<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CustomerDevice;
use App\Models\DeviceCategory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CustomerDeviceController extends Controller
{
    /**
     * List devices belonging to the authenticated customer.
     */
    public function index(Request $request): JsonResponse
    {
        $devices = CustomerDevice::with('category')
            ->where('customer_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'data' => $devices->map(fn (CustomerDevice $d) => [
                'id' => (string) $d->id,
                'category_id' => (string) $d->category_id,
                'category_name' => $d->category?->name ?? 'Umum',
                'brand' => $d->brand,
                'model' => $d->model,
                'serial_number' => $d->serial_number,
                'description' => $d->description,
                'created_at' => $d->created_at->toIso8601String(),
            ]),
        ]);
    }

    /**
     * Register a new device for the authenticated customer.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'category_id' => ['required', 'exists:device_categories,id'],
            'brand' => ['required', 'string', 'max:100'],
            'model' => ['required', 'string', 'max:100'],
            'serial_number' => ['nullable', 'string', 'max:100'],
            'description' => ['nullable', 'string', 'max:500'],
        ]);

        $category = DeviceCategory::findOrFail($validated['category_id']);
        if (! $category->is_active) {
            return response()->json([
                'error' => [
                    'code' => 'INACTIVE_CATEGORY',
                    'message' => 'Kategori perangkat ini tidak lagi aktif.',
                ],
            ], 422);
        }

        $device = CustomerDevice::create([
            'customer_id' => $request->user()->id,
            'category_id' => $category->id,
            'brand' => trim($validated['brand']),
            'model' => trim($validated['model']),
            'serial_number' => isset($validated['serial_number']) ? trim($validated['serial_number']) : null,
            'description' => isset($validated['description']) ? trim($validated['description']) : null,
        ]);

        return response()->json([
            'data' => [
                'id' => (string) $device->id,
                'category_id' => (string) $device->category_id,
                'category_name' => $category->name,
                'brand' => $device->brand,
                'model' => $device->model,
                'serial_number' => $device->serial_number,
                'description' => $device->description,
                'created_at' => $device->created_at->toIso8601String(),
                'message' => 'Perangkat berhasil didaftarkan.',
            ],
        ], 201);
    }

    /**
     * Show device details (Customer owner only).
     */
    public function show(Request $request, CustomerDevice $device): JsonResponse
    {
        if ($device->customer_id !== $request->user()->id) {
            return response()->json([
                'error' => [
                    'code' => 'RESOURCE_UNAVAILABLE',
                    'message' => 'Perangkat tidak ditemukan atau Anda tidak memiliki akses.',
                ],
            ], 404);
        }

        return response()->json([
            'data' => [
                'id' => (string) $device->id,
                'category_id' => (string) $device->category_id,
                'category_name' => $device->category?->name ?? 'Umum',
                'brand' => $device->brand,
                'model' => $device->model,
                'serial_number' => $device->serial_number,
                'description' => $device->description,
                'created_at' => $device->created_at->toIso8601String(),
            ],
        ]);
    }
}

