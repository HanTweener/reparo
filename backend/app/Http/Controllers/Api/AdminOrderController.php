<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CancellationRequest;
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
        $query = RepairOrder::with(['customer', 'category', 'technician', 'invoice', 'cancellationRequests' => fn ($q) => $q->where('decision', 'PENDING')])
            ->orderBy('created_at', 'desc');

        if ($request->has('status')) {
            $query->where('status', $request->query('status'));
        }

        $orders = $query->get();

        return response()->json([
            'data' => $orders->map(fn (RepairOrder $o) => [
                'id' => (string) $o->id,
                'public_reference' => $o->public_reference,
                'status' => $o->status,
                'lock_version' => $o->lock_version,
                'service_code' => $o->service_code,
                'customer' => ['id' => (string) $o->customer_id, 'name' => $o->customer?->name ?? 'Pelanggan', 'email' => $o->customer?->email ?? ''],
                'device_name' => $o->device_name,
                'device' => ['id' => '', 'brand' => '', 'model' => $o->device_name, 'name' => $o->device_name, 'category_name' => $o->category?->name ?? 'Umum'],
                'preferred_arrival_date' => $o->preferred_arrival_date?->format('Y-m-d'),
                'confirmed_arrival_date' => $o->confirmed_arrival_date?->format('Y-m-d'),
                'technician' => $o->technician ? ['id' => (string) $o->technician->id, 'name' => $o->technician->name] : null,
                'invoice' => $o->invoice ? ['id' => (string) $o->invoice->id, 'invoice_number' => $o->invoice->invoice_number, 'amount' => $o->invoice->current_amount, 'status' => $o->invoice->status] : null,
                'has_pending_cancellation' => $o->cancellationRequests->isNotEmpty(),
                'created_at' => $o->created_at->toIso8601String(),
            ]),
        ]);
    }

    /**
     * Queue statistics with period filter (day, week, month, all).
     */
    public function statistics(Request $request): JsonResponse
    {
        $period = $request->query('period', 'all');
        $query = RepairOrder::query();

        if ($period === 'day') {
            $query->whereDate('created_at', today());
        } elseif ($period === 'week') {
            $query->whereBetween('created_at', [now()->startOfWeek(), now()->endOfWeek()]);
        } elseif ($period === 'month') {
            $query->whereBetween('created_at', [now()->startOfMonth(), now()->endOfMonth()]);
        }

        $allOrders = $query->get(['id', 'status']);

        return response()->json([
            'data' => [
                'period' => $period,
                'incoming' => $allOrders->whereIn('status', ['BOOKED', 'ARRIVED'])->count(),
                'in_progress' => $allOrders->whereIn('status', ['DIAGNOSING', 'ESTIMATED', 'IN_REPAIR', 'QC'])->count(),
                'completed' => $allOrders->whereIn('status', ['READY', 'COMPLETED', 'DELIVERED'])->count(),
                'cancelled' => $allOrders->where('status', 'CANCELLED')->count(),
                'total' => $allOrders->count(),
            ],
        ]);
    }

    /**
     * Admin or Cashier creates a new booking (e.g. walk-in customer).
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'customer_name' => ['required', 'string', 'max:255'],
            'customer_email' => ['nullable', 'email', 'max:255'],
            'device_name' => ['required', 'string', 'min:3', 'max:255'],
            'category_id' => ['nullable', 'exists:device_categories,id'],
            'service_code' => ['nullable', 'string', 'max:32'],
            'issue_description' => ['required', 'string', 'min:5', 'max:1000'],
            'preferred_arrival_date' => ['nullable', 'date'],
            'arrival_date' => ['nullable', 'date'],
        ]);

        $admin = $request->user();
        $email = strtolower(trim($validated['customer_email'] ?? ''));
        if (empty($email)) {
            $email = 'walkin_' . time() . '_' . rand(100, 999) . '@reparo.test';
        }

        $customer = User::firstOrCreate(
            ['email' => $email],
            [
                'name' => $validated['customer_name'],
                'password' => bcrypt('Password123!'),
                'role_code' => 'CUSTOMER',
                'is_active' => true,
                'email_verified_at' => now(),
            ]
        );

        $arrivalDate = $validated['preferred_arrival_date'] ?? $validated['arrival_date'] ?? now()->toDateString();

        $order = DB::transaction(function () use ($admin, $customer, $validated, $arrivalDate) {
            $reference = RepairOrder::generateUniqueReference();

            $order = RepairOrder::create([
                'public_reference' => $reference,
                'customer_id' => $customer->id,
                'device_name' => trim($validated['device_name']),
                'category_id' => $validated['category_id'] ?? null,
                'service_code' => $validated['service_code'] ?? 'MAINTENANCE',
                'issue_description' => trim($validated['issue_description']),
                'preferred_arrival_date' => $arrivalDate,
                'confirmed_arrival_date' => $arrivalDate,
                'status' => 'BOOKED',
                'current_technician_id' => null,
                'created_by_user_id' => $admin->id,
                'lock_version' => 1,
            ]);

            OrderStatusHistory::create([
                'order_id' => $order->id,
                'previous_status' => null,
                'new_status' => 'BOOKED',
                'changed_by_user_id' => $admin->id,
                'reason' => 'Booking dibuat oleh Admin/Kasir.',
                'created_at' => now(),
            ]);

            return $order;
        });

        return response()->json([
            'data' => [
                'id' => (string) $order->id,
                'public_reference' => $order->public_reference,
                'status' => $order->status,
                'message' => 'Pesanan walk-in ' . $order->public_reference . ' berhasil dibuat.',
            ],
        ], 201);
    }

    /**
     * Admin confirms preferred arrival date.
     */
    public function confirmSchedule(Request $request, RepairOrder $order): JsonResponse
    {
        $validated = $request->validate(['confirmed_arrival_date' => ['required', 'date']]);
        $order->update(['confirmed_arrival_date' => $validated['confirmed_arrival_date']]);

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
