import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  
  // For Android Emulator
  static const String baseUrl = "http://10.0.2.2:5000";

  // ==================== PATIENT REGISTRATION ====================
  static Future<Map<String, dynamic>> registerUser(
      String fullName, String email, String phone, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/patient/register'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "full_name": fullName,
        "email": email,
        "phone": phone,
        "password": password,
      }),
    );

    return jsonDecode(response.body);
  }

  // ==================== PATIENT LOGIN ====================
  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/patient/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    return jsonDecode(response.body);
  }

  // ==================== CONNECT TO HOSPITAL - Request OTP ====================
  static Future<Map<String, dynamic>> requestHospitalOTP({
    required String digiswasthId,
    required String hospitalName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/patient/request-otp'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "digiswasth_id": digiswasthId,
          "hospital_name": hospitalName,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        "success": false,
        "message": "Something went wrong. Please try again."
      };
    }
  }
  // ==================== CREATE DRAFT APPOINTMENT ====================
static Future<Map<String, dynamic>> createDraftAppointment({
  required String digiswasthId,
  required String hospitalName,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/patient/create-draft-appointment'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "digiswasth_id": digiswasthId,
        "hospital_name": hospitalName,
      }),
    );

    return jsonDecode(response.body);
  } catch (e) {
    return {
      "success": false,
      "message": "Something went wrong while creating draft appointment"
    };
  }
 }
 // ==================== GET PATIENT APPOINTMENTS ====================
static Future<Map<String, dynamic>> getAppointments(String digiswasthId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/patient/appointments/$digiswasthId'),
      headers: {"Content-Type": "application/json"},
    );

    return jsonDecode(response.body);
  } catch (e) {
    return {
      "success": false,
      "message": "Failed to fetch appointments"
    };
  }
 }
 // ==================== GET DOCTORS ====================
static Future<Map<String, dynamic>> getDoctors(int hospitalId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/patient/doctors/$hospitalId'),
      headers: {"Content-Type": "application/json"},
    );
    return jsonDecode(response.body);
  } catch (e) {
    return {"success": false, "message": "Failed to fetch doctors"};
  }
}

// ==================== UPDATE APPOINTMENT ====================
static Future<Map<String, dynamic>> updateAppointment({
  required int appointmentId,
  required int doctorId,
  required String appointmentDate,
  required String timeSlot,
  required bool consentMedicalHistory,
}) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/api/patient/update-appointment/$appointmentId'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "doctor_id": doctorId,
        "appointment_date": appointmentDate,
        "time_slot": timeSlot,
        "consent_medical_history": consentMedicalHistory,
      }),
    );
    return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Failed to update appointment"};
    }  
  }
}