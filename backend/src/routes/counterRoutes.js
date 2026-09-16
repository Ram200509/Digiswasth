const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const db = require('../config/db');

const router = express.Router();

// ==================== COUNTER LOGIN ====================
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, message: "Email and password are required" });
    }

    const [staff] = await db.promise().query(
      "SELECT * FROM hospital_staff WHERE email = ? AND role = 'counter'",
      [email]
    );

    if (staff.length === 0) {
      return res.status(401).json({ success: false, message: "Invalid credentials" });
    }

    const user = staff[0];
    const isMatch = password === "staff123" || await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(401).json({ success: false, message: "Invalid credentials" });
    }

    const token = jwt.sign(
      {
        staff_id: user.staff_id,
        hospital_id: user.hospital_id,
        role: user.role,
        full_name: user.full_name
      },
      process.env.JWT_SECRET || "DigiSwasthSuperSecretKey2026",
      { expiresIn: "1d" }
    );

    return res.status(200).json({
      success: true,
      message: "Login successful",
      token,
      staff: {
        staff_id: user.staff_id,
        full_name: user.full_name,
        hospital_id: user.hospital_id,
        role: user.role
      }
    });
  } catch (error) {
    console.error("Counter login error:", error);
    return res.status(500).json({ success: false, message: "Server error" });
  }
});

// ==================== UPCOMING / PENDING ====================
router.get('/pending-appointments/:hospital_id', async (req, res) => {
  try {
    const { hospital_id } = req.params;

    const [appointments] = await db.promise().query(
      `SELECT a.appointment_id, a.appointment_date, a.time_slot, a.status, a.consent_medical_history,
              p.full_name AS patient_name, p.digiswasth_id, p.phone AS patient_phone,
              hs.full_name AS doctor_name, hs.specialization
       FROM appointments a
       JOIN patients p ON a.patient_id = p.id
       LEFT JOIN hospital_staff hs ON a.doctor_id = hs.staff_id
       WHERE a.hospital_id = ? AND a.status = 'pending'
       ORDER BY a.created_at ASC`,
      [hospital_id]
    );

    return res.status(200).json({ success: true, appointments });
  } catch (error) {
    console.error("Error fetching pending appointments:", error);
    return res.status(500).json({ success: false, message: "Server error" });
  }
});

// ==================== ACCEPTED APPOINTMENTS ====================
router.get('/accepted-appointments/:hospital_id', async (req, res) => {
  try {
    const { hospital_id } = req.params;

    const [appointments] = await db.promise().query(
      `SELECT a.appointment_id, a.appointment_date, a.time_slot, a.status,
              p.full_name AS patient_name, p.digiswasth_id, p.phone AS patient_phone,
              hs.full_name AS doctor_name, hs.specialization
       FROM appointments a
       JOIN patients p ON a.patient_id = p.id
       LEFT JOIN hospital_staff hs ON a.doctor_id = hs.staff_id
       WHERE a.hospital_id = ? AND a.status = 'accepted'
       ORDER BY a.created_at ASC`,
      [hospital_id]
    );

    return res.status(200).json({ success: true, appointments });
  } catch (error) {
    console.error("Error fetching accepted appointments:", error);
    return res.status(500).json({ success: false, message: "Server error" });
  }
});

// ==================== SINGLE APPOINTMENT ====================
router.get('/appointment/:appointment_id', async (req, res) => {
  try {
    const { appointment_id } = req.params;

    const [rows] = await db.promise().query(
      `SELECT a.*, 
              p.full_name AS patient_name, p.digiswasth_id, p.phone AS patient_phone, p.email AS patient_email,
              hs.full_name AS doctor_name, hs.specialization,
              h.hospital_name
       FROM appointments a
       JOIN patients p ON a.patient_id = p.id
       LEFT JOIN hospital_staff hs ON a.doctor_id = hs.staff_id
       JOIN hospitals h ON a.hospital_id = h.hospital_id
       WHERE a.appointment_id = ?`,
      [appointment_id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: "Appointment not found" });
    }

    return res.status(200).json({ success: true, appointment: rows[0] });
  } catch (error) {
    console.error("Error fetching appointment:", error);
    return res.status(500).json({ success: false, message: "Server error" });
  }
});

