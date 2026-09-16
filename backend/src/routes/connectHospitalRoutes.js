const express = require('express');
const https = require('https');
const db = require('../config/db');

const router = express.Router();

// Temporary OTP storage (in-memory for prototype)
const otpStore = new Map();

// ==================== REQUEST OTP ====================
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

    const patient = patients[0];
    const phone = patient.phone;

    // Generate OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiry = Date.now() + 10 * 60 * 1000; // 10 minutes

    // Store OTP
    otpStore.set(digiswasth_id, { otp, expiry });

    // ==================== SEND REAL OTP VIA MSG91 ====================
    const authKey = "549803AkOhEUHR1skJ6a536ad6P1";
    const templateId = "6a5370792a337ce690053d42";

    const msg91Url = `https://api.msg91.com/api/v5/otp?authkey=${authKey}&mobile=91${phone}&otp=${otp}&template_id=${templateId}`;

    https.get(msg91Url, (msgRes) => {
      let data = '';
      msgRes.on('data', chunk => data += chunk);
      msgRes.on('end', () => {
        console.log(`✅ Real OTP sent to ${phone}`);
      });
    }).on('error', (err) => {
      console.error("MSG91 Error:", err.message);
    });

    return res.status(200).json({
      success: true,
      message: "OTP sent successfully to your registered mobile number.",
      digiswasth_id: digiswasth_id,
      hospital_name: hospital_name
    });

  } catch (error) {
    console.error("Error in /request-otp:", error);
    return res.status(500).json({
      success: false,
      message: "Server error while sending OTP"
    });
  }
});

module.exports = router;