const { NFC } = require('nfc-pcsc');
const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());

const PORT = 3001;
let lastCardId = null;
let isReaderConnected = false;

// Sistema de logs
const logs = [];
const MAX_LOGS = 500; // Máximo de logs a mantener en memoria

function addLog(type, message) {
  const logEntry = {
    timestamp: new Date().toISOString(),
    type: type, // 'info', 'success', 'error', 'warning'
    message: message
  };
  
  logs.push(logEntry);
  
  // Mantener solo los últimos MAX_LOGS
  if (logs.length > MAX_LOGS) {
    logs.shift();
  }
  
  // También mostrar en consola
  const timestamp = new Date().toLocaleTimeString();
  const prefix = type === 'error' ? '✗' : type === 'success' ? '✓' : 'ℹ';
  console.log(`[${timestamp}] ${prefix} ${message}`);
}

const nfc = new NFC();

nfc.on('reader', reader => {
  addLog('success', `Lector NFC conectado: ${reader.reader.name}`);
  isReaderConnected = true;

  reader.on('card', card => {
    // Formatear ID: convertir a mayúsculas y agregar dos puntos
    const cardId = card.uid.toUpperCase().match(/.{1,2}/g).join(':');
    addLog('success', `Tarjeta detectada: ${cardId}`);
    lastCardId = cardId;
    
    setTimeout(() => {
      if (lastCardId === cardId) {
        lastCardId = null;
      }
    }, 5000);
  });

  reader.on('error', err => {
    addLog('error', `Error en lector: ${err.message || err}`);
  });

  reader.on('end', () => {
    addLog('warning', 'Lector desconectado');
    isReaderConnected = false;
  });
});

app.get('/last-card', (req, res) => {
  res.json({ 
    cardId: lastCardId,
    readerConnected: isReaderConnected
  });
  lastCardId = null;
});

app.get('/status', (req, res) => {
  res.json({ 
    status: 'running',
    readerConnected: isReaderConnected,
    port: PORT
  });
});

// Endpoint para obtener logs
app.get('/logs', (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 100;
    const recentLogs = logs.slice(-limit);
    console.log(`[DEBUG] Endpoint /logs llamado, retornando ${recentLogs.length} logs`);
    res.json(recentLogs);
  } catch (error) {
    console.error('[ERROR] Error en endpoint /logs:', error);
    res.status(500).json({ error: 'Error al obtener logs', message: error.message });
  }
});

// Endpoint para limpiar logs
app.post('/logs/clear', (req, res) => {
  logs.length = 0;
  addLog('info', 'Logs limpiados manualmente');
  res.json({ success: true, message: 'Logs limpiados' });
});

// Servir la consola web
app.get('/console', (req, res) => {
  res.sendFile(__dirname + '/console.html');
});

// Endpoint raíz también sirve la consola
app.get('/', (req, res) => {
  res.sendFile(__dirname + '/console.html');
});

app.listen(PORT, () => {
  addLog('info', `Servicio NFC iniciado en puerto ${PORT}`);
  addLog('info', 'Esperando lector ACR122U...');
  console.log(`\n=================================`);
  console.log(`  Servicio NFC iniciado`);
  console.log(`  Puerto: ${PORT}`);
  console.log(`  Consola: http://localhost:${PORT}/console`);
  console.log(`  Esperando lector ACR122U...`);
  console.log(`=================================\n`);
});