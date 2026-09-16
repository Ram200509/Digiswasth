const express = require('express');
const bcrypt = require('bcrypt');
const db = require('../config/db');

const router = express.Router();

router.get('/hospitals', async (req, res) => {
  try {
    const [hospitals] = await db.promise().query(
      "SELECT hospital_id, hospital_name FROM hospitals ORDER BY hospital_name"
    );
    return res.status(200).json({ success: true, hospitals });
  } catch (error) {
    return res.status(500).json({ success: false, message: "Server error" });
  }
});

router.post('/register', async (req, res) => {
  try {
    const { full_name, email, phone, password, role, hospital_name, specialization } = req.body;

    const allowedRoles = ['counter', 'doctor', 'pharmacy', 'test'];

    if (!full_name || !email || !password || !role || !hospital_name) {
      return res.status(400).json({ success: false, message: "Required fields missing" });
    }

    if (!allowedRoles.includes(role)) {
      return res.status(400).json({ success: false, message: "Invalid role" });
    }

    const [existing] = await db.promise().query(
      "SELECT staff_id FROM hospital_staff WHERE email = ?",
      [email]
    );

    if (existing.length > 0) {
      return res.status(400).json({ success: false, message: "Email already registered" });
    }

    const [hospitals] = await db.promise().query(
      "SELECT hospital_id FROM hospitals WHERE hospital_name = ?",
      [hospital_name]
    );

    if (hospitals.length === 0) {
      return res.status(404).json({ success: false, message: "Hospital not found" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const [result] = await db.promise().query(
      `INSERT INTO hospital_staff
       (hospital_id, full_name, email, password, role, phone, specialization)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        hospitals[0].hospital_id,
        full_name,
        email,
        hashedPassword,
        role,
        phone || null,
        specialization || null
      ]
    );

    const staffId = result.insertId;
    const digiswasthStaffId = `DSS-2026-${String(staffId).padStart(6, '0')}`;

    await db.promise().query(
      "UPDATE hospital_staff SET digiswasth_staff_id = ? WHERE staff_id = ?",
      [digiswasthStaffId, staffId]
    );

    return res.status(201).json({
      success: true,
      message: "Admin account created",
      digiswasth_staff_id: digiswasthStaffId,
      role
    });
  } catch (error) {
    console.error("Admin register error:", error);
    return res.status(500).json({ success: false, message: "Server error" });
  }
});
router.get('/staff/:staff_id', async (req, res) => {
  try {
    const [staff] = await db.promise().query(
      `SELECT hs.staff_id, hs.digiswasth_staff_id, hs.full_name, hs.role,
              h.hospital_name
       FROM hospital_staff hs
       JOIN hospitals h ON hs.hospital_id = h.hospital_id
       WHERE hs.staff_id = ?`,
      [req.params.staff_id]
    );

    if (staff.length === 0) {
      return res.status(404).json({ success: false, message: "Staff not found" });
    }

    return res.status(200).json({ success: true, staff: staff[0] });
  } catch (error) {
    return res.status(500).json({ success: false, message: "Server error" });
  }
});

module.exports = router;