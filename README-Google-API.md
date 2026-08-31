# API de Google — Texticode

Documentación técnica de los endpoints de **autenticación con Google** y **Google Calendar** usados por Texticode. Cubre los dos flujos que coexisten en el backend:

- **Web** — flujo de redirect (`/api/google/...`), ya existente.
- **Móvil (Flutter)** — flujo con SDK nativo de Google Sign-In (`/api/auth/google/mobile` + `/api/calendar/...`), agregado para la app.

Base URL (desarrollo): `http://192.168.0.6:3001/api`

Todas las rutas protegidas requieren el header:

```
Authorization: Bearer <token>
```

El `<token>` es el JWT devuelto por `/api/auth/login` o `/api/auth/google/mobile`.

---

## 1. Autenticación

### 1.1 POST /api/auth/login

Login normal con usuario/contraseña. (Ya existente, incluido aquí por contexto.)

**Body**
```json
{
  "correo": "usuario@texticode.com",
  "contrasena": "MiPass123!"
}
```

**200 OK**
```json
{
  "token": "eyJhbGciOi...",
  "usuario": {
    "Id_Usuario": 1,
    "Nombre_Completo": "Camilo Tibambre",
    "Nombre_Usuario": "Camilo1",
    "Correo": "camilotibambre@gmail.com",
    "Id_Rol": 1,
    "Rol": "Administrador",
    "Estado": "activo"
  }
}
```

**Errores:** `400` datos incompletos · `401` credenciales incorrectas · `403` cuenta inactiva · `500` error interno.

---

### 1.2 POST /api/auth/google/mobile 🆕

Login desde la app móvil usando el SDK nativo de Google Sign-In. El celular nunca ve el `client_secret` ni el `refresh_token`: solo manda el `idToken` (identidad) y, opcionalmente, el `serverAuthCode` (para vincular Calendar en el mismo paso).

**Body**
```json
{
  "idToken": "eyJhbGciOi... (idToken de Google)",
  "accessToken": "ya29.a0... (opcional, no se usa para verificar identidad)",
  "serverAuthCode": "4/0Ab... (opcional — si se manda, vincula Calendar de una vez)"
}
```

**200 OK** — mismo formato exacto que `/api/auth/login`:
```json
{
  "token": "eyJhbGciOi...",
  "usuario": {
    "Id_Usuario": 1,
    "Nombre_Completo": "Camilo Tibambre",
    "Nombre_Usuario": "Camilo1",
    "Correo": "camilotibambre@gmail.com",
    "Id_Rol": 1,
    "Rol": "Administrador",
    "Estado": "activo"
  }
}
```

**Errores:**
| Código | Motivo |
|---|---|
| 400 | Falta `idToken` |
| 401 | `idToken` inválido o no verificado por Google |
| 403 | Cuenta inactiva |
| 404 | No existe un usuario Texticode con ese correo de Google (debe crearlo un admin primero) |
| 500 | Error interno |

**Notas:**
- Si `serverAuthCode` falla al vincular Calendar (código expirado, ya usado, etc.), el login **igual se completa** — el fallo de Calendar solo se loguea en el servidor, no bloquea el login.
- El `serverAuthCode` es de un solo uso. Si necesitas reintentar vincular Calendar por separado, usa `POST /api/calendar/connect` (ver abajo), no reintentes el login.

---

### 1.3 GET /api/google/auth-url?action=login|link

Flujo **web**: genera la URL de consentimiento de Google. `action=login` para iniciar sesión, `action=link` para vincular Calendar a una sesión ya activa (requiere `Authorization: Bearer`).

**200 OK**
```json
{
  "url": "https://accounts.google.com/o/oauth2/v2/auth?...",
  "scopes": ["openid", "email", "profile", "https://www.googleapis.com/auth/calendar", "https://www.googleapis.com/auth/calendar.events"]
}
```

### 1.4 GET /api/google/callback

Flujo **web**: callback que Google llama tras el consentimiento. Redirige al frontend (`/google-auth/callback` o `/login` con `?googleError=`). No se llama manualmente.

---

## 2. Google Calendar (móvil)

### 2.1 GET /api/calendar/status 🆕

Indica si el usuario autenticado ya vinculó Google Calendar.

**Headers:** `Authorization: Bearer <token>`

**200 OK**
```json
{
  "connected": true,
  "calendarEmail": "camilotibambre@gmail.com"
}
```
Si no está vinculado: `{ "connected": false, "calendarEmail": null }`

---

### 2.2 POST /api/calendar/connect 🆕

