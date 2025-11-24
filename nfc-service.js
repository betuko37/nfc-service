const { NFC } = require('nfc-pcsc');
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(cors());

const PORT = 3001;
let lastCardId = null;
let isReaderConnected = false;

// Sistema de logs
const logs = [];
const MAX_LOGS = 1000; // Máximo de logs a mantener en memoria (aumentado)

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
    const errorMessage = err.message || err.toString();
    
    // Filtrar errores comunes que son normales y no requieren registro
    const ignorarErrores = [
      'An error occurred while transmitting',
      'transmitting',
      'timeout',
      'card removed',
      'no card',
      'card not present'
    ];
    
    // Solo registrar errores importantes (no relacionados con transmisión normal)
    const esErrorImportante = !ignorarErrores.some(patron => 
      errorMessage.toLowerCase().includes(patron.toLowerCase())
    );
    
    if (esErrorImportante) {
      addLog('error', `Error en lector: ${errorMessage}`);
    }
    // Los errores de transmisión se ignoran silenciosamente (son normales)
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
    port: PORT,
    logsAvailable: true,
    logsCount: logs.length
  });
});

// Endpoint de diagnóstico
app.get('/diagnostic', (req, res) => {
  res.json({
    service: 'NFC Service',
    version: '1.0',
    endpoints: [
      '/status',
      '/last-card',
      '/logs',
      '/logs/clear',
      '/console',
      '/'
    ],
    logsCount: logs.length,
    readerConnected: isReaderConnected
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

// Función para leer y servir console.html
function serveConsole(req, res) {
  try {
    // Rutas posibles para el archivo HTML
    const possiblePaths = [
      path.join(__dirname, 'console.html'),
      path.resolve(process.cwd(), 'console.html'),
      path.join(path.dirname(process.execPath), 'console.html')
    ];
    
    let htmlContent = null;
    let htmlPath = null;
    
    // Intentar leer desde cada ruta posible
    for (const tryPath of possiblePaths) {
      try {
        if (fs.existsSync(tryPath)) {
          htmlContent = fs.readFileSync(tryPath, 'utf8');
          htmlPath = tryPath;
          break;
        }
      } catch (err) {
        // Continuar con la siguiente ruta
        continue;
      }
    }
    
    // Si no se encontró, intentar leer desde el snapshot de pkg
    if (!htmlContent) {
      try {
        // En pkg compilado, los assets están en el snapshot
        htmlContent = fs.readFileSync(path.join(__dirname, 'console.html'), 'utf8');
        htmlPath = 'snapshot';
      } catch (err) {
        throw new Error(`No se pudo encontrar console.html en ninguna de las rutas: ${possiblePaths.join(', ')}`);
      }
    }
    
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.send(htmlContent);
  } catch (error) {
    console.error('Error al leer console.html:', error);
    console.error('__dirname:', __dirname);
    console.error('process.cwd():', process.cwd());
    console.error('process.execPath:', process.execPath);
    res.status(500).send(`
      <html>
        <head><title>Error</title></head>
        <body style="font-family: Arial; padding: 20px;">
          <h1>Error al cargar la consola</h1>
          <p><strong>Error:</strong> ${error.message}</p>
          <p><strong>__dirname:</strong> ${__dirname}</p>
          <p><strong>process.cwd():</strong> ${process.cwd()}</p>
          <hr>
          <p>Por favor, verifica que console.html esté en la misma carpeta que nfc-service.exe</p>
        </body>
      </html>
    `);
  }
}

// Servir la consola web
app.get('/console', serveConsole);

// Endpoint raíz también sirve la consola
app.get('/', serveConsole);

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