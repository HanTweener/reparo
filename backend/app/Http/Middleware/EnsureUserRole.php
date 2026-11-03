<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserRole
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if (! $user) {
            return response()->json([
                'error' => [
                    'code' => 'UNAUTHENTICATED',
                    'message' => 'Sesi tidak ditemukan atau telah kedaluwarsa.',
                ],
            ], Response::HTTP_UNAUTHORIZED);
        }

        if (! $user->is_active) {
            return response()->json([
                'error' => [
                    'code' => 'ACCOUNT_DISABLED',
                    'message' => 'Akun Anda telah dinonaktifkan.',
                ],
            ], Response::HTTP_FORBIDDEN);
        }

        if (! empty($roles) && ! in_array($user->role_code, $roles, true)) {
            return response()->json([
                'error' => [
                    'code' => 'FORBIDDEN',
                    'message' => 'Anda tidak memiliki hak akses untuk tindakan ini.',
                ],
            ], Response::HTTP_FORBIDDEN);
        }

        return $next($request);
    }
}