Vincula (o re-vincula) Google Calendar usando un `serverAuthCode` obtenido del SDK nativo. Se usa cuando el usuario ya tiene sesión (login normal) y decide vincular Calendar después, desde "Vincular con Google" en el perfil.

**Headers:** `Authorization: Bearer <token>`

**Body**
```json
{ "serverAuthCode": "4/0Ab..." }
```

**200 OK**
```json
{ "connected": true, "calendarEmail": "camilotibambre@gmail.com" }
```

**Errores:** `400` falta `serverAuthCode`, código inválido/expirado/ya usado, o `redirect_uri_mismatch` si por error se reintrodujo `redirect_uri` en el intercambio.

---

### 2.3 DELETE /api/calendar/connect 🆕

Desvincula Google Calendar del usuario autenticado (borra sus tokens guardados).

**Headers:** `Authorization: Bearer <token>`

**200 OK**
```json
{ "mensaje": "Google Calendar desvinculado correctamente." }
```

---

### 2.4 POST /api/calendar/sync 🆕

Sincroniza **todas** las órdenes visibles para el usuario actual (admin: todas · operario: las suyas · cliente: las suyas) como eventos en su Google Calendar — uno por cada `Fecha_Limite`.

**Headers:** `Authorization: Bearer <token>`

**200 OK**
```json
{ "creados": 3, "actualizados": 5, "total": 8 }
```

**Errores:** `400` si no hay Calendar vinculado, sync desactivado, o falla algún request a la API de Google.

---

### 2.5 POST /api/calendar/sync/:idOrden 🆕

Sincroniza una sola orden puntual (por ejemplo, justo después de crearla o de cambiar su `Fecha_Limite`).

**Headers:** `Authorization: Bearer <token>`

**Params:** `idOrden` — ID de la orden.

**200 OK**
```json
{ "mensaje": "Orden sincronizada correctamente." }
```

**Errores:** `404` orden no encontrada o sin acceso · `400` Calendar no vinculado o error de Google.

---

### 2.6 POST /api/google/sync/delivery-events

Flujo **web** equivalente a 2.4 (mismo propósito, nombre distinto, formato de respuesta con `results` detallado por orden). Mantenido para no romper la versión web existente.

### 2.7 GET /api/google/events/upcoming?limit=10

Lista los próximos eventos de Texticode en el Calendar vinculado (flujo web).

### 2.8 DELETE /api/google/unlink

Desvincula Calendar (equivalente web de 2.3, mismo efecto, ruta distinta).

### 2.9 GET /api/google/connected-users

Solo admin (`Id_Rol = 1`). Lista todos los usuarios y su estado de vinculación con Google.

### 2.10 PATCH /api/google/settings

Actualiza `syncEnabled` / `calendarId` del usuario autenticado.

---

## 3. Diferencias clave entre flujo Web y Móvil

| | Web | Móvil |
|---|---|---|
| Inicio | Redirect a Google | SDK nativo (`google_sign_in`) |
| Login | `GET /api/google/auth-url` → `GET /api/google/callback` | `POST /api/auth/google/mobile` |
| Vincular Calendar | `GET /api/google/auth-url?action=link` → callback | `POST /api/calendar/connect` |
| Intercambio de código | Con `redirect_uri` | **Sin** `redirect_uri` (`exchangeMobileAuthCode`) |
| Sincronizar | `POST /api/google/sync/delivery-events` | `POST /api/calendar/sync` |
| Respuesta de login | Redirect con querystring | JSON `{ token, usuario }` |

---

## 4. Variables de entorno requeridas

```
GOOGLE_CLIENT_ID=<Web Client ID de Google Cloud Console>
GOOGLE_CLIENT_SECRET=<secret del mismo cliente Web>
GOOGLE_REDIRECT_URI=http://localhost:3001/api/google/callback   # solo usado por el flujo web
FRONTEND_URL=http://localhost:5173
JWT_SECRET=...
JWT_EXPIRES=8h
GOOGLE_ALLOW_DIFFERENT_EMAILS=false
```

El **Android Client ID** (con package name + SHA-1/SHA-256) se crea también en Google Cloud Console, pero **no se usa en ninguna variable de entorno del backend** — Google lo valida directamente contra la firma del APK.

---

## 5. Tabla de estados HTTP usados

| Código | Significado en esta API |
|---|---|
| 200 | Éxito |
| 400 | Datos faltantes o error devuelto por Google/lógica de negocio |
| 401 | Sesión ausente, inválida, o `idToken` no verificado |
| 403 | Cuenta inactiva o rol sin permiso |
| 404 | Usuario/orden no encontrado |
| 500 | Error interno no controlado |
