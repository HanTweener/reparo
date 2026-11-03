<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_customer_can_register_and_is_always_assigned_customer_role(): void
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Budi Santoso',
            'email' => 'budi@example.com',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
            'role_code' => 'ADMIN', // Tamper attempt should be ignored
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.user.email', 'budi@example.com')
            ->assertJsonPath('data.user.role_code', 'CUSTOMER');

        $this->assertDatabaseHas('users', [
            'email' => 'budi@example.com',
            'role_code' => 'CUSTOMER',
        ]);
    }

    public function test_login_returns_token_and_user_for_valid_credentials(): void
    {
        $user = User::create([
            'name' => 'Demo Customer',
            'email' => 'customer@reparo.test',
            'password' => Hash::make('Password123!'),
            'role_code' => 'CUSTOMER',
            'is_active' => true,
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'customer@reparo.test',
            'password' => 'Password123!',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure(['data' => ['user', 'token', 'message']])
            ->assertJsonPath('data.user.role_code', 'CUSTOMER');
    }

    public function test_login_returns_safe_generic_error_for_invalid_credentials(): void
    {
        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'nonexistent@reparo.test',
            'password' => 'WrongPassword!',
        ]);

        $response->assertStatus(401)
            ->assertJsonPath('error.code', 'INVALID_CREDENTIALS');
    }

    public function test_disabled_account_cannot_login(): void
    {
        User::create([
            'name' => 'Disabled User',
            'email' => 'disabled@reparo.test',
            'password' => Hash::make('Password123!'),
            'role_code' => 'CUSTOMER',
            'is_active' => false,
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'disabled@reparo.test',
            'password' => 'Password123!',
        ]);

        $response->assertStatus(403)
            ->assertJsonPath('error.code', 'ACCOUNT_DISABLED');
    }

    public function test_unauthenticated_me_request_is_rejected(): void
    {
        $response = $this->getJson('/api/v1/me');

        $response->assertStatus(401)
            ->assertJsonPath('error.code', 'UNAUTHENTICATED');
    }

    public function test_customer_cannot_access_admin_staff_management(): void
    {
        $customer = User::create([
            'name' => 'Customer User',
            'email' => 'cust@reparo.test',
            'password' => Hash::make('Password123!'),
            'role_code' => 'CUSTOMER',
            'is_active' => true,
        ]);

        $response = $this->actingAs($customer)->getJson('/api/v1/admin/staff');

        $response->assertStatus(403)
            ->assertJsonPath('error.code', 'FORBIDDEN');
    }

    public function test_admin_can_create_staff_account(): void
    {
        $admin = User::create([
            'name' => 'Admin User',
            'email' => 'admin@reparo.test',
            'password' => Hash::make('Password123!'),
            'role_code' => 'ADMIN',
            'is_active' => true,
        ]);

        $response = $this->actingAs($admin)->postJson('/api/v1/admin/staff', [
            'name' => 'Teknisi Baru',
            'email' => 'teknisi.baru@example.com',
            'password' => 'Password123!',
            'role_code' => 'TECHNICIAN',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.role_code', 'TECHNICIAN');

        $this->assertDatabaseHas('users', [
            'email' => 'teknisi.baru@example.com',
            'role_code' => 'TECHNICIAN',
            'created_by_user_id' => $admin->id,
        ]);
    }
}

