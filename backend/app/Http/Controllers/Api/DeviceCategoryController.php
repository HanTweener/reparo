<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DeviceCategory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeviceCategoryController extends Controller
{
    /**
     * List active device categories (Public/Customer).
     */
    public function index(): JsonResponse
    {
        $categories = DeviceCategory::where('is_active', true)
            ->orderBy('name')
            ->get(['id', 'name', 'is_active']);

        return response()->json([
            'data' => $categories->map(fn ($cat) => [
                'id' => (string) $cat->id,
                'name' => $cat->name,
                'is_active' => $cat->is_active,
            ]),
        ]);
    }

    /**
     * Store new category (Admin only).
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:100', 'unique:device_categories,name'],
        ]);

        $category = DeviceCategory::create([
            'name' => trim($validated['name']),
            'is_active' => true,
        ]);

        return response()->json([
            'data' => [
                'id' => (string) $category->id,
                'name' => $category->name,
                'is_active' => $category->is_active,
                'message' => 'Kategori perangkat berhasil dibuat.',
            ],
        ], 201);
    }
}

