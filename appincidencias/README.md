# 📣 Tu Voz Cuenta

**Tu Voz Cuenta** es una plataforma tecnológica multiplataforma (Web y Móvil) diseñada para la gestión integral de incidencias en la vía pública. Permite una comunicación directa y transparente entre los ciudadanos, los técnicos municipales y la administración local.

## 🚀 Características Principales

-   **Registro Seguro:** Identificación obligatoria mediante DNI/NIE y verificación de correo electrónico.
-   **Reporte Inteligente:** Selección de categorías (Alumbrado, Limpieza, Mobiliario, Vías, etc.) con descripción detallada.
-   **Evidencia Visual:** Captura de fotos optimizadas para documentar las incidencias.
-   **Geolocalización GPS:** Ubicación precisa automática para facilitar la labor de los técnicos.
-   **Gestión por Roles:** Paneles especializados para Ciudadanos, Técnicos y Administradores.
-   **Multiplataforma:** Funcionamiento nativo en Android, iOS y Navegadores Web.

## 🛠️ Tecnologías Utilizadas

-   **Frontend:** Flutter & Dart.
-   **Autenticación:** Firebase Auth (Email/Password & Google Sign-In).
-   **Base de Datos:** Firebase Firestore & MySQL (vía PHP).
-   **Almacenamiento de Imágenes:** Cloudinary API.
-   **Geolocalización:** Geolocator API.

## 📦 Configuración del Proyecto

### Requisitos Previos

-   Flutter SDK (^3.11.4)
-   Dart SDK
-   Cuenta en Firebase Console
-   Credenciales de Cloudinary

### Instalación

1.  Clonar el repositorio:
    ```bash
    git clone https://github.com/Arttoybon/Appinics.git
    ```
2.  Instalar dependencias:
    ```bash
    flutter pub get
    ```
3.  Configurar Firebase para Android/iOS/Web siguiendo la documentación oficial.
4.  Ejecutar la aplicación:
    ```bash
    flutter run
    ```

## 🎨 Iconos y Marca

Para actualizar los iconos de la aplicación en todas las plataformas, se utiliza el paquete `flutter_launcher_icons`. Configura el archivo en `pubspec.yaml` y ejecuta:

```bash
dart run flutter_launcher_icons
```

---
*Este proyecto ha sido desarrollado como una solución de modernización digital para la gestión municipal.*
