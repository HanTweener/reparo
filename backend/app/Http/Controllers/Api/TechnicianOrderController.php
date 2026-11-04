<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\OrderAssignmentEvent;
use App\Models\RepairOrder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TechnicianOrderController extends Controller
{
    /**
     * List repair orders: assigned, available (global pool), or history.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $scope = $request->query('scope', 'assigned');

        $query = RepairOrder::with([
            'customer',
            'category',
            'statusHistory',
            'diagnosis',
            'workNotes',
            'estimateRevisions',
            'qcChecks',
            'invoice',
        ])->orderBy('created_at', 'desc');

        if ($scope === 'available') {
            $query->whereNull('current_technician_id')
                ->whereNotIn('status', ['COMPLETED', 'DELIVERED', 'CANCELLED']);
        } elseif ($scope === 'history') {
            $query->where('current_technician_id', $user->id)
                ->whereIn('status', ['COMPLETED', 'DELIVERED']);
        } else {
            $query->where('current_technician_id', $user->id)
                ->whereNotIn('status', ['COMPLETED', 'DELIVERED', 'CANCELLED']);
        }

        $orders = $query->get();

        return response()->json([
            'data' => $orders->map(fn (RepairOrder $o) => [
                'id' => (string) $o->id,
                'public_reference' => $o->public_reference,
                'status' => $o->status,
                'lock_version' => $o->lock_version,
                'service_code' => $o->service_code,
                'customer' => [
                    'name' => $o->customer?->name ?? 'Pelanggan',
                ],
                'device_name' => $o->device_name,
                'device' => [
                    'brand' => '',
                    'model' => $o->device_name,
                    'name' => $o->device_name,
                    'category_name' => $o->category?->name ?? 'Umum',
                ],
                'issue_description' => $o->issue_description,
                'confirmed_arrival_date' => $o->confirmed_arrival_date?->format('Y-m-d'),
                'current_technician_id' => $o->current_technician_id ? (string) $o->current_technician_id : null,
                'diagnosis' => $o->diagnosis ? [
                    'customer_safe_summary' => $o->diagnosis->customer_safe_summary,
                ] : null,
                'work_notes' => $o->workNotes->map(fn ($n) => [
                    'id' => (string) $n->id,
                    'note_text' => $n->note_text,
                    'created_at' => $n->created_at->toIso8601String(),
                ]),
                'estimate_revisions' => $o->estimateRevisions->map(fn ($e) => [
                    'revision_number' => $e->revision_number,
                    'amount' => $e->amount,
                    'currency_code' => $e->currency_code,
                    'reason' => $e->reason,
                    'created_at' => $e->created_at->toIso8601String(),
                ]),
                'qc_checks' => $o->qcChecks->map(fn ($q) => [
                    'id' => (string) $q->id,
                    'result' => $q->result,
                    'note' => $q->note,
                    'created_at' => $q->created_at->toIso8601String(),
                ]),
                'invoice' => $o->invoice ? [
                    'id' => (string) $o->invoice->id,
                    'invoice_number' => $o->invoice->invoice_number,
                    'amount' => $o->invoice->current_amount,
                    'currency_code' => $o->invoice->currency_code,
                    'status' => $o->invoice->status,
                ] : null,
                'created_at' => $o->created_at->toIso8601String(),
            ]),
        ]);
    }

    /**
     * Technician claims an unassigned order from the global queue.
     */
    public function claim(Request $request, RepairOrder $order): JsonResponse
    {
        $technician = $request->user();

        if ($order->current_technician_id !== null) {
            return response()->json([
                'error' => [
                    'code' => 'ALREADY_ASSIGNED',
                    'message' => 'Pesanan sudah diambil oleh teknisi lain.',
                ],
            ], 409);
        }

        if (in_array($order->status, ['COMPLETED', 'DELIVERED', 'CANCELLED'], true)) {
            return response()->json([
                'error' => [
                    'code' => 'INVALID_STATE',
                    'message' => 'Pesanan dengan status ini tidak dapat diambil.',
                ],
            ], 422);
        }

        DB::transaction(function () use ($order, $technician) {
            $order->current_technician_id = $technician->id;
            $order->lock_version += 1;
            $order->save();

            OrderAssignmentEvent::create([
                'order_id' => $order->id,
                'previous_technician_id' => null,
                'new_technician_id' => $technician->id,
                'changed_by_user_id' => $technician->id,
                'reason' => 'Teknisi mengklaim pekerjaan dari antrean global',
            ]);
        });

        return response()->json([
            'message' => 'Pekerjaan berhasil diambil ke antrean tugas Anda.',
            'data' => [
                'id' => (string) $order->id,
                'current_technician_id' => (string) $technician->id,
            ],
        ]);
    }
}
