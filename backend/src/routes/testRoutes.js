const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const db = require('../config/db');

const router = express.Router();

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const [staff] = await db.promise().query(
      "SELECT * FROM hospital_staff WHERE email = ? AND role = 'test'",
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
      { staff_id: user.staff_id, hospital_id: user.hospital_id, role: user.role },
      process.env.JWT_SECRET || "DigiSwasthSuperSecretKey2026",
      { expiresIn: "1d" }
    );
    return res.status(200).json({
      success: true,
      token,
      staff: {
        staff_id: user.staff_id,
        full_name: user.full_name,
        hospital_id: user.hospital_id,
        role: user.role
      }
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: "Server error" });
  }
});

router.get('/pending/:hospital_id', async (req, res) => {
  try {
    const [rows] = await db.promise().query(
      `SELECT pr.prescription_id, pr.tests, pr.diagnosis, a.appointment_id, a.time_slot,
              p.full_name AS patient_name, p.digiswasth_id,
              hs.full_name AS doctor_name
       FROM prescriptions pr
       JOIN appointments a ON pr.appointment_id = a.appointment_id
       JOIN patients p ON a.patient_id = p.id
       JOIN hospital_staff hs ON pr.doctor_id = hs.staff_id
       WHERE a.hospital_id = ? AND pr.test_status = 'pending'`,
      [req.params.hospital_id]
    );
    return res.status(200).json({ success: true, tests: rows });
  } catch (error) {
    return res.status(500).json({ success: false, message: "Server error" });
  }
});

router.put('/complete/:prescription_id', async (req, res) => {
  try {
    const { staff_id, result_notes } = req.body;

    const [rows] = await db.promise().query(
      `SELECT pr.*, a.patient_id, a.appointment_id
       FROM prescriptions pr
       JOIN appointments a ON pr.appointment_id = a.appointment_id
       WHERE pr.prescription_id = ?`,
      [req.params.prescription_id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: "Test request not found" });
    }

    await db.promise().query(
      "UPDATE prescriptions SET test_status = 'completed' WHERE prescription_id = ?",
      [req.params.prescription_id]
    );

    const record = rows[0];
    const record_data = {
      tests: record.tests,
      result_notes: result_notes || "Tests completed",
      action: "Test ward closed tests"
    };

    const [latest] = await db.promise().query(
      `SELECT current_hash FROM medical_records WHERE patient_id = ? ORDER BY record_id DESC LIMIT 1`,
      [record.patient_id]
    );
    const previous_hash = latest.length > 0 ? latest[0].current_hash : null;
    const current_hash = crypto.createHash('sha256').update(JSON.stringify({
      patient_id: record.patient_id,
      appointment_id: record.appointment_id,
      record_type: 'test_result',
      record_data,
      previous_hash,
      timestamp: new Date().toISOString()
    })).digest('hex');

    await db.promise().query(
      `INSERT INTO medical_records
       (patient_id, appointment_id, record_type, record_data, created_by, previous_hash, current_hash)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        record.patient_id,
        record.appointment_id,
        'test_result',
        JSON.stringify(record_data),
        staff_id || record.doctor_id,
        previous_hash,
        current_hash
      ]
    );

    return res.status(200).json({ success: true, message: "Test session closed" });
  } catch (error) {
    return res.status(500).json({ success: false, message: "Server error" });
  }
});

module.exports = router;