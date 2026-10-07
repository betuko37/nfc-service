// Escucha embarques del servidor y los imprime en QZ Tray.
// Chrome puede estar cerrado: este proceso ya vive en la computadora del empaque.

const crypto = require("crypto");
const fs = require("fs");
const path = require("path");

let ioFactory = null;
let WebSocket = null;
try {
  ioFactory = require("socket.io-client").io;
  WebSocket = require("ws");
} catch (error) {
  ioFactory = null;
  WebSocket = null;
}

const QZ_PORTS = [
  ["wss", 8181],
  ["wss", 8282],
  ["wss", 8383],
  ["wss", 8484],
  ["ws", 8182],
  ["ws", 8283],
  ["ws", 8384],
  ["ws", 8485],
];

const PRINT_OPTIONS = {
  bounds: null,
  colorType: "color",
  copies: 1,
  density: 0,
  duplex: false,
  fallbackDensity: null,
  interpolation: "bicubic",
  jobName: "JornalPro",
  legacy: false,
  margins: 0,
  orientation: null,
  paperThickness: null,
  printerTray: null,
  rasterize: false,
  rotation: 0,
  scaleContent: true,
  size: null,
  units: "in",
  forceRaw: false,
  encoding: null,
  spool: null,
};

let log = (type, message) => {
  console.log(`[${type}] ${message}`);
};

let config = null;
let socket = null;
let qzSocket = null;
let qzConnectPromise = null;
let qzPending = new Map();
let recentShipments = new Set();

function configFilePath() {
  const besideExe = path.join(path.dirname(process.execPath), "print-config.json");
  const besideScript = path.join(__dirname, "print-config.json");
  if (fs.existsSync(besideExe) && !besideExe.includes("node_modules")) return besideExe;
  return besideScript;
}

function isLoopback(req) {
  const ip = String(req.socket?.remoteAddress || "");
  return ip === "127.0.0.1" || ip === "::1" || ip === "::ffff:127.0.0.1";
}

function loadConfigFromDisk() {
  try {
    const raw = fs.readFileSync(configFilePath(), "utf8");
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object") return null;
    return normalizeConfig(parsed);
  } catch {
    return null;
  }
}

