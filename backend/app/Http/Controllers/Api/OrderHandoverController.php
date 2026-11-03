<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\OrderStatusHistory;
use App\Models\RepairOrder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderHandoverController extends Controller
{
    public function handover(Request $request, RepairOrder $order): JsonResponse
    {
        $user = $request->user();

        // Allowed: Admin or currently assigned Technician
        $isAssignedTech = ($user->role_code === 'TECHNICIAN' && $order->current_technician_id === $user->id);
        $isAdmin = ($user->role_code === 'ADMIN');

        if (! $isAssignedTech && ! $isAdmin) {
            return response()->json([
                'error' => ['code' => 'FORBIDDEN', 'message' => 'Only Admin or the assigned Technician may complete handover.'],
            ], 403);
        }

        if ($order->status !== 'READY') {
            return response()->json([
                'error' => ['code' => 'INVALID_STATE', 'message' => 'Order must be in READY state for handover.'],
            ], 422);
        }

        $invoice = $order->invoice;
        if (! $invoice || $invoice->status !== 'PAID') {
            return response()->json([
                'error' => ['code' => 'PAYMENT_REQUIRED', 'message' => 'Handover requires verified payment before completion.'],
            ], 422);
        }

        DB::transaction(function () use ($order, $user) {
            $prev = $order->status;
            $order->status = 'COMPLETED';
            $order->lock_version += 1;
            $order->save();

            OrderStatusHistory::create([
                'order_id' => $order->id,
                'previous_status' => $prev,
                'new_status' => 'COMPLETED',
                'changed_by_user_id' => $user->id,
                'reason' => 'Physical device handover completed to customer',
            ]);
        });

        return response()->json([
            'message' => 'Device handover recorded. Order marked as completed.',
            'order' => $order->fresh(),
        ]);
    }
}

