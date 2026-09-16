const mysql = require('mysql2');

// Create a connection pool (recommended way)
const pool = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'digiswasth',
  port: 3306,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// Test the pool
pool.getConnection((err, connection) => {
  if (err) {
    console.error('❌ MySQL Pool Connection Failed:', err.message);
    return;
  }
  console.log('✅ Connected to DigiSwasth Database (XAMPP) using Pool');
  connection.release(); // Release the connection back to the pool
});

module.exports = pool;