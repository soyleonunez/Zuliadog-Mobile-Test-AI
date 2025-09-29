// =====================================================
// SERVICIO DE AUTENTICACIÓN SIMPLE
// Sistema de login unificado para Zuliadog
// =====================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Usuario actual
  static User? get currentUser => _supabase.auth.currentUser;

  // Estado de autenticación
  static bool get isAuthenticated => currentUser != null;

  // ID del usuario actual
  static String? get currentUserId => currentUser?.id;

  // Email del usuario actual
  static String? get currentUserEmail => currentUser?.email;

  // =====================================================
  // MÉTODOS DE AUTENTICACIÓN
  // =====================================================

  /// Iniciar sesión con email y contraseña
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        print('✅ Usuario autenticado: ${response.user!.email}');
      }

      return response;
    } catch (e) {
      print('❌ Error en login: $e');
      rethrow;
    }
  }

  /// Registrar nuevo usuario
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
        },
      );

      if (response.user != null) {
        print('✅ Usuario registrado: ${response.user!.email}');
      }

      return response;
    } catch (e) {
      print('❌ Error en registro: $e');
      rethrow;
    }
  }

  /// Cerrar sesión
  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      print('✅ Sesión cerrada');
    } catch (e) {
      print('❌ Error al cerrar sesión: $e');
      rethrow;
    }
  }

  /// Cambiar contraseña
  static Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      print('✅ Contraseña actualizada');
    } catch (e) {
      print('❌ Error al cambiar contraseña: $e');
      rethrow;
    }
  }

  // =====================================================
  // MÉTODOS DE USUARIO
  // =====================================================

  /// Obtener información del usuario actual
  static Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    if (!isAuthenticated) return null;

    try {
      final response = await _supabase
          .from('users')
          .select('*')
          .eq('id', currentUserId!)
          .single();

      return response;
    } catch (e) {
      print('❌ Error al obtener info del usuario: $e');
      return null;
    }
  }

  /// Obtener clínicas del usuario actual
  static Future<List<Map<String, dynamic>>> getUserClinics() async {
    if (!isAuthenticated) return [];

    try {
      final response = await _supabase.from('user_clinic_roles').select('''
            clinic_id,
            role,
            clinics:clinic_id (
              id,
              name,
              address,
              phone,
              email
            )
          ''').eq('user_id', currentUserId!);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error al obtener clínicas: $e');
      return [];
    }
  }

  /// Obtener clínica activa del usuario
  static Future<Map<String, dynamic>?> getActiveClinic() async {
    final clinics = await getUserClinics();
    if (clinics.isEmpty) return null;

    // Retornar la primera clínica activa
    return clinics.first['clinics'];
  }

  /// Cambiar clínica activa (guardar en preferencias locales)
  static Future<void> setActiveClinic(String clinicId) async {
    // Aquí podrías guardar en SharedPreferences
    // Por ahora solo imprimimos
    print('🏥 Clínica activa cambiada a: $clinicId');
  }

  // =====================================================
  // MÉTODOS DE VERIFICACIÓN
  // =====================================================

  /// Verificar si el usuario tiene rol específico en una clínica
  static Future<bool> hasRoleInClinic({
    required String clinicId,
    required String role,
  }) async {
    if (!isAuthenticated) return false;

    try {
      final response = await _supabase
          .from('user_clinic_roles')
          .select('role')
          .eq('user_id', currentUserId!)
          .eq('clinic_id', clinicId)
          .single();

      return response['role'] == role;
    } catch (e) {
      print('❌ Error al verificar rol: $e');
      return false;
    }
  }

  /// Verificar si el usuario es administrador
  static Future<bool> isAdmin() async {
    if (!isAuthenticated) return false;

    try {
      final userInfo = await getCurrentUserInfo();
      return userInfo?['is_admin'] == true;
    } catch (e) {
      print('❌ Error al verificar admin: $e');
      return false;
    }
  }

  // =====================================================
  // MÉTODOS DE UTILIDAD
  // =====================================================

  /// Generar hash de contraseña (para desarrollo)
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Validar formato de email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validar fortaleza de contraseña
  static bool isStrongPassword(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]'));
  }

  // =====================================================
  // STREAM DE AUTENTICACIÓN
  // =====================================================

  /// Stream de cambios de autenticación
  static Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  /// Escuchar cambios de autenticación
  static void listenToAuthChanges(Function(AuthState) callback) {
    _supabase.auth.onAuthStateChange.listen(callback);
  }
}

// =====================================================
// MODELOS DE DATOS
// =====================================================

class UserInfo {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final bool isActive;
  final bool isAdmin;
  final DateTime createdAt;

  UserInfo({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.isActive,
    required this.isAdmin,
    required this.createdAt,
  });

  factory UserInfo.fromMap(Map<String, dynamic> map) {
    return UserInfo(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      fullName: map['full_name'] ?? '',
      phone: map['phone'],
      isActive: map['is_active'] ?? true,
      isAdmin: map['is_admin'] ?? false,
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class ClinicInfo {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String role;
  final bool isActive;

  ClinicInfo({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    required this.role,
    required this.isActive,
  });

  factory ClinicInfo.fromMap(Map<String, dynamic> map) {
    return ClinicInfo(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'],
      phone: map['phone'],
      email: map['email'],
      role: map['role'] ?? 'employee',
      isActive: true, // Siempre activo por ahora
    );
  }
}
