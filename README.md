# NFC Service

Servicio REST para leer tarjetas NFC usando el lector ACR122U. El servicio detecta tarjetas NFC y expone los IDs formateados a través de una API HTTP simple.

## 📋 Características

- ✅ Detección automática de tarjetas NFC
- ✅ Formato de ID en mayúsculas con separadores (`83:BF:6E:BE`)
- ✅ API REST simple con CORS habilitado
- ✅ Estado del lector en tiempo real
- ✅ Auto-limpieza de IDs después de 5 segundos
- ✅ Consola web para visualizar logs en tiempo real

## 🚀 Instalación

1. **Clonar o descargar el proyecto**

2. **Instalar dependencias:**
```bash
npm install
```

3. **Si usas macOS, validar PC/SC y driver CCID**
   - Instala el driver oficial ACS para macOS (el que ya tienes en este repo).
   - Reinicia el equipo después de instalar el driver (recomendado).
   - Verifica que el servicio PC/SC esté disponible:
```bash
pcsctest
```
   Si ves que detecta el lector, el sistema está listo.

4. **Conectar el lector ACR122U** a tu computadora

5. **Iniciar el servicio:**
```bash
npm start
```

El servicio se iniciará en el puerto `47321` por defecto.

## 🍎 Instalador macOS (driver + servicio auto inicio)

Si quieres una instalacion estilo "setup" (como en Windows), usa:

```bash
bash ./macos/install-macos.command
```

Este instalador:
- instala el servicio en modo usuario (sin admin)
- intenta detectar driver ACS ya instalado
- si no hay driver, pregunta si deseas instalarlo (ese paso si pide password)
- crea una instalacion local en `~/.nfc-service`
- descarga un runtime Node LTS compatible en `~/.nfc-service/runtime` (no depende del Node del sistema)
- instala dependencias Node para macOS con ese runtime
- registra auto inicio con `launchd`
- levanta el servicio en segundo plano

### Desinstalar en macOS

```bash
bash ./macos/uninstall-macos.command
```

Logs del servicio en macOS:
- `~/.nfc-service/logs/service.log`
- `~/.nfc-service/logs/launchd.err.log`
- `~/.nfc-service/logs/launchd.out.log`

### Crear instalador DMG (arrastrar y abrir)

Si ya instalaste `create-dmg` con Homebrew, genera el instalador así:

```bash
bash ./macos/build-dmg.command
```

El script crea:
- `dist-macos/NFC-Service-Installer.dmg`
- dentro del DMG:
  - `INSTALAR.command` (icono centrado; instrucciones en el fondo del DMG)
- con fondo personalizado 500x500: logo JORNALPRO arriba, panel de pasos abajo, nubes y siluetas agrícolas

El script crea:
- `dist-macos/NFC-Service-Installer.dmg`
- dentro del DMG:
  - `INSTALAR.app` (aplicación nativa; instrucciones en el fondo del DMG)
- con fondo personalizado 500x500: logo JORNALPRO arriba, panel de pasos abajo, nubes y siluetas agrícolas

Flujo para usuario final:
1. Abrir DMG (doble clic)
2. Doble clic en `INSTALAR`
3. Se ejecuta `install-macos.command` completo en Terminal
4. Al terminar: crea acceso en Desktop, abre consola web y deja el servicio en auto inicio

### Distribución web (evitar alerta de Gatekeeper)

macOS marca como "no verificado" cualquier archivo descargado de internet que no esté **firmado y notarizado** por Apple. No es un virus: es Gatekeeper.

Para publicar el DMG en tu web sin esa alerta necesitas:

1. Cuenta **Apple Developer** (99 USD/año)
2. Certificado **Developer ID Application** en tu Mac
3. Firmar y notarizar al generar el instalador:

```bash
export MACOS_SIGN_IDENTITY="Developer ID Application: TU EMPRESA (TEAMID)"
export APPLE_NOTARIZE_APPLE_ID="tu@email.com"
export APPLE_NOTARIZE_TEAM_ID="TEAMID"
export APPLE_NOTARIZE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"

bash ./macos/build-dmg.command
```

