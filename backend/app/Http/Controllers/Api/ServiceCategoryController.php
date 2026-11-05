<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ServiceCategory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ServiceCategoryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $query = ServiceCategory::query()->orderBy('name', 'asc');
        if (! $user || ! $user->isAdmin()) {
            $query->where('is_active', true);
        }

        $list = $query->get();

        return response()->json([
            'data' => $list->map(fn (ServiceCategory $c) => [
                'id' => (string) $c->id,
                'name' => $c->name,
                'code' => $c->code,
                'base_price' => (float) $c->base_price,
                'description' => $c->description ?? '',
                'is_active' => $c->is_active,
            ]),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255', 'unique:service_categories,name'],
            'code' => ['nullable', 'string', 'max:64', 'unique:service_categories,code'],
            'base_price' => ['required', 'numeric', 'min:0'],
            'description' => ['nullable', 'string', 'max:500'],
        ]);

        $code = ! empty($validated['code'])
            ? strtoupper(preg_replace('/[^a-zA-Z0-9_]/', '_', $validated['code']))
            : strtoupper(preg_replace('/[^a-zA-Z0-9_]/', '_', $validated['name']));

        $cat = ServiceCategory::create([
            'name' => trim($validated['name']),
            'code' => $code,
            'base_price' => $validated['base_price'],
            'description' => $validated['description'] ?? null,
            'is_active' => true,
        ]);

        return response()->json([
            'data' => [
                'id' => (string) $cat->id,
                'name' => $cat->name,
                'code' => $cat->code,
                'base_price' => (float) $cat->base_price,
                'description' => $cat->description ?? '',
                'is_active' => $cat->is_active,
            ],
            'message' => 'Kategori layanan baru berhasil ditambahkan.',
        ], 201);
    }

    public function update(Request $request, ServiceCategory $serviceCategory): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255', 'unique:service_categories,name,'.$serviceCategory->id],
            'base_price' => ['sometimes', 'numeric', 'min:0'],
            'description' => ['nullable', 'string', 'max:500'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        $serviceCategory->update($validated);

        return response()->json([
            'data' => [
                'id' => (string) $serviceCategory->id,
                'name' => $serviceCategory->name,
                'code' => $serviceCategory->code,
                'base_price' => (float) $serviceCategory->base_price,
                'description' => $serviceCategory->description ?? '',
                'is_active' => $serviceCategory->is_active,
            ],
            'message' => 'Kategori layanan berhasil diperbarui.',
        ]);
    }
}

