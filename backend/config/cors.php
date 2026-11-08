<?php

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],
    'allowed_methods' => ['*'],
    'allowed_origins' => env('CORS_ALLOWED_ORIGINS')
        ? array_filter(array_map('trim', explode(',', env('CORS_ALLOWED_ORIGINS'))))
        : array_filter([
            env('FRONTEND_URL'),
            'http://localhost',
            'http://localhost:*',
            'http://127.0.0.1:*',
        ]),
    'allowed_origins_patterns' => env('CORS_ALLOWED_ORIGINS_PATTERNS')
        ? array_filter(array_map('trim', explode(',', env('CORS_ALLOWED_ORIGINS_PATTERNS'))))
        : [],
    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 0,
    'supports_credentials' => true,
];