El build firma `INSTALAR.app`, los scripts y el DMG, y envía el DMG a Apple para notarización automática.

Si ya generaste el DMG, solo firma/notariza:

```bash
bash ./macos/sign-and-notarize.command dist-macos/NFC-Service-Installer.dmg
```

Sin notarización, el usuario puede abrirlo con clic derecho → **Abrir** (solo la primera vez).

**Nota:** `INSTALAR.app` guarda el instalador como un solo archivo `nfc-service-payload.tar.gz` dentro del bundle (no scripts sueltos). Esto reduce bloqueos de macOS/antivirus al descargar de internet y evita App Translocation.

La solución definitiva para que no aparezca “malicioso” al descargar es **firmar y notarizar** el DMG con Apple Developer.

### Publicar el DMG en tu frontend (React / Vite / Next)

**No pongas el DMG en `src/`** — el bundler puede corromper el archivo binario y el instalador falla.

1. Copia estos archivos a la carpeta **`public/`** de tu frontend (no `src/`):

```
public/NFC-Service-Installer.dmg
public/nfc-service-payload.tar.gz   (respaldo; opcional pero recomendado)
```

2. Enlace directo de descarga (ejemplo React):

```jsx
<a href="/NFC-Service-Installer.dmg" download="NFC-Service-Installer.dmg">
  Descargar instalador macOS
</a>
```

3. Flujo del usuario:
   - Descargar el DMG
   - Abrir el DMG (doble clic)
   - **Doble clic en INSTALAR** dentro del volumen montado
   - No arrastrar solo `INSTALAR.app` a Applications (macOS puede quitar archivos internos)

4. Tras publicar, verifica el tamaño del DMG descargado (~1,1 MB). Si es mucho menor, el archivo se corrompió al subirlo.

Si ya habias instalado antes, puedes desinstalar desde **Aplicaciones → Desinstalar NFC Service** o con:

```bash
bash ./macos/uninstall-macos.command
```

Nota Apple Silicon: `bless --openfolder` no existe en arm64; el build usa `bless --folder`, que es el metodo soportado.

## 📡 API Endpoints

### `GET /last-card`

Obtiene la última tarjeta detectada. El ID se limpia automáticamente después de ser consultado.

**Respuesta:**
```json
{
  "cardId": "83:BF:6E:BE",
  "readerConnected": true
}
```

**Ejemplo:**
```bash
curl http://localhost:47321/last-card
```

### `GET /status`

Obtiene el estado del servicio y del lector.

**Respuesta:**
```json
{
  "status": "running",
  "readerConnected": true,
  "port": 3001
}
```

**Ejemplo:**
```bash
curl http://localhost:47321/status
```

### `GET /logs`

Obtiene los logs del servicio (últimos 100 por defecto).

**Parámetros:**
- `limit` (opcional): Número de logs a obtener (máximo 500)

**Respuesta:**
```json
[
  {
    "timestamp": "2024-01-15T10:30:45.123Z",
    "type": "success",
    "message": "Tarjeta detectada: 83:BF:6E:BE"
  }
]
```

**Ejemplo:**
```bash
curl http://localhost:47321/logs?limit=50
```

### `POST /logs/clear`

Limpia todos los logs almacenados.

**Ejemplo:**
```bash
curl -X POST http://localhost:47321/logs/clear
```

### `GET /console`

Interfaz web para visualizar los logs en tiempo real.

**Acceso:**
Abre en tu navegador: `http://localhost:47321/console`

## 🖥️ Consola de Logs

El servicio incluye una consola web para visualizar los logs en tiempo real.

### Acceder a la consola

1. Inicia el servicio:
```bash
npm start
```

2. Abre tu navegador y ve a:
```
http://localhost:47321/console
```

### Características de la consola

