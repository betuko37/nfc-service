// ============================================
// MANEJO DE ERRORES TEMPRANO (antes de todo)
// ============================================
process.on('uncaughtException', (error) => {
  const msg = error.message || error.toString();
  console.error('[CRÍTICO] Excepción no capturada:', msg);
  try { addLog('error', `Excepción crítica: ${msg}`); } catch(e) {}
  // NO salir - mantener el servicio vivo
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('[CRÍTICO] Promesa rechazada:', reason);
  try { addLog('error', `Promesa rechazada: ${reason}`); } catch(e) {}
});

process.on('SIGTERM', () => {});
process.on('SIGINT', () => {});
process.on('SIGHUP', () => {});

// Mantener el proceso vivo
process.stdin.resume();
process.stdin.on('error', () => {});

// ============================================
// CARGA DE MÓDULOS CON MANEJO DE ERRORES
// ============================================
let NFC, express, cors, fs, path;

try {
  NFC = require('nfc-pcsc').NFC;
  express = require('express');
  cors = require('cors');
  fs = require('fs');
  path = require('path');
} catch (error) {
  console.error('[ERROR FATAL] No se pudieron cargar los módulos:', error.message);
  console.error('Asegúrate de que node_modules esté presente o usa el ejecutable compilado.');
  // Mantener el proceso vivo para diagnóstico
  setInterval(() => {
    console.log('[ESPERANDO] Servicio en espera debido a error de módulos...');
  }, 30000);
}

// ============================================
// INICIALIZACIÓN DEL SERVIDOR
// ============================================
let app;
try {
  app = express();
  app.use(cors());
} catch (error) {
  console.error('[ERROR] No se pudo inicializar Express:', error.message);
}

const PORT = 3001;
let lastCardId = null;
let isReaderConnected = false;
let serviceStartTime = Date.now();
let lastNfcActivity = Date.now();
let nfcInstance = null;

// ============================================
// FLAGS DE CONTROL PARA EVITAR BUCLES
// ============================================
let isReconnecting = false;          // Evita reconexiones simultáneas
let reconnectTimeout = null;         // Referencia al timeout de reconexión
let lastReconnectTime = 0;           // Última vez que se reconectó
const RECONNECT_COOLDOWN = 10000;    // 10 segundos mínimo entre reconexiones forzadas

// Sistema de logs
const logs = [];
const MAX_LOGS = 1000;

function addLog(type, message) {
  const logEntry = {
    timestamp: new Date().toISOString(),
    type: type,
    message: message
  };
  
  logs.push(logEntry);
  
  if (logs.length > MAX_LOGS) {
    logs.shift();
  }
  
  const timestamp = new Date().toLocaleTimeString();
  const prefix = type === 'error' ? '✗' : type === 'success' ? '✓' : type === 'warning' ? '⚠' : 'ℹ';
  console.log(`[${timestamp}] ${prefix} ${message}`);
}

// ============================================
// DETECCIÓN DE SUSPENSIÓN/REANUDACIÓN
// ============================================
let lastHeartbeat = Date.now();
const SUSPEND_THRESHOLD = 5000;

setInterval(() => {
  const now = Date.now();
  const elapsed = now - lastHeartbeat;
  
  if (elapsed > SUSPEND_THRESHOLD) {
    addLog('warning', `Sistema reanudado después de ${Math.round(elapsed / 1000)} segundos de suspensión`);
    handleSystemResume();
  }
  
  lastHeartbeat = now;
}, 1000);

function handleSystemResume() {
  // Esperar a que el sistema se estabilice antes de reconectar
  const timeSinceLastReconnect = Date.now() - lastReconnectTime;
  
  if (timeSinceLastReconnect < RECONNECT_COOLDOWN) {
    addLog('info', 'Esperando cooldown antes de reconectar...');
    return;
  }
  
  addLog('info', 'Iniciando recuperación después de suspensión...');
  
  // Cancelar cualquier reconexión pendiente
  if (reconnectTimeout) {
    clearTimeout(reconnectTimeout);
    reconnectTimeout = null;
  }
  
  // Esperar 5 segundos para que USB se estabilice
  reconnectTimeout = setTimeout(() => {
    safeReconnect();
  }, 5000);
}

// ============================================
// SISTEMA NFC CON RECONEXIÓN CONTROLADA
// ============================================
let currentReader = null;
let reconnectAttempts = 0;

