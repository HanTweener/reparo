<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Register a new Customer account.
     * Public self-registration always assigns the CUSTOMER role.
     */
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => strtolower(trim($validated['email'])),
            'password' => Hash::make($validated['password']),
            'role_code' => 'CUSTOMER',
            'is_active' => true,
        ]);

        $token = $user->createToken('reparo-auth')->plainTextToken;

        return response()->json([
            'data' => [
                'user' => [
                    'id' => (string) $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role_code' => $user->role_code,
                    'email_verified_at' => $user->email_verified_at?->toIso8601String(),
                ],
                'token' => $token,
                'message' => 'Registrasi berhasil. Akun Customer telah dibuat.',
            ],
        ], 201);
    }

    /**
     * Sign in with email and password.
     */
    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'string', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', strtolower(trim($validated['email'])))->first();

        // Non-enumerating error for invalid user or password
        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            return response()->json([
                'error' => [
                    'code' => 'INVALID_CREDENTIALS',
                    'message' => 'Email atau kata sandi tidak cocok.',
                ],
            ], 401);
        }

        if (! $user->is_active) {
            return response()->json([
                'error' => [
                    'code' => 'ACCOUNT_DISABLED',
                    'message' => 'Akun Anda telah dinonaktifkan.',
                ],
            ], 403);
        }

        $token = $user->createToken('reparo-auth')->plainTextToken;

        return response()->json([
            'data' => [
                'user' => [
                    'id' => (string) $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role_code' => $user->role_code,
                    'email_verified_at' => $user->email_verified_at?->toIso8601String(),
                ],
                'token' => $token,
                'message' => 'Masuk berhasil.',
            ],
        ]);
    }

    /**
     * Invalidate current session/token.
     */
    public function logout(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user) {
            $user->currentAccessToken()?->delete();
        }

        return response()->json([
            'data' => [
                'message' => 'Berhasil keluar dari akun.',
            ],
        ]);
    }

    /**
     * Get authenticated user profile summary.
     */
    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'data' => [
                'id' => (string) $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role_code' => $user->role_code,
                'is_active' => $user->is_active,
                'email_verified_at' => $user->email_verified_at?->toIso8601String(),
            ],
        ]);
    }
}
