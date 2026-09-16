require('dotenv').config();
const express = require('express');
const cors = require('cors');
const patientRoutes = require('./src/routes/patientRoutes');
const dummyConnectHospitalRoutes = require('./src/routes/dummyConnectHospitalRoutes');
const counterRoutes = require('./src/routes/counterRoutes');
const doctorRoutes = require('./src/routes/doctorRoutes');
const pharmacyRoutes = require('./src/routes/pharmacyRoutes');
const testRoutes = require('./src/routes/testRoutes');
const medicalRecordsRoutes = require('./src/routes/medicalRecordsRoutes');
const adminRoutes = require('./src/routes/adminRoutes');
//const connectHospitalRoutes = require('./src/routes/connectHospitalRoutes');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

// Use patient routes
app.use('/api/patient', patientRoutes);

// Test route
app.get('/', (req, res) => {
  res.json({ message: "DigiSwasth Backend is running!" });
});

app.listen(PORT, () => {
  console.log(`🚀 DigiSwasth Backend running on http://localhost:${PORT}`);
});


// Use connect hospital routes
//app.use('/api/patient', connectHospitalRoutes);
// Real version (keep it, don't delete)

// Dummy version (use this while developing)

app.use('/api/patient', dummyConnectHospitalRoutes);
app.use('/api/counter', counterRoutes);
app.use('/api/doctor', doctorRoutes);
app.use('/api/pharmacy', pharmacyRoutes);
app.use('/api/test', testRoutes);
app.use('/api/medical-records', medicalRecordsRoutes);
app.use('/api/admin', adminRoutes);