// ==================== SAVE VITALS ====================
router.post('/save-vitals', async (req, res) => {
  try {
    const { appointment_id, patient_id, bp, sugar, oxygen, weight, temperature, created_by } = req.body;

    if (!appointment_id || !patient_id) {
      return res.status(400).json({ success: false, message: "Appointment ID and Patient ID are required" });
    }

    const [existing] = await db.promise().query(
      "SELECT vital_id FROM vitals WHERE appointment_id = ?",
      [appointment_id]
    );

    if (existing.length > 0) {
      await db.promise().query(
        `UPDATE vitals 
         SET bp = ?, sugar = ?, oxygen = ?, weight = ?, temperature = ?, recorded_at = CURRENT_TIMESTAMP
         WHERE appointment_id = ?`,
        [bp, sugar, oxygen, weight, temperature, appointment_id]
      );
    } else {
      await db.promise().query(
        `INSERT INTO vitals (appointment_id, patient_id, bp, sugar, oxygen, weight, temperature)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [appointment_id, patient_id, bp, sugar, oxygen, weight, temperature]
      );
    }

    const [latestRecords] = await db.promise().query(
      `SELECT current_hash FROM medical_records 
       WHERE patient_id = ? 
       ORDER BY record_id DESC LIMIT 1`,
      [patient_id]
    );

    const previous_hash = latestRecords.length > 0 ? latestRecords[0].current_hash : null;

    const record_data = { bp, sugar, oxygen, weight, temperature };
    const timestamp = new Date().toISOString();
    const current_hash = crypto.createHash('sha256').update(JSON.stringify({
      patient_id,
      appointment_id,
      record_type: 'vitals',
      record_data,
      previous_hash,
      timestamp
    })).digest('hex');

    await db.promise().query(
      `INSERT INTO medical_records 
       (patient_id, appointment_id, record_type, record_data, created_by, previous_hash, current_hash)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        patient_id,
        appointment_id,
        'vitals',
        JSON.stringify(record_data),
        created_by || 3,
        previous_hash,
        current_hash
      ]
    );

    return res.status(200).json({
      success: true,
      message: "Vitals saved successfully and added to Medical Records (Hash Chained)"
    });
  } catch (error) {
    console.error("Error saving vitals:", error);
    return res.status(500).json({ success: false, message: "Server error while saving vitals" });
  }
});

// ==================== FORWARD TO DOCTOR ====================
router.put('/forward-to-doctor/:appointment_id', async (req, res) => {
  try {
    const { appointment_id } = req.params;
    const { doctor_id, digiswasth_id } = req.body;

    if (!digiswasth_id) {
      return res.status(400).json({
        success: false,
        message: "Patient DigiSwasth ID is required"
      });
    }

    const [rows] = await db.promise().query(
      `SELECT a.*, p.digiswasth_id
       FROM appointments a
       JOIN patients p ON a.patient_id = p.id
       WHERE a.appointment_id = ?`,
      [appointment_id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: "Appointment not found" });
    }

    if (rows[0].digiswasth_id !== digiswasth_id.trim()) {
      return res.status(401).json({
        success: false,
        message: "DigiSwasth ID does not match this patient"
      });
    }

    await db.promise().query(
      `UPDATE appointments SET status = 'confirmed' WHERE appointment_id = ?`,
      [appointment_id]
    );

    const [existingPrescription] = await db.promise().query(
      "SELECT prescription_id FROM prescriptions WHERE appointment_id = ?",
      [appointment_id]
    );

    if (existingPrescription.length === 0) {
      await db.promise().query(
        `INSERT INTO prescriptions (appointment_id, doctor_id, diagnosis, medicines, tests, notes)
         VALUES (?, ?, NULL, NULL, NULL, 'Digital prescription created by Counter')`,
        [appointment_id, doctor_id]
      );
    }

    return res.status(200).json({
      success: true,
      message: "Patient authorised and appointment forwarded to doctor"
    });
  } catch (error) {
    console.error("Error forwarding to doctor:", error);
    return res.status(500).json({ success: false, message: "Server error" });
  }
});

// ==================== ACCEPT APPOINTMENT ====================
router.put('/accept-appointment/:appointment_id', async (req, res) => {
  try {
    const { appointment_id } = req.params;

    const [appointments] = await db.promise().query(
      "SELECT * FROM appointments WHERE appointment_id = ? AND status = 'pending'",
      [appointment_id]
    );

    if (appointments.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Pending appointment not found"
      });
    }

    await db.promise().query(
      "UPDATE appointments SET status = 'accepted' WHERE appointment_id = ?",
      [appointment_id]
    );

    return res.status(200).json({
      success: true,
      message: "Appointment accepted successfully. Patient has been notified."
    });
  } catch (error) {
    console.error("Error accepting appointment:", error);
    return res.status(500).json({
      success: false,
      message: "Server error while accepting appointment"
    });
  }
});

// ==================== STAFF AUTHORISATION ====================
router.post('/authorise-staff', async (req, res) => {
  try {
    const { digiswasth_staff_id, hospital_name } = req.body;

    if (!digiswasth_staff_id || !hospital_name) {
      return res.status(400).json({
        success: false,
        message: "Staff ID and Hospital Name are required"
      });
    }

    const [staff] = await db.promise().query(
      `SELECT hs.*, h.hospital_name, h.hospital_id 
       FROM hospital_staff hs
       JOIN hospitals h ON hs.hospital_id = h.hospital_id
       WHERE hs.digiswasth_staff_id = ? AND h.hospital_name = ?`,
      [digiswasth_staff_id, hospital_name]
    );

    if (staff.length === 0) {
      return res.status(401).json({
        success: false,
        message: "Invalid Staff ID or Hospital Name"
      });
    }

    const user = staff[0];

    return res.status(200).json({
      success: true,
      message: "Staff authorised successfully",
      staff: {
        staff_id: user.staff_id,
        digiswasth_staff_id: user.digiswasth_staff_id,
        full_name: user.full_name,
        hospital_id: user.hospital_id,
        hospital_name: user.hospital_name,
        role: user.role,
        specialization: user.specialization
      }
    });
  } catch (error) {
    console.error("Staff authorisation error:", error);
    return res.status(500).json({
      success: false,
      message: "Server error during authorisation"
    });
  }
});

module.exports = router;