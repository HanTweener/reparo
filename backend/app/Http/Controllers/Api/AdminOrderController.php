<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CancellationRequest;
use App\Models\CustomerDevice;
use App\Models\OrderAssignmentEvent;
use App\Models\OrderStatusHistory;
use App\Models\RepairOrder;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class AdminOrderController extends Controller
{
    /**
     * Operational queue showing repair orders.
     */
    public function index(Request $request): JsonResponse
    {
        $query = RepairOrder::with(['customer', 'device.category', 'technician', 'invoice', 'cancellationRequests' => function ($q) {
            $q->where('decision', 'PENDING');
        }])->orderBy('created_at', 'desc');

        if ($request->has('status')) {
            $query->where('status', $request->query('status'));
        }

        $orders = $query->get();

        return response()->json([
            'data' => $orders->map(fn (RepairOrder $o) => [
                'id' => (string) $o->id,
                'public_reference' => $o->public_reference,
                'status' => $o->status,
                'service_code' => $o->service_code,
                'customer' => [
                    'id' => (string) $o->customer_id,
                    'name' => $o->customer?->name ?? 'Pelanggan',
                    'email' => $o->customer?->email ?? '',
                ],
                'device' => [
                    'id' => (string) $o->device_id,
                    'brand' => $o->device?->brand ?? '',
                    'model' => $o->device?->model ?? '',
                    'category_name' => $o->device?->category?->name ?? 'Umum',
                ],
                'preferred_arrival_date' => $o->preferred_arrival_date?->format('Y-m-d'),
                'confirmed_arrival_date' => $o->confirmed_arrival_date?->format('Y-m-d'),
                'technician' => $o->technician ? [
                    'id' => (string) $o->technician->id,
                    'name' => $o->technician->name,
                ] : null,
                'invoice' => $o->invoice ? [
                    'id' => (string) $o->invoice->id,
                    'invoice_number' => $o->invoice->invoice_number,
                    'amount' => $o->invoice->current_amount,
                    'status' => $o->invoice->status,
                ] : null,
                'has_pending_cancellation' => $o->cancellationRequests->isNotEmpty(),
                'created_at' => $o->created_at->toIso8601String(),
            ]),
        ]);
    }

    /**
     * Admin confirms preferred arrival date.
     */
    public function confirmSchedule(Request $request, RepairOrder $order): JsonResponse
    {
        $validated = $request->validate([
            'confirmed_arrival_date' => ['required', 'date'],
        ]);

        $order->update([
            'confirmed_arrival_date' => $validated['confirmed_arrival_date'],
        ]);

        return response()->json([
            'data' => [
                'id' => (string) $order->id,
                'confirmed_arrival_date' => $order->confirmed_arrival_date->format('Y-m-d'),
                'message' => 'Jadwal kedatangan telah dikonfirmasi.',
            ],
        ]);
    }

    /**
     * Admin assigns or reassigns an eligible Technician.
     */
    public function assignTechnician(Request $request, RepairOrder $order): JsonResponse
    {
        $validated = $request->validate([
            'technician_id' => ['required', 'integer', 'exists:users,id'],
            'reason' => ['nullable', 'string', 'max:255'],
        ]);

        $technician = User::where('id', $validated['technician_id'])
            ->where('role_code', 'TECHNICIAN')
            ->where('is_active', true)
            ->first();

        if (! $technician) {
            return response()->json([
                'error' => [
                    'code' => 'INVALID_TECHNICIAN',
                    'message' => 'Pengguna yang dipilih bukan Teknisi aktif.',
                ],
            ], 422);
        }

        $admin = $request->user();

        DB::transaction(function () use ($order, $technician, $admin, $validated) {
            $prevTechId = $order->current_technician_id;

            $order->update([
                'current_technician_id' => $technician->id,
                'lock_version' => $order->lock_version + 1,
            ]);

            OrderAssignmentEvent::create([
                'order_id' => $order->id,
                'previous_technician_id' => $prevTechId,
                'new_technician_id' => $technician->id,
                'changed_by_user_id' => $admin->id,
                'reason' => $validated['reason'] ?? null,
                'created_at' => now(),
            ]);
        });

        return response()->json([
            'data' => [
                'order_id' => (string) $order->id,
                'technician' => [
                    'id' => (string) $technician->id,
                    'name' => $technician->name,
                ],
                'message' => 'Teknisi ' . $technician->name . ' berhasil ditugaskan.',
            ],
        ]);
    }

    /**
     * Admin decides a pending cancellation request.
     */
    public function decideCancellation(Request $request, RepairOrder $order): JsonResponse
    {
        $validated = $request->validate([
            'decision' => ['required', Rule::in(['CONFIRMED', 'DENIED'])],
            'reason' => ['nullable', 'string', 'max:500'],
        ]);

        $cancelReq = CancellationRequest::where('order_id', $order->id)
            ->where('decision', 'PENDING')
            ->first();

        if (! $cancelReq) {
            return response()->json([
                'error' => [
                    'code' => 'NO_PENDING_CANCELLATION',
                    'message' => 'Tidak ada permohonan pembatalan tertunda untuk pesanan ini.',
                ],
            ], 422);
        }

        $admin = $request->user();

        DB::transaction(function () use ($order, $cancelReq, $admin, $validated) {
            $cancelReq->update([
                'decision' => $validated['decision'],
                'decided_by_user_id' => $admin->id,
                'decision_reason' => $validated['reason'] ?? null,
                'decided_at' => now(),
            ]);

            if ($validated['decision'] === 'CONFIRMED') {
                $prevStatus = $order->status;
                $order->update([
                    'status' => 'CANCELLED',
                    'lock_version' => $order->lock_version + 1,
                ]);

                OrderStatusHistory::create([
                    'order_id' => $order->id,
                    'previous_status' => $prevStatus,
                    'new_status' => 'CANCELLED',
                    'changed_by_user_id' => $admin->id,
                    'reason' => 'Admin menyetujui pembatalan: ' . ($validated['reason'] ?? 'Tanpa alasan tambahan'),
                    'created_at' => now(),
                ]);
            }
        });

        return response()->json([
            'data' => [
                'order_id' => (string) $order->id,
                'decision' => $validated['decision'],
                'status' => $order->fresh()->status,
                'message' => $validated['decision'] === 'CONFIRMED'
                    ? 'Pesanan berhasil dibatalkan.'
                    : 'Permohonan pembatalan pesanan ditolak.',
            ],
        ]);
    }
}
