<?php

use App\Http\Controllers\Api\AdminOrderController;
use App\Http\Controllers\Api\AdminStaffController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CustomerDeviceController;
use App\Http\Controllers\Api\CustomerOrderController;
use App\Http\Controllers\Api\DeviceCategoryController;
use App\Http\Controllers\Api\InvoicePaymentController;
use App\Http\Controllers\Api\OrderHandoverController;
use App\Http\Controllers\Api\TechnicianOrderController;
use App\Http\Controllers\Api\TechnicianWorkflowController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    // Public routes (Guest)
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/auth/login', [AuthController::class, 'login']);
    Route::get('/device-categories', [DeviceCategoryController::class, 'index']);
    Route::post('/webhooks/midtrans', [InvoicePaymentController::class, 'handleWebhook']);

    // Authenticated routes
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::get('/me', [AuthController::class, 'me']);

        // Order invoice & Handover routes (Customer / Tech / Admin)
        Route::get('/orders/{order}/invoice', [InvoicePaymentController::class, 'showInvoice']);
        Route::post('/orders/{order}/handover', [OrderHandoverController::class, 'handover']);

        // Customer routes (Role: CUSTOMER)
        Route::middleware('role:CUSTOMER')->prefix('customer')->group(function () {
            Route::get('/devices', [CustomerDeviceController::class, 'index']);
            Route::post('/devices', [CustomerDeviceController::class, 'store']);
            Route::get('/devices/{device}', [CustomerDeviceController::class, 'show']);

            Route::get('/orders', [CustomerOrderController::class, 'index']);
            Route::post('/orders', [CustomerOrderController::class, 'store']);
            Route::get('/orders/{order}', [CustomerOrderController::class, 'show']);
            Route::post('/orders/{order}/cancellation-requests', [CustomerOrderController::class, 'requestCancellation']);

            Route::post('/invoices/{invoice}/payment-attempts', [InvoicePaymentController::class, 'createPaymentAttempt']);
            Route::get('/payment-attempts/{attempt}', [InvoicePaymentController::class, 'getPaymentAttempt']);
        });

        // Technician routes (Role: TECHNICIAN)
        Route::middleware('role:TECHNICIAN')->prefix('technician')->group(function () {
            Route::get('/orders', [TechnicianOrderController::class, 'index']);
            Route::post('/orders/{order}/diagnosis/start', [TechnicianWorkflowController::class, 'startDiagnosis']);
            Route::put('/orders/{order}/diagnosis', [TechnicianWorkflowController::class, 'saveDiagnosis']);
            Route::post('/orders/{order}/estimates', [TechnicianWorkflowController::class, 'addEstimate']);
            Route::post('/orders/{order}/repair/start', [TechnicianWorkflowController::class, 'startRepair']);
            Route::post('/orders/{order}/work-notes', [TechnicianWorkflowController::class, 'addWorkNote']);
            Route::post('/orders/{order}/qc/start', [TechnicianWorkflowController::class, 'startQc']);
            Route::post('/orders/{order}/qc-checks', [TechnicianWorkflowController::class, 'submitQcCheck']);
        });

        // Admin routes (Role: ADMIN)
        Route::middleware('role:ADMIN')->prefix('admin')->group(function () {
            Route::get('/orders', [AdminOrderController::class, 'index']);
            Route::patch('/orders/{order}/schedule', [AdminOrderController::class, 'confirmSchedule']);
            Route::put('/orders/{order}/assignment', [AdminOrderController::class, 'assignTechnician']);
            Route::post('/orders/{order}/cancellation-decision', [AdminOrderController::class, 'decideCancellation']);

            Route::post('/invoices/{invoice}/corrections', [InvoicePaymentController::class, 'correctInvoice']);

            Route::post('/device-categories', [DeviceCategoryController::class, 'store']);

            Route::get('/staff', [AdminStaffController::class, 'index']);
            Route::post('/staff', [AdminStaffController::class, 'store']);
            Route::patch('/staff/{user}/status', [AdminStaffController::class, 'updateStatus']);
        });
    });
});
