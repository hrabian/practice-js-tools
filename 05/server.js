const path = require('path');
const express = require('express');
const sqlite3 = require('sqlite3').verbose();

const app = express();
const PORT = process.env.PORT || 3000;

const dbPath = path.join(__dirname, 'bus_washes.db');
const db = new sqlite3.Database(dbPath);

db.serialize(() => {
  db.run(`
    CREATE TABLE IF NOT EXISTS washes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bus_number TEXT NOT NULL,
      wash_date TEXT NOT NULL
    )
  `);
});

app.use(express.json());
app.use(express.static(__dirname));

app.post('/api/washes', (req, res) => {
  const { busNumber, washDate } = req.body;

  if (!busNumber || !washDate) {
    return res.status(400).json({ error: 'Brak wymaganych danych.' });
  }

  const query = 'INSERT INTO washes (bus_number, wash_date) VALUES (?, ?)';
  db.run(query, [busNumber, washDate], function onInsert(error) {
    if (error) {
      return res.status(500).json({ error: 'Nie udało się zapisać wpisu.' });
    }

    return res.status(201).json({
      id: this.lastID,
      bus_number: busNumber,
      wash_date: washDate,
    });
  });
});

app.get('/api/washes/current-month', (_req, res) => {
  const now = new Date();
  const startDate = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().slice(0, 10);
  const endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0).toISOString().slice(0, 10);

  const query = `
    SELECT id, bus_number, wash_date
    FROM washes
    WHERE wash_date BETWEEN ? AND ?
    ORDER BY wash_date DESC, id DESC
  `;

  db.all(query, [startDate, endDate], (error, rows) => {
    if (error) {
      return res.status(500).json({ error: 'Nie udało się pobrać wpisów.' });
    }

    return res.json(rows);
  });
});

app.listen(PORT, () => {
  console.log(`Serwer działa na http://localhost:${PORT}`);
});
