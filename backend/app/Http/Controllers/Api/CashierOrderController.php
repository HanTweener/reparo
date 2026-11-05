<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DeviceCategory;
use App\Models\OrderStatusHistory;
use App\Models\RepairOrder;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class CashierOrderController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = RepairOrder::with([
            'customer',
            'category',
            'technician',
            'statusHistory',
            'invoice',
        ])->orderBy('created_at', 'desc');

        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        if ($request->filled('search')) {
            $term = trim($request->query('search'));
            $query->where(function ($q) use ($term) {
                $q->where('public_reference', 'like', "%{$term}%")
                    ->orWhere('device_name', 'like', "%{$term}%")
                    ->orWhereHas('customer', fn ($cq) => $cq->where('name', 'like', "%{$term}%"));
            });
        }

        $orders = $query->get();

        return response()->json([
            'data' => $orders->map(fn (RepairOrder $o) => [
                'id' => (string) $o->id,
                'public_reference' => $o->public_reference,
                'status' => $o->status,
                'lock_version' => $o->lock_version,
                'service_code' => $o->service_code,
                'device_name' => $o->device_name,
                'customer' => [
                    'id' => (string) $o->customer?->id,
                    'name' => $o->customer?->name ?? 'Pelanggan',
                    'email' => $o->customer?->email ?? '',
                ],
                'technician' => $o->technician ? [
                    'id' => (string) $o->technician->id,
                    'name' => $o->technician->name,
                ] : null,
                'device' => [
                    'brand' => '',
                    'model' => $o->device_name,
                    'name' => $o->device_name,
                    'category_name' => $o->category?->name ?? 'Umum',
                ],
                'issue_description' => $o->issue_description,
                'preferred_arrival_date' => $o->preferred_arrival_date?->format('Y-m-d'),
                'confirmed_arrival_date' => $o->confirmed_arrival_date?->format('Y-m-d'),
                'invoice' => $o->invoice ? [
                    'id' => (string) $o->invoice->id,
                    'invoice_number' => $o->invoice->invoice_number,
                    'amount' => (string) $o->invoice->current_amount,
                    'status' => $o->invoice->status,
                ] : null,
                'created_at' => $o->created_at->toIso8601String(),
            ]),
        ]);
    }

    public function statistics(Request $request): JsonResponse
    {
        $period = $request->query('period', 'all');
        $query = RepairOrder::query();

        if ($period === 'day') {
            $query->whereDate('created_at', Carbon::today());
        } elseif ($period === 'week') {
            $query->whereBetween('created_at', [Carbon::now()->startOfWeek(), Carbon::now()->endOfWeek()]);
        } elseif ($period === 'month') {
            $query->whereBetween('created_at', [Carbon::now()->startOfMonth(), Carbon::now()->endOfMonth()]);
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

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'customer_name' => ['required', 'string', 'max:255'],
            'customer_email' => ['nullable', 'email', 'max:255'],
            'customer_phone' => ['nullable', 'string', 'max:32'],
            'device_name' => ['required', 'string', 'max:255'],
            'category_id' => ['nullable', 'exists:device_categories,id'],
            'service_code' => ['required', 'string', 'max:64'],
            'issue_description' => ['required', 'string', 'min:5', 'max:2000'],
            'arrival_date' => ['required', 'date'],
        ]);

        $cashier = $request->user();

        $order = DB::transaction(function () use ($validated, $cashier) {
            $email = ! empty($validated['customer_email'])
                ? strtolower(trim($validated['customer_email']))
                : 'walkin_'.Str::random(8).'@reparo.customer';

            $customer = User::firstOrCreate(
                ['email' => $email],
                [
                    'name' => trim($validated['customer_name']),
                    'password' => Hash::make(Str::random(16)),
                    'role_code' => 'CUSTOMER',
                    'is_active' => true,
                ]
            );

            $order = RepairOrder::create([
                'public_reference' => 'REP-'.date('Ymd').'-'.strtoupper(Str::random(4)),
                'customer_id' => $customer->id,
                'device_name' => trim($validated['device_name']),
                'category_id' => $validated['category_id'] ?? null,
                'service_code' => $validated['service_code'],
                'issue_description' => trim($validated['issue_description']),
                'preferred_arrival_date' => $validated['arrival_date'],
                'confirmed_arrival_date' => $validated['arrival_date'],
                'status' => 'BOOKED',
                'current_technician_id' => null,
                'created_by_user_id' => $cashier->id,
                'lock_version' => 1,
            ]);

            OrderStatusHistory::create([
                'order_id' => $order->id,
                'previous_status' => null,
                'new_status' => 'BOOKED',
                'changed_by_user_id' => $cashier->id,
                'reason' => 'Booking walk-in dibuat oleh Kasir ('.$cashier->name.').',
                'created_at' => now(),
            ]);

            return $order;
        });

        return response()->json([
            'data' => [
                'id' => (string) $order->id,
                'public_reference' => $order->public_reference,
                'status' => $order->status,
                'device_name' => $order->device_name,
                'message' => 'Pesanan walk-in berhasil dicatat di antrean perbaikan.',
            ],
        ], 201);
    }

    public function show(Request $request, RepairOrder $order): JsonResponse
    {
        $order->load(['customer', 'category', 'technician', 'statusHistory', 'invoice']);

        return response()->json([
            'data' => [
                'id' => (string) $order->id,
                'public_reference' => $order->public_reference,
                'status' => $order->status,
                'device_name' => $order->device_name,
                'customer' => [
                    'name' => $order->customer?->name,
                    'email' => $order->customer?->email,
                ],
                'technician' => $order->technician ? [
                    'id' => (string) $order->technician->id,
                    'name' => $order->technician->name,
                ] : null,
                'created_at' => $order->created_at->toIso8601String(),
            ],
        ]);
    }

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
                'order_id' => (string) $order->id,
                'confirmed_arrival_date' => $order->confirmed_arrival_date->format('Y-m-d'),
                'message' => 'Jadwal kedatangan pesanan berhasil dikonfirmasi.',
            ],
        ]);
    }
}

