<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RepairOrder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TechnicianOrderController extends Controller
{
    /**
     * List repair orders assigned to the authenticated technician.
     */
    public function index(Request $request): JsonResponse
    {
        $orders = RepairOrder::with([
            'customer',
            'device.category',
            'statusHistory',
            'diagnosis',
            'workNotes',
            'estimateRevisions',
            'qcChecks',
            'invoice',
        ])
            ->where('current_technician_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'data' => $orders->map(fn (RepairOrder $o) => [
                'id' => (string) $o->id,
                'public_reference' => $o->public_reference,
                'status' => $o->status,
                'service_code' => $o->service_code,
                'customer' => [
                    'name' => $o->customer?->name ?? 'Pelanggan',
                ],
                'device' => [
                    'brand' => $o->device?->brand ?? '',
                    'model' => $o->device?->model ?? '',
                    'category_name' => $o->device?->category?->name ?? 'Umum',
                ],
                'issue_description' => $o->issue_description,
                'confirmed_arrival_date' => $o->confirmed_arrival_date?->format('Y-m-d'),
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
}