function normalizeConfig(input) {
  const apiUrl = String(input.apiUrl || "").trim().replace(/\/$/, "");
  const token = String(input.token || "").trim();
  const locationId = String(input.locationId || "").trim();
  const packingCenterId = String(input.packingCenterId || "").trim();
  if (!apiUrl || !token || !locationId || !packingCenterId) return null;
  if (!/^https?:\/\//i.test(apiUrl)) return null;
  return { apiUrl, token, locationId, packingCenterId };
}

function saveConfig(next) {
  fs.writeFileSync(configFilePath(), JSON.stringify(next, null, 2), "utf8");
  config = next;
}

function socketOrigin(apiUrl) {
  try {
    return new URL(apiUrl).origin;
  } catch {
    return apiUrl.replace(/\/api.*$/i, "").replace(/\/$/, "");
  }
}

function status() {
  return {
    listening: Boolean(config && socket && socket.connected),
    packingCenterId: config?.packingCenterId || "",
    qzReady: Boolean(qzSocket && qzSocket.readyState === WebSocket?.OPEN),
  };
}

async function api(method, urlPath, body) {
  const response = await fetch(`${config.apiUrl}${urlPath}`, {
    method,
    headers: {
      Authorization: `Bearer ${config.token}`,
      "x-location-id": config.locationId,
      "Content-Type": "application/json",
    },
    body: body == null ? undefined : JSON.stringify(body),
  });
  const text = await response.text();
  let parsed = null;
  try {
    parsed = text ? JSON.parse(text) : null;
  } catch {
    parsed = text;
  }
  if (!response.ok) {
    const message =
      (parsed && typeof parsed === "object" && (parsed.message || parsed.error)) ||
      text ||
      "Error de API";
    throw new Error(typeof message === "string" ? message : "Error de API");
  }
  if (parsed && typeof parsed === "object" && typeof parsed.pdfBase64 !== "string" && parsed.data) {
    return parsed.data;
  }
  return parsed;
}

function pdfPayload(value) {
  const trimmed = String(value || "").trim();
  const marker = "base64,";
  const index = trimmed.indexOf(marker);
  return index >= 0 ? trimmed.slice(index + marker.length).trim() : trimmed;
}

function newUid() {
  return crypto.randomBytes(4).toString("hex").slice(0, 6);
}

function rejectPending(error) {
  for (const pending of qzPending.values()) pending.reject(error);
  qzPending.clear();
}

function bindQz(ws) {
  ws.on("message", (raw) => {
    let returned;
    try {
      returned = JSON.parse(String(raw));
    } catch {
      return;
    }
    if (!returned || returned.uid == null) return;
    const pending = qzPending.get(returned.uid);
    if (!pending) return;
    qzPending.delete(returned.uid);
    if (returned.error) pending.reject(new Error(String(returned.error)));
    else pending.resolve(returned.result);
  });
  ws.on("close", () => {
    if (qzSocket === ws) qzSocket = null;
    rejectPending(new Error("QZ Tray cerró la conexión."));
  });
  ws.on("error", () => {});
}

function qzCall(ws, payload) {
  return new Promise((resolve, reject) => {
    const uid = newUid();
    const message = {
      ...payload,
      timestamp: payload.timestamp || Date.now(),
      uid,
      position: { x: 0, y: 0 },
    };
    const timer = setTimeout(() => {
      qzPending.delete(uid);
      reject(new Error("QZ Tray no respondió."));
    }, 20000);
    qzPending.set(uid, {
      resolve: (value) => {
        clearTimeout(timer);
        resolve(value);
      },
      reject: (error) => {
        clearTimeout(timer);
        reject(error);
      },
    });
    ws.send(JSON.stringify(message));
  });
}

function openQzPort(protocol, port) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(`${protocol}://localhost:${port}`, {
      rejectUnauthorized: false,
      handshakeTimeout: 1200,
    });
    const fail = (error) => {
      try { ws.terminate(); } catch (e) {}
      reject(error);
    };
    const timer = setTimeout(() => fail(new Error("timeout")), 1200);
    ws.once("open", () => {
      clearTimeout(timer);
      ws.removeAllListeners("error");
      resolve(ws);
    });
    ws.once("error", (error) => {
      clearTimeout(timer);
      fail(error);
    });
  });
}

async function connectQz() {
  if (qzSocket && qzSocket.readyState === WebSocket.OPEN) return qzSocket;
  if (qzConnectPromise) return qzConnectPromise;
  qzConnectPromise = handshakeQz().finally(() => {
    qzConnectPromise = null;
  });
  return qzConnectPromise;
}

async function handshakeQz() {
  qzSocket = null;
  let lastError = new Error("QZ Tray no está abierto en esta computadora.");
  for (const [protocol, port] of QZ_PORTS) {
    let ws = null;
    try {
      ws = await openQzPort(protocol, port);
      bindQz(ws);
      await qzCall(ws, { call: "getVersion" });
      const certificate = await api("GET", "/packing/qz/certificate");
      const cert = typeof certificate === "string" ? certificate : "";
      if (!cert.trim()) throw new Error("El servidor no entregó el certificado de impresión.");
      await qzCall(ws, { certificate: cert });
      qzSocket = ws;
      return ws;
    } catch (error) {
      lastError = error;
      if (ws) {
        try { ws.terminate(); } catch (e) {}
      }
      if (qzSocket === ws) qzSocket = null;
    }
  }
  throw lastError;
}

async function printPdf(printerName, pdfBase64) {
  const timestamp = Date.now();
  const params = {
    printer: { name: printerName },
    options: PRINT_OPTIONS,
    data: [
      {
        type: "pixel",
        format: "pdf",
        flavor: "base64",
        data: pdfPayload(pdfBase64),
      },
    ],
  };
  const toSign = JSON.stringify({ call: "print", params, timestamp });
  const hashed = crypto.createHash("sha256").update(toSign).digest("hex");
  const signature = await api("POST", "/packing/qz/sign", { request: hashed });
  const signed = typeof signature === "string" ? signature : "";
  if (!signed) throw new Error("No se pudo firmar la impresión.");
  const ws = await connectQz();
  await qzCall(ws, {
    call: "print",
    params,
    timestamp,
    signature: signed,
    signAlgorithm: "SHA512",
  });
}

