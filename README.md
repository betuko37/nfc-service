# NFC Service

Servicio REST para leer tarjetas NFC usando el lector ACR122U. El servicio detecta tarjetas NFC y expone los IDs formateados a través de una API HTTP simple.

## 📋 Características

- ✅ Detección automática de tarjetas NFC
- ✅ Formato de ID en mayúsculas con separadores (`83:BF:6E:BE`)
- ✅ API REST simple con CORS habilitado
- ✅ Estado del lector en tiempo real
- ✅ Auto-limpieza de IDs después de 5 segundos

## 🚀 Instalación

1. **Clonar o descargar el proyecto**

2. **Instalar dependencias:**
```bash
npm install
```

3. **Conectar el lector ACR122U** a tu computadora

4. **Iniciar el servicio:**
```bash
npm start
```

El servicio se iniciará en el puerto `3001` por defecto.

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
curl http://localhost:3001/last-card
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
curl http://localhost:3001/status
```

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
        const response = await fetch('http://localhost:3001/last-card');
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
const PORT = 3001; // Cambia este valor
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

### Puerto en uso

Si el puerto 3001 está ocupado, cambia el `PORT` en `nfc-service.js`.

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



