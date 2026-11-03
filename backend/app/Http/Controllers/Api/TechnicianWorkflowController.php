<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Diagnosis;
use App\Models\EstimateRevision;
use App\Models\Invoice;
use App\Models\OrderStatusHistory;
use App\Models\QcCheck;
use App\Models\RepairOrder;
use App\Models\WorkNote;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TechnicianWorkflowController extends Controller
{
    private function authorizeAssignedTechnician(Request $request, RepairOrder $order): ?JsonResponse
    {
        if ($order->current_technician_id !== $request->user()->id) {
            return response()->json([
                'error' => [
                    'code' => 'FORBIDDEN',
                    'message' => 'Only the currently assigned technician may perform this action.',
                ],
            ], 403);
        }
        return null;
    }

    public function startDiagnosis(Request $request, RepairOrder $order): JsonResponse
    {
        if ($error = $this->authorizeAssignedTechnician($request, $order)) {
            return $error;
        }

        if ($order->status !== 'BOOKED') {
            return response()->json([
                'error' => ['code' => 'INVALID_STATE', 'message' => 'Order must be in BOOKED status to start diagnosis.'],
            ], 422);
        }

        DB::transaction(function () use ($order, $request) {
            $prev = $order->status;
            $order->status = 'DIAGNOSING';
            $order->lock_version += 1;
            $order->save();

            OrderStatusHistory::create([
                'order_id' => $order->id,
                'previous_status' => $prev,
                'new_status' => 'DIAGNOSING',
                'changed_by_user_id' => $request->user()->id,
                'reason' => 'Technician started device diagnosis',
            ]);
        });

        return response()->json(['message' => 'Diagnosis started.', 'order' => $order->fresh()]);
    }

    public function saveDiagnosis(Request $request, RepairOrder $order): JsonResponse
    {
        if ($error = $this->authorizeAssignedTechnician($request, $order)) {
            return $error;
        }

        $validated = $request->validate([
            'customer_safe_summary' => ['required', 'string', 'max:2000'],
        ]);

        $diagnosis = Diagnosis::updateOrCreate(
            ['order_id' => $order->id],
            [
                'technician_id' => $request->user()->id,
                'customer_safe_summary' => $validated['customer_safe_summary'],
            ]
        );

        return response()->json(['message' => 'Diagnosis saved.', 'diagnosis' => $diagnosis]);
    }

    public function addEstimate(Request $request, RepairOrder $order): JsonResponse
    {
        if ($error = $this->authorizeAssignedTechnician($request, $order)) {
            return $error;
        }

        if (in_array($order->status, ['READY', 'COMPLETED', 'CANCELLED'], true)) {
            return response()->json([
                'error' => ['code' => 'INVALID_STATE', 'message' => 'Estimates cannot be revised once QC has passed or order is closed.'],
            ], 422);
        }

        $latestRevision = $order->estimateRevisions()->orderBy('revision_number', 'desc')->first();
        $isFirst = $latestRevision === null;

        $rules = [
            'amount' => ['required', 'numeric', 'min:0'],
            'currency_code' => ['nullable', 'string', 'size:3'],
        ];

        if (! $isFirst) {
            $rules['reason'] = ['required', 'string', 'max:500'];
        }

        $validated = $request->validate($rules);
        $nextRevisionNumber = $isFirst ? 1 : ($latestRevision->revision_number + 1);

        $revision = EstimateRevision::create([
            'order_id' => $order->id,
            'revision_number' => $nextRevisionNumber,
            'amount' => $validated['amount'],
            'currency_code' => $validated['currency_code'] ?? 'IDR',
            'reason' => $validated['reason'] ?? null,
            'created_by_user_id' => $request->user()->id,
        ]);

        return response()->json(['message' => 'Estimate revision recorded.', 'revision' => $revision], 201);
    }

    public function startRepair(Request $request, RepairOrder $order): JsonResponse
    {
        if ($error = $this->authorizeAssignedTechnician($request, $order)) {
            return $error;
        }

        if ($order->status !== 'DIAGNOSING') {
            return response()->json([
                'error' => ['code' => 'INVALID_STATE', 'message' => 'Order must be in DIAGNOSING status to start repair.'],
            ], 422);
        }

        DB::transaction(function () use ($order, $request) {
            $prev = $order->status;
            $order->status = 'IN_REPAIR';
            $order->lock_version += 1;
            $order->save();

            OrderStatusHistory::create([
                'order_id' => $order->id,
                'previous_status' => $prev,
                'new_status' => 'IN_REPAIR',
                'changed_by_user_id' => $request->user()->id,
                'reason' => 'Technician started physical repair work',
            ]);
        });

        return response()->json(['message' => 'Repair started.', 'order' => $order->fresh()]);
    }

    public function addWorkNote(Request $request, RepairOrder $order): JsonResponse
    {
        if ($error = $this->authorizeAssignedTechnician($request, $order)) {
            return $error;
        }

        $validated = $request->validate([
            'note_text' => ['required', 'string', 'max:2000'],
        ]);

        $note = WorkNote::create([
            'order_id' => $order->id,
            'author_user_id' => $request->user()->id,
            'note_text' => $validated['note_text'],
        ]);

        return response()->json(['message' => 'Work note saved.', 'note' => $note], 201);
    }

    public function startQc(Request $request, RepairOrder $order): JsonResponse
    {
        if ($error = $this->authorizeAssignedTechnician($request, $order)) {
            return $error;
        }

        if ($order->status !== 'IN_REPAIR') {
            return response()->json([
                'error' => ['code' => 'INVALID_STATE', 'message' => 'Order must be IN_REPAIR to submit for QC.'],
            ], 422);
        }

        DB::transaction(function () use ($order, $request) {
            $prev = $order->status;
            $order->status = 'QC';
            $order->lock_version += 1;
            $order->save();

            OrderStatusHistory::create([
                'order_id' => $order->id,
                'previous_status' => $prev,
                'new_status' => 'QC',
                'changed_by_user_id' => $request->user()->id,
                'reason' => 'Technician submitted repair for quality inspection',
            ]);
        });

        return response()->json(['message' => 'QC phase started.', 'order' => $order->fresh()]);
    }

    public function submitQcCheck(Request $request, RepairOrder $order): JsonResponse
    {
        if ($error = $this->authorizeAssignedTechnician($request, $order)) {
            return $error;
        }

        if ($order->status !== 'QC') {
            return response()->json([
                'error' => ['code' => 'INVALID_STATE', 'message' => 'Order must be in QC status to submit inspection check.'],
            ], 422);
        }

        $validated = $request->validate([
            'result' => ['required', 'in:PASS,FAIL'],
            'note' => ['nullable', 'string', 'max:1000'],
        ]);

        $invoice = null;

        DB::transaction(function () use ($order, $request, $validated, &$invoice) {
            QcCheck::create([
                'order_id' => $order->id,
                'technician_id' => $request->user()->id,
                'result' => $validated['result'],
                'note' => $validated['note'] ?? null,
            ]);

            if ($validated['result'] === 'FAIL') {
                OrderStatusHistory::create([
                    'order_id' => $order->id,
                    'previous_status' => 'QC',
                    'new_status' => 'QC',
                    'changed_by_user_id' => $request->user()->id,
                    'reason' => 'QC check failed: ' . ($validated['note'] ?? 'Defects observed, returning for rework'),
                ]);
            } else {
                $order->status = 'READY';
                $order->lock_version += 1;
                $order->save();

                OrderStatusHistory::create([
                    'order_id' => $order->id,
                    'previous_status' => 'QC',
                    'new_status' => 'READY',
                    'changed_by_user_id' => $request->user()->id,
                    'reason' => 'QC check passed. Order ready for payment and collection.',
                ]);

                // Atomically issue invoice based on latest estimate
                $latestEstimate = $order->estimateRevisions()->orderBy('revision_number', 'desc')->first();
                $amount = $latestEstimate ? $latestEstimate->amount : '0.00';
                $currency = $latestEstimate ? $latestEstimate->currency_code : 'IDR';

                $invoiceNumber = 'INV-' . date('Ymd') . '-' . str_pad((string) $order->id, 4, '0', STR_PAD_LEFT);

                $invoice = Invoice::create([
                    'order_id' => $order->id,
                    'invoice_number' => $invoiceNumber,
                    'current_amount' => $amount,
                    'currency_code' => $currency,
                    'status' => 'OPEN',
                    'issued_at' => now(),
                ]);
            }
        });

        return response()->json([
            'message' => $validated['result'] === 'PASS' ? 'QC passed and invoice issued.' : 'QC inspection recorded as failed.',
            'order' => $order->fresh(),
            'invoice' => $invoice,
        ]);
    }
}

