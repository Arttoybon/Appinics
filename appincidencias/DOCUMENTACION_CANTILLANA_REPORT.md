# 📚 DOCUMENTACIÓN MAESTRA: CANTILLANA REPORT v2.0

## 📝 1. RESUMEN DEL PROYECTO
**Cantillana Report** es una plataforma tecnológica de vanguardia diseñada para la gestión integral de incidencias en la vía pública. La versión 2.0 ha sido optimizada para ofrecer un rendimiento superior en entornos web y móviles, garantizando la seguridad mediante la validación de identidad (DNI) y la eficiencia operativa mediante paneles especializados por roles.

---

## 👤 2. MANUAL DEL CIUDADANO (USUARIO FINAL)
*Color de la interfaz: **Naranja***

### 2.1. Registro e Identificación
*   **DNI/NIE Obligatorio:** Por seguridad y rigor administrativo, todos los usuarios deben registrar su DNI. Si accede mediante Google, se activará una pantalla obligatoria para completar este dato antes de permitir cualquier reporte.
*   **Verificación de Email:** Los registros manuales requieren confirmar un enlace enviado al correo para activar las funciones de la cuenta.

### 2.2. Flujo de Reporte de Incidencias
1.  **Categorización:** Selección de la naturaleza del problema (Alumbrado, Limpieza, Mobiliario, Vías u Otros).
2.  **Descripción Detallada:** Campo de texto libre para aportar contexto.
3.  **Evidencia Visual:** Captura de fotos procesadas al **90% de calidad** y resolución **Full HD (1920x1080)** para un equilibrio perfecto entre nitidez y velocidad de subida.
4.  **Localización GPS:** Botón **"ACTIVAR GPS"** interactivo. Es obligatorio pulsarlo para conceder el permiso al navegador y obtener la coordenada exacta.

### 2.3. Consulta y Multimedia
*   **Historial:** Acceso a "Mis Incidencias" con estados actualizados en tiempo real.
*   **Vista Previa:** Las imágenes pueden tocarse para abrirse a **Pantalla Completa** con soporte para zoom táctil o de ratón.

---

## 🛠️ 3. MANUAL DEL TÉCNICO (OPERARIOS)
*Color de la interfaz: **Azul***

### 3.1. Dashboard de Trabajo
*   **Acceso Directo:** El sistema redirige automáticamente al técnico a su panel de gestión nada más entrar.
*   **Filtros Inteligentes:** Por defecto, el panel prioriza las incidencias **"Pendientes"** y **"Asignadas a mí"**.

