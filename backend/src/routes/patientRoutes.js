const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../config/db');
const verifyToken = require('../middleware/auth');

const router = express.Router();

// ==================== PATIENT REGISTRATION ====================
router.post('/register', async (req, res) => {
  try {
    const { full_name, email, phone, password } = req.body;

    if (!full_name || !email || !phone || !password) {
      return res.status(400).json({ message: "All fields are required" });
    }

    const [existing] = await db.promise().query(
      "SELECT * FROM patients WHERE email = ?",
      [email]
    );

    if (existing.length > 0) {
      return res.status(400).json({ message: "Email already registered" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const year = new Date().getFullYear();
    const randomNum = Math.floor(100000 + Math.random() * 900000);
    const digiswasth_id = `DS-${year}-${randomNum}`;

    await db.promise().query(
      `INSERT INTO patients (digiswasth_id, full_name, email, phone, password) 
       VALUES (?, ?, ?, ?, ?)`,
      [digiswasth_id, full_name, email, phone, hashedPassword]
    );

    res.status(201).json({
      message: "Registration successful",
      digiswasth_id: digiswasth_id
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error during registration" });
  }
});

// ==================== PATIENT LOGIN ====================
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: "Email and password are required" });
    }

    const [patients] = await db.promise().query(
      "SELECT * FROM patients WHERE email = ?",
      [email]
    );

    if (patients.length === 0) {
      return res.status(401).json({ message: "Invalid email or password" });
    }

    const patient = patients[0];

    const isPasswordValid = await bcrypt.compare(password, patient.password);

    if (!isPasswordValid) {
      return res.status(401).json({ message: "Invalid email or password" });
    }

    const token = jwt.sign(
      { 
        id: patient.id,
        digiswasth_id: patient.digiswasth_id,
        email: patient.email 
      },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(200).json({
      message: "Login successful",
      token: token,
      digiswasth_id: patient.digiswasth_id,
      full_name: patient.full_name,
      email: patient.email
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error during login" });
  }
});

// ==================== PROTECTED PROFILE ROUTE ====================
router.get('/profile', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;

    const [patients] = await db.promise().query(
      "SELECT id, digiswasth_id, full_name, email, phone, created_at FROM patients WHERE id = ?",
      [userId]
    );

    if (patients.length === 0) {
      return res.status(404).json({ message: "Patient not found" });
    }

    res.status(200).json({
      message: "Profile fetched successfully",
      profile: patients[0]
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error fetching profile" });
  }
});

module.exports = router;