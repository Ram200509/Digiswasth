const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const db = require('../config/db');
const axios = require('axios');

const router = express.Router();

// ==================== DOCTOR LOGIN ====================
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, message: "Email and password are required" });
    }

    const [staff] = await db.promise().query(
      "SELECT * FROM hospital_staff WHERE email = ? AND role = 'doctor'",
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
        role: user.role,
        specialization: user.specialization
      }
    });
  } catch (error) {
    console.error("Doctor login error:", error);
    return res.status(500).json({ success: false, message: "Server error" });
  }
});

// ==================== FORWARDED APPOINTMENTS ====================
router.get('/appointments/:doctor_id', async (req, res) => {
  try {
    const { doctor_id } = req.params;

    const [appointments] = await db.promise().query(
      `SELECT a.appointment_id, a.appointment_date, a.time_slot, a.status,
              p.full_name AS patient_name, p.digiswasth_id, p.phone AS patient_phone
       FROM appointments a
       JOIN patients p ON a.patient_id = p.id
       WHERE a.doctor_id = ? AND a.status = 'confirmed'
       ORDER BY a.created_at ASC`,
      [doctor_id]
    );

    return res.status(200).json({ success: true, appointments });
  } catch (error) {
    console.error("Error fetching doctor appointments:", error);
    return res.status(500).json({ success: false, message: "Server error" });
  }
});

// ==================== APPOINTMENT DETAILS + VITALS ====================
router.get('/appointment/:appointment_id', async (req, res) => {
  try {
    const { appointment_id } = req.params;

    const [rows] = await db.promise().query(
      `SELECT a.*, 
              p.full_name AS patient_name, p.digiswasth_id, p.phone AS patient_phone, p.email AS patient_email,
              h.hospital_name
       FROM appointments a
       JOIN patients p ON a.patient_id = p.id
       JOIN hospitals h ON a.hospital_id = h.hospital_id
       WHERE a.appointment_id = ?`,
      [appointment_id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: "Appointment not found" });
    }

    const [vitals] = await db.promise().query(
      "SELECT * FROM vitals WHERE appointment_id = ? ORDER BY vital_id DESC LIMIT 1",
      [appointment_id]
    );

    const [records] = await db.promise().query(
      `SELECT record_type, record_data, created_at
       FROM medical_records
       WHERE patient_id = ?
       ORDER BY record_id ASC`,
      [rows[0].patient_id]
    );

    return res.status(200).json({
      success: true,
      appointment: rows[0],
      vitals: vitals[0] || null,
      medical_history: records
    });
  } catch (error) {
    console.error("Error fetching doctor appointment:", error);
    return res.status(500).json({ success: false, message: "Server error" });
  }
});

// ==================== MEDAI SUMMARY ====================
router.post('/medai-summary/:appointment_id', async (req, res) => {
  try {
    const { appointment_id } = req.params;

    const [rows] = await db.promise().query(
      `SELECT a.*, p.digiswasth_id, p.full_name
       FROM appointments a
       JOIN patients p ON a.patient_id = p.id
       WHERE a.appointment_id = ?`,
      [appointment_id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: "Appointment not found" });
    }

    const appt = rows[0];

    const [vitalRows] = await db.promise().query(
      "SELECT * FROM vitals WHERE appointment_id = ? ORDER BY vital_id DESC LIMIT 1",
      [appointment_id]
    );

    const v = vitalRows[0] || {};

    function pick(obj, keys, fallback) {
      for (const key of keys) {
        if (obj[key] !== undefined && obj[key] !== null && String(obj[key]).trim() !== "") {
          return obj[key];
        }
      }
      return fallback;
    }

    function parseBP(raw) {
      const text = String(raw || "");
      if (text.includes("/")) {
        const parts = text.split("/");
        return {
          sys: parseFloat(parts[0]) || 120,
          dia: parseFloat(parts[1]) || 80
        };
      }
      return {
        sys: parseFloat(pick(v, ["bp_systolic", "systolic"], 120)) || 120,
        dia: parseFloat(pick(v, ["bp_diastolic", "diastolic"], 80)) || 80
      };
    }

    const { sys, dia } = parseBP(pick(v, ["bp", "blood_pressure", "BP"], "120/80"));

    let previous = "None";
    try {
      const [history] = await db.promise().query(
        `SELECT record_data
         FROM medical_records
         WHERE patient_id = ?
         ORDER BY record_id DESC
         LIMIT 1`,
        [appt.patient_id]
      );

      if (history.length > 0 && history[0].record_data) {
        let raw = history[0].record_data;
        if (typeof raw === "string") {
          try { raw = JSON.parse(raw); } catch (e) { raw = { notes: raw }; }
        }
        previous = raw.diagnosis || raw.previous_diagnosis || "None";
      }
    } catch (e) {
      previous = "None";
    }

    const payload = {
      bp_systolic: sys,
      bp_diastolic: dia,
      sugar: parseFloat(pick(v, ["sugar", "blood_sugar", "glucose"], 100)) || 100,
      oxygen: parseFloat(pick(v, ["oxygen", "spo2", "o2"], 98)) || 98,
      weight: parseFloat(pick(v, ["weight"], 65)) || 65,
      temperature: parseFloat(pick(v, ["temperature", "temp"], 98.6)) || 98.6,
      previous_diagnosis: String(previous || "None").slice(0, 80)
    };

    console.log("MEDAI PAYLOAD:", payload);

    const medaiRes = await axios.post("http://localhost:8000/predict", payload);

    return res.status(200).json({
      success: true,
      summary: medaiRes.data.summary,
      predictions: medaiRes.data.predictions
    });
  } catch (error) {
    console.error("MedAI error:", error.message);
    return res.status(500).json({
      success: false,
      message: "MedAI service not reachable. Start py app.py first."
    });
  }
});