### 3.2. Herramientas de Gestión
*   **Buscador Maestro:** Permite buscar por **ID (#XXXXX)** o palabras clave. Al escribir, los filtros de estado se suspenden para una localización global rápida.
*   **Navegación GPS:** Botón **"ABRIR EN GOOGLE MAPS"** para guiar al operario mediante navegación paso a paso hasta el desperfecto.
*   **Estados:** El técnico es responsable de mover la incidencia a **"En proceso"** y finalmente a **"Resuelta"**.

---

## 🏛️ 4. MANUAL DEL ADMINISTRADOR (GESTIÓN MUNICIPAL)
*Color de la interfaz: **Verde***

### 4.1. Panel Administrativo Web
*   **Diseño Dashboard:** Interfaz optimizada para monitores de escritorio con un ancho de **1200px** y visualización en cuadrículas (Grid) de múltiples columnas.

### 4.2. Moderación y Control de Usuarios
*   **Gestión de Roles:** Capacidad de asignar especialidades técnicas a cualquier usuario registrado.
*   **Bloqueo de Seguridad:** Botón para impedir el acceso inmediato a usuarios conflictivos.
*   **Eliminación en Cascada:** Al borrar un usuario, el sistema elimina **automáticamente todas sus incidencias, fotos y comentarios** de la base de datos, garantizando una limpieza total.

### 4.3. Supervisión de Datos
*   **Edición de Reportes:** Icono del **lápiz azul** para corregir descripciones o ajustar coordenadas GPS erróneas enviadas por los ciudadanos.

---

## 💻 5. ESPECIFICACIONES TÉCNICAS (SISTEMAS)

### 5.1. Arquitectura de Software
*   **Framework:** Flutter 3.x (Multiplataforma Nativa).
*   **Base de Datos:** Google Firestore en **Modo Nativo** (ID: `cantillana-native`).
*   **Backend de Imágenes:** Cloudinary API (Bucket: `dftjjcrtv`).
*   **Seguridad:** Firebase Auth con Middleware `AuthWrapper` para control de acceso en tiempo real.

### 5.2. Optimización de Rendimiento
*   **Renderizado Web:** Uso del motor **HTML Renderer** para máxima nitidez de texto y escalado de imágenes sin pixelación.
*   **Manejo de Imágenes:** Redimensionamiento automático a **1920x1080px** con filtro `FilterQuality.medium`.
*   **Geolocalización:** Precisión ajustada a `medium` en Web para evitar bloqueos por falta de hardware GPS en PCs de escritorio.

---

## 🛠️ 6. GUÍA DE RESOLUCIÓN DE PROBLEMAS (TROUBLESHOOTING)

### 6.1. Errores de Acceso y Login
| Síntoma | Causa | Solución |
| :--- | :--- | :--- |
| Error `unknown_reason` (Web) | Puerto de ejecución no autorizado. | Ejecutar siempre en el puerto 5000: `--web-port 5000`. |
| Error `DEVELOPER_ERROR` (Android) | Firma SHA-1 no registrada. | Generar SHA-1 con `gradlew signingReport` y añadirlo a la consola de Firebase. |
| La pantalla de bloqueo parpadea | Bucle de cierre de sesión. | Pulsa el botón "Volver al Login" para resetear la sesión de Google y Firebase. |

### 6.2. Errores de Funcionalidad
| Síntoma | Causa | Solución |
| :--- | :--- | :--- |
| El GPS no detecta ubicación | Falta de interacción manual. | **Obligatorio:** El usuario debe pulsar el botón "ACTIVAR GPS" para que el navegador muestre el aviso de permisos. |
| Imágenes borrosas o pixeladas | Motor gráfico incorrecto. | Compilar siempre con el comando: `flutter build web --web-renderer html`. |
| No aparece el botón de Google Maps | Coordenadas nulas. | El sistema mostrará: "Esta incidencia no tiene ubicación guardada". |

---

## 🚀 7. MANTENIMIENTO Y ESCALABILIDAD

El sistema ha sido diseñado para ser fácilmente ampliable mediante las siguientes acciones técnicas:

### 7.1. Añadir Nuevas Categorías de Incidencia
Para añadir un nuevo departamento (ej: "Parques" o "Electricidad"):
1.  Localice el archivo `lib/screens/report_screen.dart`.
2.  Busque la lista `_categorias`.
3.  Añada un nuevo objeto con el nombre y el icono deseado:
    ```dart
    {'nombre': 'Parques', 'icon': Icons.park}
    ```

### 7.2. Cambio de Servidor de Imágenes
Si desea cambiar la cuenta de almacenamiento de fotos en Cloudinary:
1.  Abra el archivo `lib/services/api_service.dart`.
2.  Actualice las variables `_cloudinaryUrl` y `_uploadPreset` con las nuevas credenciales del bucket.

### 7.3. Autorizar Nuevos Dominios o Entornos
Cuando la aplicación se mueva a un dominio de producción (ej: `www.ayuntamiento.es`):
1.  **Google Cloud Console:** Vaya a la sección de Credenciales de OAuth 2.0 y añada la nueva URL en **"Orígenes de JavaScript autorizados"**.
2.  **Firebase Console:** En el apartado Authentication > Settings, añada el dominio en la lista de **"Authorized Domains"**.

---
*Documento Final de Especificaciones - Revisión 2.0 - Mayo 2026*

## 👥 8. CUENTAS DE PRUEBA (TESTING)

Para verificar el funcionamiento de los distintos roles y permisos, se pueden utilizar las siguientes credenciales preconfiguradas:

| Perfil | Email | Contraseña |
| :--- | :--- | :--- |
| **Ciudadano** | `ciudadano1@gmail.com` | `123456789` |
| **Técnico** | `tecnico@gmail.com` | `123456789` |
| **Administrador** | `admin@gmail.com` | `123456789` |
