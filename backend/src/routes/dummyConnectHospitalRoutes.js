const express = require('express');
const db = require('../config/db');

const router = express.Router();

// In-memory OTP storage for dummy mode
const otpStore = new Map();

// ==================== DUMMY REQUEST OTP ====================
router.post('/request-otp', async (req, res) => {
  try {
    const { digiswasth_id, hospital_name } = req.body;

    if (!digiswasth_id || !hospital_name) {
      return res.status(400).json({ 
        success: false, 
        message: "DigiSwasth ID and Hospital Name are required" 
      });
    }

    // Check if DigiSwasth ID exists
    const [patients] = await db.promise().query(
      "SELECT * FROM patients WHERE digiswasth_id = ?",
      [digiswasth_id]
    );

    if (patients.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Invalid DigiSwasth ID"
      });
    }

    // Generate dummy OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiry = Date.now() + 10 * 60 * 1000; // 10 minutes

    // Store OTP
    otpStore.set(digiswasth_id, { otp, expiry });

    // Log OTP in terminal (for testing)
    console.log(`[DUMMY] OTP for ${digiswasth_id}: ${otp}`);

    return res.status(200).json({
      success: true,
      message: "OTP sent successfully (Dummy Mode)",
      digiswasth_id: digiswasth_id,
      hospital_name: hospital_name
    });

  } catch (error) {
    console.error("Error in dummy /request-otp:", error);
    return res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
});


// ==================== CREATE DRAFT APPOINTMENT AFTER OTP ====================
router.post('/create-draft-appointment', async (req, res) => {
  try {
    const { digiswasth_id, hospital_name } = req.body;

    if (!digiswasth_id || !hospital_name) {
      return res.status(400).json({
        success: false,
        message: "DigiSwasth ID and Hospital Name are required"
      });
    }

    // 1. Find patient
    const [patients] = await db.promise().query(
      "SELECT id FROM patients WHERE digiswasth_id = ?",
      [digiswasth_id]
    );

    if (patients.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Patient not found"
      });
    }

    const patientId = patients[0].id;

    // 2. Find hospital
    const [hospitals] = await db.promise().query(
      "SELECT hospital_id FROM hospitals WHERE hospital_name = ?",
      [hospital_name]
    );

    if (hospitals.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Hospital not found"
      });
    }

    const hospitalId = hospitals[0].hospital_id;

    // 3. Check if a draft already exists for this patient + hospital
    const [existing] = await db.promise().query(
      "SELECT * FROM appointments WHERE patient_id = ? AND hospital_id = ? AND status = 'draft'",
      [patientId, hospitalId]
    );

    if (existing.length > 0) {
      return res.status(200).json({
        success: true,
        message: "Draft appointment already exists",
        appointment_id: existing[0].appointment_id
      });
    }

    // 4. Create new draft appointment
    // Note: doctor_id is temporarily set to NULL or a default. We will update it later.
    const [result] = await db.promise().query(
      `INSERT INTO appointments 
       (patient_id, hospital_id, doctor_id, appointment_date, time_slot, status, consent_medical_history) 
       VALUES (?, ?, NULL, CURDATE(), 'Not Selected', 'draft', false)`,
      [patientId, hospitalId]
    );

    return res.status(201).json({
      success: true,
      message: "Draft appointment created successfully",
      appointment_id: result.insertId
    });

  } catch (error) {
    console.error("Error creating draft appointment:", error);
    return res.status(500).json({
      success: false,
      message: "Server error while creating draft appointment"
    });
  }
});
// ==================== GET PATIENT APPOINTMENTS ====================
router.get('/appointments/:digiswasth_id', async (req, res) => {
  try {
    const { digiswasth_id } = req.params;

    // Find patient
    const [patients] = await db.promise().query(
      "SELECT id FROM patients WHERE digiswasth_id = ?",
      [digiswasth_id]
    );

    if (patients.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Patient not found"
      });
    }

    const patientId = patients[0].id;

    // Get appointments with hospital name
    const [appointments] = await db.promise().query(
      `SELECT a.appointment_id, a.status, a.appointment_date, a.time_slot, 
              h.hospital_name, h.hospital_id
       FROM appointments a
       JOIN hospitals h ON a.hospital_id = h.hospital_id
       WHERE a.patient_id = ? 
       AND a.status IN ('draft', 'pending', 'confirmed')
       ORDER BY a.created_at DESC`,
      [patientId]
    );

    return res.status(200).json({
      success: true,
      appointments: appointments
    });

  } catch (error) {
    console.error("Error fetching appointments:", error);
    return res.status(500).json({
      success: false,
      message: "Server error while fetching appointments"
    });
  }
});
// ==================== GET DOCTORS OF A HOSPITAL ====================
router.get('/doctors/:hospital_id', async (req, res) => {
  try {
    const { hospital_id } = req.params;

    const [doctors] = await db.promise().query(
      `SELECT staff_id, full_name, specialization 
       FROM hospital_staff 
       WHERE hospital_id = ? AND role = 'doctor'`,
      [hospital_id]
    );

    return res.status(200).json({
      success: true,
      doctors: doctors
    });
  } catch (error) {
    console.error("Error fetching doctors:", error);
    return res.status(500).json({
      success: false,
      message: "Server error while fetching doctors"
    });
  }
});
// ==================== UPDATE DRAFT APPOINTMENT ====================
router.put('/update-appointment/:appointment_id', async (req, res) => {
  try {
    const { appointment_id } = req.params;
    const { doctor_id, appointment_date, time_slot, consent_medical_history } = req.body;

    if (!doctor_id || !appointment_date || !time_slot) {
      return res.status(400).json({
        success: false,
        message: "Doctor, Date and Time Slot are required"
      });
    }

    await db.promise().query(
      `UPDATE appointments 
       SET doctor_id = ?, appointment_date = ?, time_slot = ?, 
           consent_medical_history = ?, status = 'pending'
       WHERE appointment_id = ? AND status = 'draft'`,
      [doctor_id, appointment_date, time_slot, consent_medical_history ? 1 : 0, appointment_id]
    );

    return res.status(200).json({
      success: true,
      message: "Appointment submitted successfully"
    });
  } catch (error) {
    console.error("Error updating appointment:", error);
    return res.status(500).json({
      success: false,
      message: "Server error while updating appointment"
    });
  }
});
module.exports = router;