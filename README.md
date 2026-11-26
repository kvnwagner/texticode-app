# Texticode Mobile - Google Login y Google Calendar

Esta app Flutter ya tiene conectado el flujo móvil para:

- iniciar sesión con Google usando el mismo usuario, correo y rol que maneja el backend de Texticode;
- vincular una cuenta de Google Calendar desde el perfil;
- sincronizar todas las órdenes visibles para el usuario autenticado.

Importante: en este repositorio el backend no está incluido, solo existe `backend/package-lock.json`. La app móvil llama las rutas documentadas abajo. Si esas rutas no existen en tu backend Express real, la app compila pero Google/Calendar fallará con errores de conexión o 404.

## Archivos modificados

- `lib/features/auth/presentation/screens/login_screen.dart`: activa `Continuar con Google` y navega por rol.
- `lib/features/auth/data/repositories/google_auth_repository.dart`: obtiene tokens de Google y `serverAuthCode`.
- `lib/features/admin/data/repositories/calendar_repository.dart`: consume las rutas de Calendar.
- `lib/features/admin/presentation/screens/perfil_screen.dart`: vincula y sincroniza Calendar para admin.
- `lib/features/operario/presentation/screens/perfil_screen.dart`: vincula y sincroniza Calendar para operario.
- `lib/features/cliente/presentation/screens/cliente_perfil_screen.dart`: vincula y sincroniza Calendar para cliente.
- `lib/core/constants/api_constants.dart`: lee `GOOGLE_WEB_CLIENT_ID` por `--dart-define`.
- `android/app/src/main/AndroidManifest.xml`: agrega permiso de internet en release.

## Configuración en Google Console

1. Abrir Google Cloud Console.
2. Crear o seleccionar el proyecto usado por la versión web.
3. Activar `Google Calendar API`.
4. Configurar OAuth consent screen.
5. Agregar estos scopes:
   - `openid`
   - `email`
   - `profile`
   - `https://www.googleapis.com/auth/calendar.events`
6. Crear un OAuth Client ID tipo `Web application`.
   - Este es el valor que se pasa como `GOOGLE_WEB_CLIENT_ID`.
   - Debe ser el mismo que usa el backend para verificar tokens e intercambiar `serverAuthCode`.
7. Crear un OAuth Client ID tipo `Android`.
   - Package name: `com.texticode_app.texticode_app`
   - SHA-1: huella del keystore debug o release.
   - SHA-256: recomendado también.

Para obtener SHA-1/SHA-256:

```powershell
cd android
.\gradlew signingReport
```

## Ejecutar la app

Verifica primero la IP del backend:

```dart
// lib/core/constants/api_constants.dart
static const String baseUrl = 'http://192.168.0.6:3001/api';
```

Ejecuta Flutter pasando el Web Client ID:

```bash
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=TU_WEB_CLIENT_ID.apps.googleusercontent.com
```

Si no pasas ese valor, la app mostrará:

```text
Falta configurar GOOGLE_WEB_CLIENT_ID.
```

## Login con Google

Ruta móvil usada por la app:

```http
POST /api/auth/google/mobile
Content-Type: application/json
```

Body:

```json
{
  "idToken": "GOOGLE_ID_TOKEN",
  "accessToken": "GOOGLE_ACCESS_TOKEN",
  "serverAuthCode": "GOOGLE_SERVER_AUTH_CODE"
}
```

El backend debe:

- verificar `idToken` con Google usando `GOOGLE_WEB_CLIENT_ID`;
- buscar el usuario por `Correo`;
- devolver el mismo `Id_Usuario`, `Id_Rol`, `Rol` y `Estado` que devuelve el login web;
- crear o rechazar usuarios nuevos según la regla actual de la versión web;
- intercambiar `serverAuthCode` por tokens de Google y guardar el `refresh_token`;
- responder con el mismo formato de `POST /api/auth/login`.

Respuesta correcta:

```json
{
  "token": "JWT_DE_TEXTICODE",
  "usuario": {
    "Id_Usuario": 1,
    "Nombre_Completo": "Nombre Apellido",
    "Nombre_Usuario": "admin",
    "Correo": "usuario@empresa.com",
    "Id_Rol": 1,
    "Rol": "Administrador",
    "Estado": "activo"
  }
}
```

