<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CancellationRequest;
use App\Models\CustomerDevice;
use App\Models\OrderStatusHistory;
use App\Models\RepairOrder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CustomerOrderController extends Controller
{
    /**
     * List repair orders owned by the authenticated customer.
     */
    public function index(Request $request): JsonResponse
    {
        $orders = RepairOrder::with([
            'device.category',
            'statusHistory',
            'diagnosis',
            'estimateRevisions',
            'invoice.corrections',
        ])
            ->where('customer_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'data' => $orders->map(fn (RepairOrder $o) => $this->formatOrder($o)),
        ]);
    }

    /**
     * Create a new Maintenance booking for an owned device.
     */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'device_id' => ['required', 'integer'],
            'issue_description' => ['required', 'string', 'min:5', 'max:1000'],
            'preferred_arrival_date' => ['required', 'date', 'after_or_equal:today'],
        ]);

        // Security check: Device must belong to this authenticated customer
        $device = CustomerDevice::where('id', $validated['device_id'])
            ->where('customer_id', $user->id)
            ->first();

        if (! $device) {
            return response()->json([
                'error' => [
                    'code' => 'INVALID_DEVICE',
                    'message' => 'Perangkat tidak ditemukan atau bukan milik Anda.',
                ],
            ], 422);
        }

        $order = DB::transaction(function () use ($user, $device, $validated) {
            $reference = 'REP-' . date('Y') . '-' . str_pad((string) (RepairOrder::count() + 1), 4, '0', STR_PAD_LEFT);

            $order = RepairOrder::create([
                'public_reference' => $reference,
                'customer_id' => $user->id,
                'device_id' => $device->id,
                'service_code' => 'MAINTENANCE',
                'issue_description' => trim($validated['issue_description']),
                'preferred_arrival_date' => $validated['preferred_arrival_date'],
                'confirmed_arrival_date' => null,
                'status' => 'BOOKED',
                'current_technician_id' => null,
                'created_by_user_id' => $user->id,
                'lock_version' => 1,
            ]);

            OrderStatusHistory::create([
                'order_id' => $order->id,
                'previous_status' => null,
                'new_status' => 'BOOKED',
                'changed_by_user_id' => $user->id,
                'reason' => 'Pemesanan dibuat oleh Pelanggan.',
                'created_at' => now(),
            ]);

            return $order;
        });

        $order->load(['device.category', 'statusHistory']);

        return response()->json([
            'data' => array_merge($this->formatOrder($order), [
                'message' => 'Pesanan ' . $order->public_reference . ' dibuat. Jadwal menunggu konfirmasi Admin.',
            ]),
        ], 201);
    }

    /**
     * Show order details for the owning customer.
     */
    public function show(Request $request, RepairOrder $order): JsonResponse
    {
        if ($order->customer_id !== $request->user()->id) {
            return response()->json([
                'error' => [
                    'code' => 'RESOURCE_UNAVAILABLE',
                    'message' => 'Pesanan tidak ditemukan atau Anda tidak memiliki akses.',
                ],
            ], 404);
        }

        $order->load([
            'device.category',
            'statusHistory',
            'cancellationRequests',
            'diagnosis',
            'estimateRevisions',
            'invoice.corrections',
        ]);

        return response()->json([
            'data' => $this->formatOrder($order),
        ]);
    }

    /**
     * Customer requests cancellation before diagnosis begins.
     */
    public function requestCancellation(Request $request, RepairOrder $order): JsonResponse
    {
        $user = $request->user();

        if ($order->customer_id !== $user->id) {
            return response()->json([
                'error' => [
                    'code' => 'RESOURCE_UNAVAILABLE',
                    'message' => 'Pesanan tidak ditemukan atau Anda tidak memiliki akses.',
                ],
            ], 404);
        }

        if ($order->status !== 'BOOKED') {
            return response()->json([
                'error' => [
                    'code' => 'CANCELLATION_NOT_ALLOWED',
                    'message' => 'Pembatalan hanya dapat diajukan sebelum perbaikan atau diagnosis dimulai.',
                ],
            ], 422);
        }

        $validated = $request->validate([
            'reason' => ['nullable', 'string', 'max:500'],
        ]);

        $cancelReq = CancellationRequest::create([
            'order_id' => $order->id,
            'requested_by_user_id' => $user->id,
            'reason' => $validated['reason'] ?? null,
            'decision' => 'PENDING',
        ]);

        return response()->json([
            'data' => [
                'id' => (string) $cancelReq->id,
                'decision' => $cancelReq->decision,
                'message' => 'Permintaan pembatalan tercatat. Menunggu persetujuan Admin.',
            ],
        ], 201);
    }

    private function formatOrder(RepairOrder $o): array
    {
        return [
            'id' => (string) $o->id,
            'public_reference' => $o->public_reference,
            'service_code' => $o->service_code,
            'issue_description' => $o->issue_description,
            'preferred_arrival_date' => $o->preferred_arrival_date?->format('Y-m-d'),
            'confirmed_arrival_date' => $o->confirmed_arrival_date?->format('Y-m-d'),
            'status' => $o->status,
            'lock_version' => $o->lock_version,
            'device' => [
                'id' => (string) $o->device_id,
                'brand' => $o->device?->brand ?? '',
                'model' => $o->device?->model ?? '',
                'category_name' => $o->device?->category?->name ?? 'Umum',
            ],
            'status_history' => $o->statusHistory->map(fn ($h) => [
                'status' => $h->new_status,
                'reason' => $h->reason,
                'created_at' => $h->created_at->toIso8601String(),
            ]),
            'diagnosis' => $o->diagnosis ? [
                'customer_safe_summary' => $o->diagnosis->customer_safe_summary,
            ] : null,
            'estimate_revisions' => $o->estimateRevisions->map(fn ($e) => [
                'revision_number' => $e->revision_number,
                'amount' => $e->amount,
                'currency_code' => $e->currency_code,
                'reason' => $e->reason,
                'created_at' => $e->created_at->toIso8601String(),
            ]),
            'invoice' => $o->invoice ? [
                'id' => (string) $o->invoice->id,
                'invoice_number' => $o->invoice->invoice_number,
                'amount' => $o->invoice->current_amount,
                'currency_code' => $o->invoice->currency_code,
                'status' => $o->invoice->status,
                'issued_at' => $o->invoice->issued_at?->toIso8601String(),
                'paid_at' => $o->invoice->paid_at?->toIso8601String(),
                'corrections' => $o->invoice->corrections->map(fn ($c) => [
                    'previous_amount' => $c->previous_amount,
                    'new_amount' => $c->new_amount,
                    'reason' => $c->reason,
                    'created_at' => $c->created_at->toIso8601String(),
                ]),
            ] : null,
            'created_at' => $o->created_at->toIso8601String(),
        ];
    }
}