function rememberShipment(shipmentId) {
  recentShipments.add(shipmentId);
  setTimeout(() => recentShipments.delete(shipmentId), 10 * 60 * 1000);
}

async function onShipmentPrint(data) {
  const payload = data && typeof data === "object" ? data : {};
  const packingCenterId = String(payload.packingCenterId || "").trim();
  const shipmentId = String(payload.shipmentId || "").trim();
  if (!config || !packingCenterId || !shipmentId) return;
  if (packingCenterId !== config.packingCenterId) return;
  if (recentShipments.has(shipmentId)) return;
  rememberShipment(shipmentId);

  try {
    const printers = await api("GET", `/packing/printers/${encodeURIComponent(packingCenterId)}`);
    const printer = String(printers?.defaultShipmentPrinter || "").trim();
    if (!printer) {
      log("warning", "Este empaque no tiene impresora de embarque configurada.");
      recentShipments.delete(shipmentId);
      return;
    }
    const pdf = await api(
      "GET",
      `/packing/processes/shipment/${encodeURIComponent(shipmentId)}/manifest-pdf`,
    );
    const pdfBase64 = typeof pdf?.pdfBase64 === "string" ? pdf.pdfBase64 : "";
    if (!pdfBase64) throw new Error("El servidor no entregó el manifiesto.");
    await printPdf(printer, pdfBase64);
    log("success", `Manifiesto enviado a ${printer}.`);
  } catch (error) {
    recentShipments.delete(shipmentId);
    log("error", `No se pudo imprimir el embarque: ${error.message || error}`);
  }
}

function connectSocket() {
  if (!ioFactory || !config) return;
  if (socket) {
    socket.removeAllListeners();
    socket.disconnect();
    socket = null;
  }
  socket = ioFactory(socketOrigin(config.apiUrl), {
    path: "/socket.io/",
    transports: ["websocket", "polling"],
    auth: { token: config.token },
    reconnection: true,
    reconnectionDelay: 2000,
    reconnectionDelayMax: 10000,
  });
  socket.on("connect", () => {
    log("success", "Impresión enlazada. Chrome puede cerrarse; QZ Tray debe seguir abierto.");
  });
  socket.on("disconnect", (reason) => {
    log("warning", `Se cortó el enlace de impresión (${reason}). Reintentando...`);
  });
  socket.on("connect_error", (error) => {
    log("error", `No se pudo enlazar la impresión: ${error.message || error}`);
  });
  socket.on("shipment:print", (data) => {
    void onShipmentPrint(data);
  });
}

function applyConfig(next, source) {
  config = next;
  log("info", `Impresión lista para el centro de empaque (${source}).`);
  connectSocket();
}

function start({ app, log: writeLog }) {
  if (typeof writeLog === "function") log = writeLog;
  if (!ioFactory || !WebSocket) {
    log("warning", "Impresión QZ no disponible: faltan dependencias. Ejecuta npm install en nfc-service.");
    return;
  }
  if (!app) return;

  app.get("/print-status", (req, res) => {
    if (!isLoopback(req)) {
      res.status(403).json({ listening: false });
      return;
    }
    res.json(status());
  });

  app.post("/print-config", (req, res) => {
    if (!isLoopback(req)) {
      res.status(403).json({ ok: false });
      return;
    }
    const next = normalizeConfig(req.body || {});
    if (!next) {
      res.status(400).json({ ok: false, message: "Faltan datos para enlazar la impresión." });
      return;
    }
    try {
      saveConfig(next);
    } catch (error) {
      log("error", `No se pudo guardar la configuración de impresión: ${error.message || error}`);
      res.status(500).json({ ok: false });
      return;
    }
    applyConfig(next, "Empaque");
    res.json({ ok: true, packingCenterId: next.packingCenterId });
  });

  const stored = loadConfigFromDisk();
  if (stored) applyConfig(stored, "configuración guardada");
  else log("info", "Impresión en espera. Abre Empaque una vez en esta computadora para enlazar el centro.");
}

module.exports = { start, status };
