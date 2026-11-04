<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Models\InvoiceCorrection;
use App\Models\PaymentAttempt;
use App\Models\PaymentWebhookEvent;
use App\Models\RepairOrder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class InvoicePaymentController extends Controller
{
    public function showInvoice(Request $request, RepairOrder $order): JsonResponse
    {
        $user = $request->user();
        if ($user->role_code === 'CUSTOMER' && $order->customer_id !== $user->id) {
            return response()->json([
                'error' => ['code' => 'FORBIDDEN', 'message' => 'You do not have access to this invoice.'],
            ], 403);
        }

        $invoice = $order->invoice()->with(['corrections.changer:id,name', 'paymentAttempts'])->first();
        if (! $invoice) {
            return response()->json([
                'error' => ['code' => 'NOT_FOUND', 'message' => 'Invoice not yet issued for this order.'],
            ], 404);
        }

        return response()->json(['invoice' => $invoice]);
    }

    public function createPaymentAttempt(Request $request, Invoice $invoice): JsonResponse
    {
        $user = $request->user();
        if ($invoice->order->customer_id !== $user->id) {
            return response()->json([
                'error' => ['code' => 'FORBIDDEN', 'message' => 'You do not own this invoice.'],
            ], 403);
        }

        if ($invoice->status === 'PAID') {
            return response()->json([
                'error' => ['code' => 'ALREADY_PAID', 'message' => 'This invoice has already been paid.'],
            ], 422);
        }

        $attemptRef = 'MID-' . date('YmdHis') . '-' . $invoice->id . '-' . Str::random(6);
        $snapToken = 'snap-token-' . Str::random(24);
        $redirectUrl = 'https://app.sandbox.midtrans.com/snap/v2/vtweb/' . $snapToken;

        $attempt = PaymentAttempt::create([
            'invoice_id' => $invoice->id,
            'provider' => 'MIDTRANS',
            'provider_reference' => $attemptRef,
            'amount' => $invoice->current_amount,
            'currency_code' => $invoice->currency_code,
            'status' => 'PENDING',
            'snap_token' => $snapToken,
            'redirect_url' => $redirectUrl,
        ]);

        return response()->json([
            'message' => 'Payment attempt created.',
            'payment_attempt' => $attempt,
        ], 201);
    }

    public function getPaymentAttempt(Request $request, PaymentAttempt $attempt): JsonResponse
    {
        $user = $request->user();
        if ($user->role_code === 'CUSTOMER' && $attempt->invoice->order->customer_id !== $user->id) {
            return response()->json([
                'error' => ['code' => 'FORBIDDEN', 'message' => 'Access denied.'],
            ], 403);
        }

        return response()->json(['payment_attempt' => $attempt]);
    }

    public function correctInvoice(Request $request, Invoice $invoice): JsonResponse
    {
        if ($invoice->status === 'PAID') {
            return response()->json([
                'error' => ['code' => 'INVALID_STATE', 'message' => 'Paid invoices cannot be corrected.'],
            ], 422);
        }

        $validated = $request->validate([
            'new_amount' => ['required', 'numeric', 'min:0'],
            'reason' => ['required', 'string', 'max:500'],
        ]);

        DB::transaction(function () use ($invoice, $validated, $request) {
            InvoiceCorrection::create([
                'invoice_id' => $invoice->id,
                'previous_amount' => $invoice->current_amount,
                'new_amount' => $validated['new_amount'],
                'reason' => $validated['reason'],
                'changed_by_user_id' => $request->user()->id,
            ]);

            $invoice->current_amount = $validated['new_amount'];
            $invoice->save();
        });

        return response()->json([
            'message' => 'Invoice corrected.',
            'invoice' => $invoice->fresh()->load('corrections.changer:id,name'),
        ]);
    }

    public function handleWebhook(Request $request): JsonResponse
    {
        $orderId = (string) $request->input('order_id');
        $statusCode = (string) $request->input('status_code');
        $grossAmount = (string) $request->input('gross_amount');
        $signatureKey = (string) $request->input('signature_key');
        $serverKey = (string) config('services.midtrans.server_key', 'SB-Mid-server-test-secret-key-reparo');

        $computedSignature = hash('sha512', $orderId . $statusCode . $grossAmount . $serverKey);

        if (! hash_equals($computedSignature, $signatureKey)) {
            return response()->json([
                'error' => ['code' => 'INVALID_SIGNATURE', 'message' => 'Webhook signature mismatch.'],
            ], 401);
        }

        $transactionId = (string) ($request->input('transaction_id') ?? $statusCode);
        $dedupKey = $orderId . ':' . $transactionId;

        if (PaymentWebhookEvent::where('deduplication_key', $dedupKey)->exists()) {
            return response()->json(['message' => 'Event already processed.'], 200);
        }

        $attempt = PaymentAttempt::where('provider_reference', $orderId)->first();
        $txStatus = (string) $request->input('transaction_status');

        $targetStatus = match ($txStatus) {
            'capture', 'settlement' => 'PAID',
            'deny', 'cancel' => 'FAILED',
            'expire' => 'EXPIRED',
            default => 'PENDING',
        };

        DB::transaction(function () use ($attempt, $dedupKey, $txStatus, $targetStatus) {
            PaymentWebhookEvent::create([
                'payment_attempt_id' => $attempt?->id,
                'deduplication_key' => $dedupKey,
                'provider_status' => $txStatus,
                'signature_valid' => true,
                'processing_outcome' => $targetStatus,
            ]);

            if ($attempt) {
                $attempt->status = $targetStatus;
                $attempt->save();

                if ($targetStatus === 'PAID') {
                    $invoice = $attempt->invoice;
                    if ($invoice && $invoice->status !== 'PAID') {
                        $invoice->status = 'PAID';
                        $invoice->paid_at = now();
                        $invoice->save();
                    }
                }
            }
        });

        return response()->json(['status' => 'success', 'applied_status' => $targetStatus]);
    }

    public function simulateSandboxPayment(Request $request, Invoice $invoice): JsonResponse
    {
        $attempt = $invoice->paymentAttempts()->latest()->first();
        if (! $attempt) {
            $attemptRef = 'MID-' . date('YmdHis') . '-' . $invoice->id . '-' . Str::random(6);
            $attempt = PaymentAttempt::create([
                'invoice_id' => $invoice->id,
                'provider' => 'MIDTRANS',
                'provider_reference' => $attemptRef,
                'amount' => $invoice->current_amount,
                'currency_code' => $invoice->currency_code,
                'status' => 'PENDING',
                'snap_token' => 'sim-snap-' . Str::random(16),
                'redirect_url' => 'https://app.sandbox.midtrans.com/snap/v2/vtweb/sim',
            ]);
        }

        $serverKey = (string) config('services.midtrans.server_key', 'SB-Mid-server-test-secret-key-reparo');
        $grossAmount = number_format($attempt->amount, 2, '.', '');
        $signatureKey = hash('sha512', $attempt->provider_reference . '200' . $grossAmount . $serverKey);

        $fakeRequest = Request::create('/api/v1/webhooks/midtrans', 'POST', [
            'order_id' => $attempt->provider_reference,
            'status_code' => '200',
            'gross_amount' => $grossAmount,
            'signature_key' => $signatureKey,
            'transaction_status' => 'settlement',
            'transaction_id' => 'SIM-' . Str::random(10),
        ]);

        return $this->handleWebhook($fakeRequest);
    }
}