- ✅ **Actualización automática** cada segundo
- ✅ **Auto-scroll** al final de los logs
- ✅ **Indicadores de estado** del lector y servicio
- ✅ **Filtrado por tipo** (info, success, error, warning)
- ✅ **Limpieza de logs** con un solo clic
- ✅ **Interfaz oscura** tipo terminal

### Tipos de logs

- **INFO** (azul): Información general del servicio
- **SUCCESS** (verde): Eventos exitosos (tarjetas detectadas, conexiones)
- **ERROR** (rojo): Errores del lector o servicio
- **WARNING** (amarillo): Advertencias (desconexiones)

## 💻 Uso en React

Ejemplo de componente React que consulta el servicio cada 300ms:

```jsx
import { useEffect, useState } from 'react';

function NFCCardReader() {
  const [cardId, setCardId] = useState(null);
  const [readerConnected, setReaderConnected] = useState(false);

  useEffect(() => {
    const fetchCard = async () => {
      try {
        const response = await fetch('http://localhost:47321/last-card');
        const data = await response.json();
        
        if (data.cardId) {
          setCardId(data.cardId);
        }
        setReaderConnected(data.readerConnected);
      } catch (error) {
        console.error('Error al consultar tarjeta:', error);
      }
    };

    // Polling cada 300ms - suficiente para NFC
    const interval = setInterval(fetchCard, 300);

    // Consulta inicial
    fetchCard();

    // Limpiar intervalo al desmontar
    return () => clearInterval(interval);
  }, []);

  return (
    <div>
      <h2>Lector NFC</h2>
      <p>Estado: {readerConnected ? '✓ Conectado' : '✗ Desconectado'}</p>
      {cardId ? (
        <div>
          <p>Tarjeta detectada:</p>
          <strong>{cardId}</strong>
        </div>
      ) : (
        <p>Acerca una tarjeta NFC...</p>
      )}
    </div>
  );
}

export default NFCCardReader;
```

## 🔧 Configuración

### Cambiar el puerto

Edita la variable `PORT` en `nfc-service.js`:

```javascript
const PORT = 47321; // Cambia este valor
```

### Formato del ID

El ID se formatea automáticamente:
- **Entrada:** `83bf6ebe`
- **Salida:** `83:BF:6E:BE` (mayúsculas con dos puntos)

El formato se aplica en la línea 20 de `nfc-service.js`.

## 📦 Compilar a ejecutable

Para crear un ejecutable `.exe` (Windows):

```bash
npm run build
```

Esto generará `nfc-service.exe` en el directorio raíz.

**Nota:** Requiere tener `pkg` instalado globalmente:
```bash
npm install -g pkg
```

## 🐛 Solución de problemas

### El lector no se detecta

1. Verifica que el lector ACR122U esté conectado
2. Asegúrate de tener los drivers instalados
3. Revisa la consola para ver mensajes de conexión

### Error de permisos (Linux/Mac)

En sistemas Unix, puede ser necesario ejecutar con permisos de administrador:

```bash
sudo npm start
```

### macOS no detecta el lector

1. Verifica que `pcsctest` vea el lector conectado
2. Si no aparece, reinstala el driver ACS y reconecta el USB
3. Reinicia el servicio NFC (`npm start`) después de reconectar el lector
4. Consulta `GET /diagnostic` para confirmar que el servicio detectó `platform: "macOS"`

### Puerto en uso

Si el puerto 47321 está ocupado, cambia el `PORT` en `nfc-service.js`.

## 📝 Formato del ID

El servicio formatea automáticamente los IDs de las tarjetas:

- **Original:** `83bf6ebe` (minúsculas, sin separadores)
- **Formateado:** `83:BF:6E:BE` (mayúsculas, con dos puntos cada 2 caracteres)

## 🔄 Flujo de trabajo

1. El servicio detecta una tarjeta NFC
2. El ID se formatea y se guarda en `lastCardId`
3. El cliente consulta `/last-card` y recibe el ID
4. El ID se limpia automáticamente después de ser consultado
5. Si no se consulta, el ID se limpia después de 5 segundos



