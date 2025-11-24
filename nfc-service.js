const { NFC } = require('nfc-pcsc');
const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());

const PORT = 3001;
let lastCardId = null;
let isReaderConnected = false;

const nfc = new NFC();

nfc.on('reader', reader => {
  console.log('✓ Lector NFC conectado:', reader.reader.name);
  isReaderConnected = true;

  reader.on('card', card => {
    // Formatear ID: convertir a mayúsculas y agregar dos puntos
    const cardId = card.uid.toUpperCase().match(/.{1,2}/g).join(':');
    console.log('✓ Tarjeta detectada:', cardId);
    lastCardId = cardId;
    
    setTimeout(() => {
      if (lastCardId === cardId) {
        lastCardId = null;
      }
    }, 5000);
  });

  reader.on('error', err => {
    console.error('✗ Error en lector:', err);
  });

  reader.on('end', () => {
    console.log('✗ Lector desconectado');
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

app.listen(PORT, () => {
  console.log(`\n=================================`);
  console.log(`  Servicio NFC iniciado`);
  console.log(`  Puerto: ${PORT}`);
  console.log(`  Esperando lector ACR122U...`);
  console.log(`=================================\n`);
});