<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RepairOrder;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class AdminStaffController extends Controller
{
    /**
     * List staff accounts (Admin, Technician, Cashier) with task stats.
     */
    public function index(): JsonResponse
    {
        $staff = User::whereIn('role_code', ['ADMIN', 'TECHNICIAN', 'CASHIER'])
            ->orderBy('created_at', 'desc')
            ->get(['id', 'name', 'email', 'role_code', 'is_active', 'email_verified_at', 'created_at']);

        return response()->json([
            'data' => $staff->map(fn (User $user) => [
                'id' => (string) $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role_code' => $user->role_code,
                'is_active' => $user->is_active,
                'completed_tasks_count' => RepairOrder::where('current_technician_id', $user->id)
                    ->whereIn('status', ['COMPLETED', 'DELIVERED'])
                    ->count(),
                'email_verified_at' => $user->email_verified_at?->toIso8601String(),
                'created_at' => $user->created_at->toIso8601String(),
            ]),
        ]);
    }

    /**
     * Create a new Staff account (Admin, Technician, or Cashier).
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
            'role_code' => ['required', Rule::in(['ADMIN', 'TECHNICIAN', 'CASHIER'])],
        ]);

        $admin = $request->user();

        $staff = User::create([
            'name' => $validated['name'],
            'email' => strtolower(trim($validated['email'])),
            'password' => Hash::make($validated['password']),
            'role_code' => $validated['role_code'],
            'is_active' => true,
            'email_verified_at' => now(), // Staff provisioned by admin are verified
            'created_by_user_id' => $admin->id,
        ]);

        return response()->json([
            'data' => [
                'id' => (string) $staff->id,
                'name' => $staff->name,
                'email' => $staff->email,
                'role_code' => $staff->role_code,
                'is_active' => $staff->is_active,
                'created_at' => $staff->created_at->toIso8601String(),
                'message' => 'Akun staf berhasil dibuat.',
            ],
        ], 201);
    }

    /**
     * Activate or deactivate staff account.
     */
    public function updateStatus(Request $request, User $user): JsonResponse
    {
        $admin = $request->user();

        if ($user->id === $admin->id) {
            return response()->json([
                'error' => [
                    'code' => 'SELF_ACTION_DENIED',
                    'message' => 'Anda tidak dapat menonaktifkan akun Anda sendiri.',
                ],
            ], 422);
        }

        $validated = $request->validate([
            'is_active' => ['required', 'boolean'],
        ]);

        $user->update([
            'is_active' => $validated['is_active'],
        ]);

        return response()->json([
            'data' => [
                'id' => (string) $user->id,
                'name' => $user->name,
                'is_active' => $user->is_active,
                'message' => $user->is_active ? 'Akun staf telah diaktifkan.' : 'Akun staf telah dinonaktifkan.',
            ],
        ]);
    }
}