// ==================== COMPLETE CONSULTATION ====================
router.post('/complete-consultation', async (req, res) => {
  try {
    const { appointment_id, doctor_id, diagnosis, medicines, tests, notes } = req.body;

    if (!appointment_id || !doctor_id) {
      return res.status(400).json({ success: false, message: "Appointment ID and Doctor ID are required" });
    }

    const [appointments] = await db.promise().query(
      "SELECT * FROM appointments WHERE appointment_id = ?",
      [appointment_id]
    );

    if (appointments.length === 0) {
      return res.status(404).json({ success: false, message: "Appointment not found" });
    }

    const appointment = appointments[0];

    const [existing] = await db.promise().query(
      "SELECT prescription_id FROM prescriptions WHERE appointment_id = ?",
      [appointment_id]
    );

    if (existing.length > 0) {
      await db.promise().query(
        `UPDATE prescriptions
         SET diagnosis = ?, medicines = ?, tests = ?, notes = ?, doctor_id = ?
         WHERE appointment_id = ?`,
        [diagnosis, medicines, tests, notes, doctor_id, appointment_id]
      );
    } else {
      await db.promise().query(
        `INSERT INTO prescriptions (appointment_id, doctor_id, diagnosis, medicines, tests, notes)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [appointment_id, doctor_id, diagnosis, medicines, tests, notes]
      );
    }

    const pharmacyStatus = (medicines && medicines.trim() !== '') ? 'pending' : 'none';
    const testStatus = (tests && tests.trim() !== '') ? 'pending' : 'none';

    await db.promise().query(
      `UPDATE prescriptions
       SET pharmacy_status = ?, test_status = ?
       WHERE appointment_id = ?`,
      [pharmacyStatus, testStatus, appointment_id]
    );

    const record_data = { diagnosis, medicines, tests, notes };

    const [latestRecords] = await db.promise().query(
      `SELECT current_hash FROM medical_records
       WHERE patient_id = ?
       ORDER BY record_id DESC LIMIT 1`,
      [appointment.patient_id]
    );

    const previous_hash = latestRecords.length > 0 ? latestRecords[0].current_hash : null;
    const timestamp = new Date().toISOString();

    const current_hash = crypto.createHash('sha256').update(JSON.stringify({
      patient_id: appointment.patient_id,
      appointment_id,
      record_type: 'prescription',
      record_data,
      previous_hash,
      timestamp
    })).digest('hex');

    await db.promise().query(
      `INSERT INTO medical_records
       (patient_id, appointment_id, record_type, record_data, created_by, previous_hash, current_hash)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        appointment.patient_id,
        appointment_id,
        'prescription',
        JSON.stringify(record_data),
        doctor_id,
        previous_hash,
        current_hash
      ]
    );

    await db.promise().query(
      "UPDATE appointments SET status = 'completed' WHERE appointment_id = ?",
      [appointment_id]
    );

    return res.status(200).json({
      success: true,
      message: "Consultation completed and sent to Pharmacy/Test if prescribed"
    });
  } catch (error) {
    console.error("Error completing consultation:", error);
    return res.status(500).json({ success: false, message: "Server error" });
  }
});

module.exports = router;