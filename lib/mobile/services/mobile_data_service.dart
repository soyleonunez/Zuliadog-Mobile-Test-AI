import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuliadog/core/config.dart';

class MobileDataService {
  static final SupabaseClient _supabase = AppConfig.supabase;

  static Future<Map<String, dynamic>?> getPetOwner(String ownerId) async {
    try {
      final response = await _supabase
          .from('pet_owners')
          .select()
          .eq('id', ownerId)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error getting pet owner: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getPetsByOwner(
      String ownerId) async {
    try {
      final response = await _supabase
          .from('pets')
          .select()
          .eq('owner_id', ownerId)
          .eq('is_active', true)
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting pets: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getPetById(String petId) async {
    try {
      final response =
          await _supabase.from('pets').select().eq('id', petId).maybeSingle();
      return response;
    } catch (e) {
      print('Error getting pet: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getUpcomingAppointments(
      String ownerId) async {
    try {
      final pets = await getPetsByOwner(ownerId);
      final petIds = pets.map((pet) => pet['id']).toList();

      if (petIds.isEmpty) return [];

      final response = await _supabase
          .from('appointments')
          .select('*, pets(name, photo_url)')
          .inFilter('pet_id', petIds)
          .gte('appointment_date', DateTime.now().toIso8601String())
          .order('appointment_date');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting appointments: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAllAppointmentsByPet(
      String petId) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select()
          .eq('pet_id', petId)
          .order('appointment_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting appointments: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getMedicalFilesByPet(
      String petId) async {
    try {
      final response = await _supabase
          .from('medical_files')
          .select()
          .eq('pet_id', petId)
          .order('upload_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting medical files: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAllMedicalFilesByOwner(
      String ownerId) async {
    try {
      final pets = await getPetsByOwner(ownerId);
      final petIds = pets.map((pet) => pet['id']).toList();

      if (petIds.isEmpty) return [];

      final response = await _supabase
          .from('medical_files')
          .select('*, pets(name, photo_url)')
          .inFilter('pet_id', petIds)
          .order('upload_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting medical files: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getMedicalHistoryByPet(
      String petId) async {
    try {
      final response = await _supabase
          .from('medical_history')
          .select()
          .eq('pet_id', petId)
          .order('visit_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting medical history: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getVeterinaryContacts() async {
    try {
      final response = await _supabase
          .from('veterinary_contacts')
          .select()
          .order('clinic_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting veterinary contacts: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getDashboardStats(String ownerId) async {
    try {
      final pets = await getPetsByOwner(ownerId);
      final upcomingAppointments = await getUpcomingAppointments(ownerId);
      final allFiles = await getAllMedicalFilesByOwner(ownerId);

      return {
        'total_pets': pets.length,
        'upcoming_appointments': upcomingAppointments.length,
        'total_files': allFiles.length,
        'next_appointment': upcomingAppointments.isNotEmpty
            ? upcomingAppointments.first
            : null,
      };
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return {
        'total_pets': 0,
        'upcoming_appointments': 0,
        'total_files': 0,
        'next_appointment': null,
      };
    }
  }
}
