import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/repair_service.dart';
import 'package:frontend/services/technician_service.dart';
import 'package:frontend/state/auth_state.dart';

void main() {
  AuthState createTestAuthState() {
    return AuthState(
      apiService: ApiService(),
      repairService: RepairService(),
      technicianService: TechnicianService(),
    );
  }

  testWidgets('Reparo App renders login screen and toggles registration', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authState = createTestAuthState();
    await tester.pumpWidget(ReparoApp(authState: authState));

    expect(find.text('Reparo'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Daftar Pelanggan'), findsOneWidget);

    await tester.tap(find.text('Daftar Pelanggan'));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Akun Pelanggan'), findsOneWidget);
    expect(find.text('Daftar Sekarang'), findsOneWidget);
  });

  testWidgets('Quick demo customer signs in and renders workbench with booking action', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authState = createTestAuthState();
    await tester.pumpWidget(ReparoApp(authState: authState));

    await tester.tap(find.text('Pelanggan'));
    await tester.pumpAndSettle();

    expect(find.text('Halo, Demo Customer'), findsOneWidget);
    expect(find.text('Booking Maintenance'), findsOneWidget);
    expect(find.text('Alur Siklus Hidup Pesanan Perbaikan V1'), findsOneWidget);
  });

  testWidgets('Quick demo admin signs in and renders operations queue', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authState = createTestAuthState();
    await tester.pumpWidget(ReparoApp(authState: authState));

    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Antrean Operasional'), findsOneWidget);
    expect(find.text('Buat Booking Baru'), findsOneWidget);
  });

  testWidgets('Quick demo cashier signs in and renders cashier operations queue', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authState = createTestAuthState();
    await tester.pumpWidget(ReparoApp(authState: authState));

    await tester.tap(find.text('Kasir'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Antrean Operasional'), findsOneWidget);
    expect(find.text('Buat Booking Baru'), findsOneWidget);
  });

  testWidgets('Quick demo technician signs in and renders technician portal with scopes', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authState = createTestAuthState();
    await tester.pumpWidget(ReparoApp(authState: authState));

    await tester.tap(find.text('Teknisi'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Portal Teknisi'), findsOneWidget);
    expect(find.text('Tugas Saya'), findsWidgets);
    expect(find.text('Antrean Global'), findsWidgets);
    expect(find.text('Riwayat Selesai'), findsOneWidget);
  });
}