// Reconexión segura (evita bucles)
function safeReconnect() {
  // Verificar cooldown
  const timeSinceLastReconnect = Date.now() - lastReconnectTime;
  if (timeSinceLastReconnect < RECONNECT_COOLDOWN && lastReconnectTime > 0) {
    addLog('info', `Cooldown activo, esperando ${Math.round((RECONNECT_COOLDOWN - timeSinceLastReconnect) / 1000)}s...`);
    return;
  }
  
  // Evitar reconexiones simultáneas
  if (isReconnecting) {
    addLog('info', 'Reconexión ya en progreso, ignorando...');
    return;
  }
  
  // Si ya está conectado, no hacer nada
  if (isReaderConnected && currentReader) {
    addLog('info', 'Lector ya conectado, no es necesario reconectar');
    return;
  }
  
  isReconnecting = true;
  lastReconnectTime = Date.now();
  
  addLog('info', 'Iniciando reconexión del sistema NFC...');
  
  try {
    // Cerrar lector actual silenciosamente
    if (currentReader) {
      try { currentReader.close(); } catch (e) {}
      currentReader = null;
    }
    
    // Cerrar instancia NFC actual silenciosamente
    if (nfcInstance) {
      try { nfcInstance.close(); } catch (e) {}
      nfcInstance = null;
    }
    
    isReaderConnected = false;
    
  } catch (error) {
    // Ignorar errores de cierre
  }
  
  // Esperar un momento y reinicializar
  setTimeout(() => {
    initializeNFC();
    isReconnecting = false;
  }, 2000);
}

// Inicializar el sistema NFC
function initializeNFC() {
  if (nfcInstance) {
    // Ya hay una instancia, no crear otra
    return;
  }
  
  addLog('info', 'Inicializando sistema NFC...');
  
  try {
    nfcInstance = new NFC();
    
    // Manejar errores del sistema NFC
    nfcInstance.on('error', (error) => {
      const msg = error.message || '';
      
      // Ignorar errores de SCardCancel (son normales al cerrar)
      if (msg.includes('SCardCancel') || msg.includes('0x80100002')) {
        return; // Ignorar silenciosamente
      }
      
      addLog('error', `Error en sistema NFC: ${msg}`);
    });
    
    // Manejar conexión de lector
    nfcInstance.on('reader', reader => {
      handleReaderConnected(reader);
    });
    
    addLog('success', 'Sistema NFC inicializado correctamente');
    
  } catch (error) {
    addLog('error', `Error al inicializar NFC: ${error.message}`);
    nfcInstance = null;
    
    // Reintentar en 10 segundos
    setTimeout(() => {
      if (!nfcInstance) {
        initializeNFC();
      }
    }, 10000);
  }
}

function handleReaderConnected(reader) {
  addLog('success', `Lector NFC conectado: ${reader.reader.name}`);
  isReaderConnected = true;
  currentReader = reader;
  reconnectAttempts = 0;
  lastNfcActivity = Date.now();

  reader.on('card', card => {
    lastNfcActivity = Date.now();
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
    
    // Ignorar errores comunes y de cancelación
    const ignorarErrores = [
      'transmitting', 'timeout', 'card removed', 'no card',
      'card not present', 'SCardCancel', '0x80100002'
    ];
    
    const esErrorIgnorable = ignorarErrores.some(patron => 
      errorMessage.toLowerCase().includes(patron.toLowerCase())
    );
    
    if (!esErrorIgnorable) {
      addLog('error', `Error en lector: ${errorMessage}`);
    }
  });

  reader.on('end', () => {
    addLog('warning', 'Lector desconectado');
    isReaderConnected = false;
    currentReader = null;
    
    // NO forzar reconexión inmediata, esperar a que el sistema NFC detecte el lector de nuevo
    // o esperar al próximo ciclo de verificación
  });
}

// Verificación periódica del estado (cada 15 segundos)
setInterval(() => {
  if (!isReaderConnected && !isReconnecting) {
    reconnectAttempts++;
    
    // Log cada 4 intentos (cada minuto aprox)
    if (reconnectAttempts % 4 === 1) {
      addLog('info', `Buscando lector NFC... (Intento ${reconnectAttempts})`);
    }
    
    // Si no hay instancia NFC, crear una
    if (!nfcInstance) {
      initializeNFC();
    }
  }
}, 15000);

// Inicializar NFC al arrancar
initializeNFC();

// ============================================
// ENDPOINTS HTTP
// ============================================

app.get('/last-card', (req, res) => {
  res.json({ 
    cardId: lastCardId,
    readerConnected: isReaderConnected
  });
  lastCardId = null;
});

