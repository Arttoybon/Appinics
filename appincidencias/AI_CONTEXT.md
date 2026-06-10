# 🤖 AI CONTEXT & PROJECT OVERVIEW

> **LAST UPDATE:** June 11, 2026 (Today)
> **CURRENT BRANDING:** Tu Voz Cuenta (Formerly: Cantillana Report)

This document is specifically designed to provide context for AI models (LLMs) working on this repository. It summarizes the project's architecture, recent major changes, and technical constraints.

## 📌 Project Identity
- **App Name:** Tu Voz Cuenta
- **Purpose:** Public incident management system for citizens, technicians, and administrators.
- **Main Class:** `TuVozCuentaApp` (in `lib/main.dart`)

## 🏗️ Technical Architecture

### Frontend
- **Framework:** Flutter 3.11.4 (Channel stable)
- **Platforms:** Android, iOS, and Web (HTML Renderer recommended).
- **Icons:** Managed via `flutter_launcher_icons` (Config in `pubspec.yaml`).

### Backend & Storage
- **Primary Database:** Google Firestore (Native Mode). 
    - *Note:* The internal Database ID is `cantillana-native`.
- **Authentication:** Firebase Auth (Email/Password & Google Sign-In).
- **Image Storage:** Cloudinary API.
    - Cloud Name: `dftjjcrtv`
    - Upload Preset: `incidencias_preset`
- **Legacy Support:** `save_incidencia.php` exists for legacy MySQL integration, but the app currently prioritizes Firestore.

## 🛠️ Major Recent Updates (June 11, 2026)
1.  **Rebranding:** Global rename from "Cantillana Report" to "Tu Voz Cuenta".
2.  **UI Redesign:** 
    - Removed text from Login Screen.
    - Optimized logo size and form placement for better UX.
3.  **Assets Update:** New launcher icon and web favicon configured (`assets/images/icono.png`).
4.  **Code Documentation:** Added comprehensive doc-comments to all main screens and services.
5.  **GitHub Prep:** Standardized `README.md` and renamed all documentation files.

## ⚠️ Technical Constraints & Notes
- **Web Favicon:** The `index.html` uses `favicon_nuevo.png` to bypass browser cache.
- **DNI Requirement:** All users (including Google SSO) must provide a DNI/NIE before accessing the main features. This is handled by `DniRequiredScreen`.
- **Role Management:** Handled via the `usuarios` collection in Firestore (`rol` field: 'user', 'tecnico', 'admin').

## 📂 Key File Map
- `lib/main.dart`: Auth flow and role-based routing.
- `lib/services/api_service.dart`: Image uploads and database writes.
- `lib/screens/report_screen.dart`: Main user entry for reporting.
- `lib/screens/admin_panel_screen.dart`: Global management.
- `lib/screens/technician_panel_screen.dart`: Task filtering by specialty.

---
*This file should be kept up to date to ensure seamless transitions between different AI sessions or models.*
