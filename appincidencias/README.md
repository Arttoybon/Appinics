# 🏢 Cantillana Report v2.0

**Cantillana Report** es una plataforma integral de gestión de incidencias municipales desarrollada con Flutter y Firebase. Permite una comunicación directa y eficiente entre los ciudadanos, los operarios técnicos y la administración municipal para mejorar el mantenimiento urbano.

![Versión](https://img.shields.io/badge/version-2.0.0-orange)
![Framework](https://img.shields.io/badge/framework-Flutter-blue)
![Database](https://img.shields.io/badge/database-Firebase-yellow)

---

## ✨ Características Principales

### 📱 Multiplataforma y Responsivo
*   **Web Dashboard:** Interfaz optimizada para monitores de escritorio (hasta 1200px) con visualización en cuadrícula.
*   **Mobile Nativo:** Experiencia fluida en Android e iOS.

### 🔐 Seguridad e Identidad
*   **DNI/NIE Obligatorio:** Validación matemática estricta de la letra de control para garantizar reportes reales.
*   **Middleware de Acceso:** Sistema robusto que verifica el estado del usuario (bloqueado/eliminado) en tiempo real.
*   **Google Auth:** Inicio de sesión rápido y seguro con integración nativa.

### 🎨 Identidad Visual Dinámica (Role-Based)
La aplicación transforma su paleta de colores según el perfil que accede:
*   🟧 **Ciudadano (Naranja):** Orientado a la facilidad de reporte.
*   🟦 **Técnico (Azul):** Orientado a la gestión de tareas de campo.
*   🟩 **Administrador (Verde):** Orientado al control y supervisión municipal.

### 📍 Geolocalización y Multimedia
*   **GPS Inteligente:** Captura de coordenadas exactas para cada incidencia.
*   **Google Maps:** Integración directa para navegación paso a paso hacia el desperfecto.
*   **HD Images:** Procesamiento de imágenes al 90% de calidad y resolución Full HD.

---

## 🛠️ Stack Tecnológico
*   **Frontend:** [Flutter](https://flutter.dev/)
*   **Backend:** [Firebase Auth](https://firebase.google.com/products/auth) & [Firestore (Native Mode)](https://firebase.google.com/products/firestore)
*   **Storage Multimedia:** [Cloudinary](https://cloudinary.com/)
*   **Identidad:** [Google Identity Services](https://developers.google.com/identity)

---

## 🚀 Instalación y Ejecución

### Requisitos Previos
*   Flutter SDK (^3.11.4)
*   Cuenta de Firebase configurada.

### Configuración
1.  Clonar el repositorio:
    ```bash
    git clone https://github.com/tu-usuario/appincidencias.git
    ```
2.  Instalar dependencias:
    ```bash
    flutter pub get
    ```

### Comandos de Ejecución

**Para Web (Recomendado para máxima calidad):**
```bash
flutter run -d chrome --web-renderer html --web-port 5000
```

**Para Móvil:**
```bash
flutter run
```

---

## 👥 Perfiles de Acceso

### 👤 Ciudadano
*   Envío de reportes con fotos y GPS.
*   Seguimiento en tiempo real de sus avisos.
*   Chat directo con técnicos si hay una respuesta oficial.

### 🛠️ Técnico
*   Panel especializado con filtros por especialidad y asignación.
*   Buscador maestro por ID de incidencia.
*   Gestión de estados (Pendiente -> En Proceso -> Resuelta).

### 🏛️ Administrador
*   Gestión total de roles y usuarios.
*   Herramientas de moderación (Bloqueo/Eliminación en cascada).
*   Edición de descripciones y corrección de ubicaciones GPS.

---

## 🧪 Cuentas de Prueba

| Rol | Email | Contraseña |
| :--- | :--- | :--- |
| **Ciudadano** | `ciudadano1@gmail.com` | `123456789` |
| **Técnico** | `tecnico@gmail.com` | `123456789` |
| **Administrador** | `admin@gmail.com` | `123456789` |

---

## 📄 Licencia
Este proyecto es de uso exclusivo para la gestión municipal del Ayuntamiento de Cantillana.

---
*Desarrollado con ❤️ para mejorar la convivencia ciudadana.*
