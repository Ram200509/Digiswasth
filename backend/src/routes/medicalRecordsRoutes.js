const express = require('express');
const crypto = require('crypto');
const db = require('../config/db');

const router = express.Router();

// ==================== CREATE MEDICAL RECORD (HASH CHAINING) ====================
router.post('/create', async (req, res) => {
  try {
    const { patient_id, appointment_id, record_type, record_data, created_by } = req.body;

    if (!patient_id || !record_type || !record_data || !created_by) {
      return res.status(400).json({
        success: false,
        message: "patient_id, record_type, record_data and created_by are required"
      });
    }

    // 1. Get the latest record of this patient to find previous_hash
    const [latestRecords] = await db.promise().query(
      `SELECT current_hash FROM medical_records 
       WHERE patient_id = ? 
       ORDER BY record_id DESC LIMIT 1`,
      [patient_id]
    );

    const previous_hash = latestRecords.length > 0 ? latestRecords[0].current_hash : null;

    // 2. Create current_hash
    const timestamp = new Date().toISOString();
    const dataToHash = JSON.stringify({
      patient_id,
      appointment_id,
      record_type,
      record_data,
      previous_hash,
      timestamp
    });

    const current_hash = crypto
      .createHash('sha256')
      .update(dataToHash)
      .digest('hex');

    // 3. Insert the new record
    await db.promise().query(
      `INSERT INTO medical_records 
       (patient_id, appointment_id, record_type, record_data, created_by, previous_hash, current_hash)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        patient_id,
        appointment_id || null,
        record_type,
        JSON.stringify(record_data),
        created_by,
        previous_hash,
        current_hash
      ]
    );

    return res.status(201).json({
      success: true,
      message: "Medical record created successfully with hash chaining",
      current_hash,
      previous_hash
    });

  } catch (error) {
    console.error("Error creating medical record:", error);
    return res.status(500).json({
      success: false,
      message: "Server error while creating medical record"
    });
  }
});

// ==================== GET MEDICAL RECORDS OF A PATIENT ====================
router.get('/patient/:patient_id', async (req, res) => {
  try {
    const { patient_id } = req.params;

    const [records] = await db.promise().query(
      `SELECT mr.*, hs.full_name AS created_by_name
       FROM medical_records mr
       LEFT JOIN hospital_staff hs ON mr.created_by = hs.staff_id
       WHERE mr.patient_id = ?
       ORDER BY mr.record_id ASC`,
      [patient_id]
    );

    return res.status(200).json({
      success: true,
      records
    });

  } catch (error) {
    console.error("Error fetching medical records:", error);
    return res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
});

// ==================== VERIFY HASH CHAIN ====================
router.get('/verify/:patient_id', async (req, res) => {
  try {
    const { patient_id } = req.params;

    const [records] = await db.promise().query(
      `SELECT * FROM medical_records WHERE patient_id = ? ORDER BY record_id ASC`,
      [patient_id]
    );

    if (records.length === 0) {
      return res.status(200).json({
        success: true,
        message: "No records found",
        isValid: true
      });
    }

    let isValid = true;
    let previousHash = null;

    for (let i = 0; i < records.length; i++) {
      const record = records[i];

      if (i === 0) {
        if (record.previous_hash !== null) {
          isValid = false;
          break;
        }
      } else {
        if (record.previous_hash !== previousHash) {
          isValid = false;
          break;
        }
      }

      previousHash = record.current_hash;
    }

    return res.status(200).json({
      success: true,
      isValid,
      totalRecords: records.length,
      message: isValid ? "Hash chain is valid" : "Hash chain is broken (possible tampering)"
    });

  } catch (error) {
    console.error("Error verifying hash chain:", error);
    return res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
});
router.get('/by-digiswasth/:digiswasth_id', async (req, res) => {
  try {
    const [patients] = await db.promise().query(
      "SELECT id FROM patients WHERE digiswasth_id = ?",
      [req.params.digiswasth_id]
    );

    if (patients.length === 0) {
      return res.status(404).json({ success: false, message: "Patient not found" });
    }

    const [records] = await db.promise().query(
      `SELECT mr.*, hs.full_name AS created_by_name,
              h.hospital_name, a.appointment_date
       FROM medical_records mr
       LEFT JOIN hospital_staff hs ON mr.created_by = hs.staff_id
       LEFT JOIN appointments a ON mr.appointment_id = a.appointment_id
       LEFT JOIN hospitals h ON a.hospital_id = h.hospital_id
       WHERE mr.patient_id = ?
       ORDER BY mr.record_id ASC`,
      [patients[0].id]
    );

    return res.status(200).json({ success: true, records });
  } catch (error) {
    return res.status(500).json({ success: false, message: "Server error" });
  }
});

module.exports = router;