Errores sugeridos:

```json
{ "error": "Token de Google inválido." }
```

```json
{ "error": "No existe un usuario activo con este correo." }
```

```json
{ "error": "No se pudo vincular Google Calendar." }
```

## Rutas de Google Calendar

Todas las rutas usan el JWT de Texticode:

```http
Authorization: Bearer JWT_DE_TEXTICODE
Content-Type: application/json
```

### Consultar estado

```http
GET /api/calendar/status
```

Respuesta:

```json
{
  "connected": true,
  "calendarEmail": "usuario@gmail.com"
}
```

Si no está vinculado:

```json
{
  "connected": false,
  "calendarEmail": null
}
```

### Vincular Calendar

```http
POST /api/calendar/connect
```

Body:

```json
{
  "serverAuthCode": "GOOGLE_SERVER_AUTH_CODE"
}
```

Respuesta:

```json
{
  "connected": true,
  "calendarEmail": "usuario@gmail.com"
}
```

El backend debe intercambiar `serverAuthCode` por tokens de Google y guardar el `refresh_token` asociado al `Id_Usuario` autenticado.

### Desvincular Calendar

```http
DELETE /api/calendar/connect
```

Respuesta:

```json
{
  "connected": false
}
```

### Sincronizar todas las órdenes

```http
POST /api/calendar/sync
```

Body: vacío.

Respuesta:

```json
{
  "total": 8,
  "creados": 3,
  "actualizados": 5
}
```

Regla recomendada:

- Administrador: sincroniza todas las órdenes.
- Operario: sincroniza solo órdenes asignadas al operario autenticado.
- Cliente: sincroniza solo órdenes del cliente autenticado.

Cada orden debería crear o actualizar un evento en Google Calendar usando su fecha límite.

### Sincronizar una orden

```http
POST /api/calendar/sync/:idOrden
```

Parámetro:

| Parámetro | Tipo | Descripción |
| --- | --- | --- |
| `idOrden` | number | ID de la orden de producción. |

Respuesta:

```json
{
  "synced": true,
  "idOrden": 15,
  "eventId": "google_calendar_event_id"
}
```

## Datos mínimos de una orden para Calendar

```json
{
  "Id_Orden": 15,
  "Codigo_Orden": "ORD-0015",
  "Producto": "Camisas",
  "Descripcion": "Producción lote agosto",
  "Estado": "En proceso",
  "Prioridad": "Alta",
  "Fecha_Limite": "2026-09-15",
  "Cantidad_Total": 120,
  "Cantidad_Actual": 40,
  "Id_Cliente": 3,
  "Id_Operario": 7
}
```

Evento sugerido:

```json
{
  "summary": "Texticode ORD-0015 - Camisas",
  "description": "Estado: En proceso\nPrioridad: Alta\nProgreso: 40/120\nProducción lote agosto",
  "start": { "date": "2026-09-15" },
  "end": { "date": "2026-09-16" }
}
```

Para evitar duplicados, guarda en tu base de datos el `eventId` de Google por orden y usuario, por ejemplo en una tabla `google_calendar_events`.

## Variables de entorno sugeridas para el backend

```env
GOOGLE_WEB_CLIENT_ID=xxxxx.apps.googleusercontent.com
GOOGLE_WEB_CLIENT_SECRET=xxxxx
JWT_SECRET=xxxxx
FRONTEND_URL=http://localhost:5173
```

## Diagnóstico rápido

Si falla el login con Google:

- confirma que ejecutaste con `--dart-define=GOOGLE_WEB_CLIENT_ID=...`;
- confirma que existe el OAuth Client tipo Android con package `com.texticode_app.texticode_app`;
- confirma que SHA-1/SHA-256 corresponden al keystore usado;
- confirma que `/api/auth/google/mobile` existe en el backend;
- confirma que el usuario existe en Texticode con el mismo correo de Google.

Si falla Calendar:

- confirma que Google Calendar API está habilitada;
- confirma que el scope `https://www.googleapis.com/auth/calendar.events` está aprobado;
- confirma que `/api/calendar/connect` guarda el `refresh_token`;
- confirma que `/api/calendar/sync` filtra órdenes según `Id_Rol`/`Id_Usuario`;
- revisa que las órdenes tengan `Fecha_Limite`.