app.get('/status', (req, res) => {
  const uptimeMs = Date.now() - serviceStartTime;
  const uptimeMinutes = Math.floor(uptimeMs / 60000);
  const uptimeHours = Math.floor(uptimeMinutes / 60);
  const uptimeDays = Math.floor(uptimeHours / 24);
  
  let uptimeStr = '';
  if (uptimeDays > 0) uptimeStr += `${uptimeDays}d `;
  if (uptimeHours % 24 > 0) uptimeStr += `${uptimeHours % 24}h `;
  uptimeStr += `${uptimeMinutes % 60}m`;
  
  res.json({ 
    status: 'running',
    readerConnected: isReaderConnected,
    port: PORT,
    uptime: uptimeStr.trim(),
    uptimeMs: uptimeMs,
    logsAvailable: true,
    logsCount: logs.length,
    isReconnecting: isReconnecting
  });
});

app.get('/diagnostic', (req, res) => {
  res.json({
    service: 'NFC Service',
    version: '2.1-stable',
    endpoints: ['/status', '/last-card', '/logs', '/logs/clear', '/console', '/restart-nfc', '/'],
    logsCount: logs.length,
    readerConnected: isReaderConnected,
    uptimeMs: Date.now() - serviceStartTime,
    reconnectAttempts: reconnectAttempts,
    isReconnecting: isReconnecting
  });
});

app.post('/restart-nfc', (req, res) => {
  addLog('info', 'Reinicio NFC solicitado manualmente');
  lastReconnectTime = 0; // Reset cooldown
  safeReconnect();
  res.json({ success: true, message: 'Reinicio NFC iniciado' });
});

app.get('/restart-nfc', (req, res) => {
  addLog('info', 'Reinicio NFC solicitado manualmente');
  lastReconnectTime = 0;
  safeReconnect();
  res.json({ success: true, message: 'Reinicio NFC iniciado' });
});

app.get('/logs', (req, res) => {
  const limit = parseInt(req.query.limit) || 100;
  res.json(logs.slice(-limit));
});

app.post('/logs/clear', (req, res) => {
  logs.length = 0;
  addLog('info', 'Logs limpiados');
  res.json({ success: true });
});

function serveConsole(req, res) {
  try {
    const possiblePaths = [
      path.join(__dirname, 'console.html'),
      path.resolve(process.cwd(), 'console.html'),
      path.join(path.dirname(process.execPath), 'console.html')
    ];
    
    let htmlContent = null;
    
    for (const tryPath of possiblePaths) {
      try {
        if (fs.existsSync(tryPath)) {
          htmlContent = fs.readFileSync(tryPath, 'utf8');
          break;
        }
      } catch (err) { continue; }
    }
    
    if (!htmlContent) {
      try {
        htmlContent = fs.readFileSync(path.join(__dirname, 'console.html'), 'utf8');
      } catch (err) {
        throw new Error('console.html no encontrado');
      }
    }
    
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.send(htmlContent);
  } catch (error) {
    res.status(500).send(`<h1>Error</h1><p>${error.message}</p>`);
  }
}

app.get('/console', serveConsole);
app.get('/', serveConsole);

// ============================================
// INICIO DEL SERVIDOR CON MANEJO DE ERRORES
// ============================================
try {
  const server = app.listen(PORT, () => {
    addLog('info', `Servicio NFC v2.1-stable iniciado en puerto ${PORT}`);
    addLog('info', 'Esperando lector ACR122U...');
    console.log(`\n==========================================`);
    console.log(`  SERVICIO NFC v2.1-STABLE`);
    console.log(`==========================================`);
    console.log(`  Puerto: ${PORT}`);
    console.log(`  Consola: http://localhost:${PORT}/console`);
    console.log(`  `);
    console.log(`  [OK] Auto-reconexion: CONTROLADA`);
    console.log(`  [OK] Cooldown: 10 segundos`);
    console.log(`  [OK] Deteccion suspension: ACTIVADA`);
    console.log(`  `);
    console.log(`  Esperando lector ACR122U...`);
    console.log(`==========================================\n`);
  });

  server.on('error', (error) => {
    if (error.code === 'EADDRINUSE') {
      console.error(`[ERROR] El puerto ${PORT} ya está en uso.`);
      addLog('error', `Puerto ${PORT} en uso - otro proceso lo está usando`);
    } else {
      console.error('[ERROR] Error del servidor:', error.message);
      addLog('error', `Error del servidor: ${error.message}`);
    }
  });
} catch (error) {
  console.error('[ERROR FATAL] No se pudo iniciar el servidor:', error.message);
}

// Mantener el proceso vivo indefinidamente
setInterval(() => {}, 60000);
