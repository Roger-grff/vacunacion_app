# 🐾 Sistema de Gestión de Campañas de Vacunación Canina y Felina (VacunApp)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Backend-orange.svg?logo=firebase)](https://firebase.google.com)
[![SQLite](https://img.shields.io/badge/SQLite-Local_Cache-blue?logo=sqlite)](https://sqlite.org)
[![OSM](https://img.shields.io/badge/OpenStreetMap-Mapas-green?logo=openstreetmap)](https://www.openstreetmap.org)

## video 

youtube(Roger Grefa): https://www.youtube.com/watch?v=mj1VC06zkCM

Este repositorio contiene la aplicación móvil oficial de **VacunApp**, una solución tecnológica diseñada para la planificación, ejecución y monitoreo de campañas de vacunación antirrábica en sectores urbanos y rurales. 

La aplicación cuenta con una arquitectura de almacenamiento híbrida (Online/Offline) para permitir el trabajo en zonas remotas sin conectividad a internet, sincronizando los datos automáticamente con **Firebase** una vez que se recupera la red.

---

## 📌 Tabla de Contenidos
1. [Descripción General](#-descripción-general)
2. [Arquitectura y Estructura del Código](#-arquitectura-y-estructura-del-código)
3. [Características Principales](#-características-principales)
4. [Estrategia de Sincronización Híbrida](#-estrategia-de-sincronización-híbrida)
5. [Roles y Permisos](#-roles-y-permisos)
6. [Instalación y Configuración](#-instalación-y-configuración)
7. [Tecnologías Utilizadas](#-tecnologías-utilizadas)

---

## 📖 Descripción General

En muchas áreas geográficas, las campañas de vacunación para mascotas se ven limitadas por la falta de infraestructura de red. **VacunApp** resuelve este problema implementando un modelo **Offline-First**. 

Los vacunadores pueden capturar fotos del animal, obtener las coordenadas de ubicación por GPS de alta precisión mediante mapas libres (**OpenStreetMap**), y rellenar el formulario de vacunación. Si no hay señal de internet, toda la información (incluida la imagen en disco local) se resguarda en una base de datos local SQLite y se sube automáticamente en segundo plano cuando la señal se restablece.

---

## 🏗️ Arquitectura y Estructura del Código

El proyecto está estructurado bajo el patrón de arquitectura **MVC/MVVM** utilizando **Provider** para la gestión de estados y desacoplando los servicios de Firebase y SQLite de la interfaz de usuario:

```text
lib/
├── firebase_options.dart      # Credenciales autogeneradas de Firebase
├── main.dart                  # Inicializador de la aplicación, Providers y rutas
├── models/                    # Estructuras de datos (Modelos)
│   ├── sector_modelo.dart     # Definición de sectores geográficos
│   ├── usuario_modelo.dart    # Datos y roles del personal de campaña
│   └── vacunacion_modelo.dart # Formularios y registros de dosis aplicadas
├── providers/                 # Gestores de Estado (Providers)
│   ├── autenticacion_proveedor.dart # Sesión, estados de login y cambio de contraseña
│   ├── sector_proveedor.dart        # Administración de zonas y asignación de personal
│   └── vacunacion_proveedor.dart    # Registro de dosis, GPS y control de sincronización
├── services/                  # Capa de Servicios externos e infraestructura
│   ├── autenticacion_servicio.dart  # Conexión directa a Firebase Auth
│   ├── base_datos_local_servicio.dart # Gestor de SQLite local offline
│   ├── datos_prueba_servicio.dart   # Sembrador de base de datos demo (Dummy Data)
│   ├── firestore_servicio.dart      # Transacciones y CRUD en Cloud Firestore
│   └── storage_servicio.dart        # Subida de imágenes a Firebase Storage
└── views/                     # Interfaz de Usuario (Vistas)
    ├── auth/                  # Inicio de sesión y flujos de claves temporales
    │   ├── cambiar_contrasena_vista.dart
    │   ├── login_vista.dart
    │   └── recuperar_contrasena_vista.dart
    ├── dashboard/             # Dashboard analítico con gráficos
    │   └── dashboard_vista.dart
    ├── sectors/               # CRUD de Sectores geográficos
    │   └── gestionar_sectores_vista.dart
    ├── shared/                # Widgets compartidos (Drawer y Navegación principal)
    │   ├── menu_lateral.dart
    │   └── pantalla_navegacion_principal.dart
    ├── users/                 # Administración de cuentas y roles de usuario
    │   └── gestionar_usuarios_vista.dart
    └── vaccinations/          # Registro de vacunas, cámara y mapas
        ├── lista_vacunacion_vista.dart
        ├── registrar_vacunacion_vista.dart
        └── selector_mapa_vista.dart
```

---

## ✨ Características Principales

*   **🛡️ Autenticación y Flujo Seguro**: 
    *   No hay autoregistro de usuarios.
    *   Las cuentas de Brigadistas y Vacunadores son creadas exclusivamente por los coordinadores.
    *   Generación automática de contraseñas aleatorias seguras con prefijo `"VTE"`.
    *   Obligatoriedad de **cambio de contraseña en el primer inicio de sesión**.
*   **📡 Sincronización Inteligente en Segundo Plano**:
    *   Monitoreo continuo de red mediante `connectivity_plus`.
    *   Subida diferida y automática de registros y archivos binarios (fotos de mascotas).
    *   Barra de estado de sincronización visual en el Dashboard.
*   **🗺️ Geolocalización Abierta e Independiente**:
    *   Integración de mapas interactivos de **OpenStreetMap** mediante la librería `flutter_map` y `latlong2`.
    *   **Cero dependencias de APIs pagas** o privativas como Google Maps.
    *   Extracción y visualización de coordenadas GPS automáticas o por pin manual en el mapa.
*   **📊 Dashboard Estadístico**:
    *   Gráficos circulares interactivos con el balance de caninos vs felinos inmunizados.
    *   Visualización sectorizada de metas cumplidas y estadísticas globales del personal de vacunación.
*   **📸 Acceso Directo a Cámara**:
    *   Captura rápida del comprobante de vacunación o foto de la mascota a través de `image_picker`.

---

## 👥 Roles y Permisos

La aplicación define niveles de acceso estrictos basados en el rol del usuario asignado:

| Funcionalidad | Coordinador de Campaña | Coordinador de Brigada | Vacunador |
|---|:---:|:---:|:---:|
| Ver Dashboard General | Si | Si | No (Solo su sector) |
| Crear y Eliminar Sectores | Si | No | No |
| Crear y Administrar Brigadistas | Si | No | No |
| Crear y Administrar Vacunadores | Si | Si | No |
| Editar/Eliminar registros de dosis | Si | Si | No (Solo lectura posterior) |
| Registrar Vacunaciones (Formulario) | Si | Si | Si |

---

## 🚀 Instalación y Configuración

Sigue estos pasos para compilar y ejecutar el proyecto en tu entorno local:

### 1. Requisitos Previos
*   **Flutter SDK**: `>=3.12.1` ([Instrucciones de instalación](https://docs.flutter.dev/get-started/install))
*   **Node.js** (opcional, para inicializar Firebase CLI)
*   Dispositivo móvil o emulador (Android o iOS)

### 2. Clonar y obtener dependencias
```bash
git clone https://github.com/tu-usuario/vacunacion_app.git
cd vacunacion_app
flutter pub get
```

### 3. Configuración de Firebase
El proyecto utiliza Firebase Auth, Firestore y Storage. Para enlazar tu propia consola de Firebase al código del cliente:
1. Instala el CLI de Firebase:
   ```bash
   npm install -g firebase-tools
   ```
2. Logueate con tu cuenta de Google:
   ```bash
   firebase login
   ```
3. Activa la CLI de FlutterFire:
   ```bash
   dart pub global activate flutterfire_cli
   ```
4. Corre la configuración desde la raíz del proyecto para crear automáticamente las opciones de enlace:
   ```bash
   flutterfire configure
   ```
   *Sigue las instrucciones en pantalla para vincular tu app a tu proyecto de Firebase. Esto generará el archivo `lib/firebase_options.dart`.*

### 4. Ejecución del Proyecto
Para correr la aplicación en modo desarrollo en tu dispositivo conectado:
```bash
flutter run
```

### 🧪 Sembrado de Datos de Prueba (Demo)
Si deseas agilizar el testing de los roles y flujos, en la parte inferior de la pantalla de **Iniciar Sesión** se encuentra disponible el botón **"Cargar Base de Datos Demo"**. 
Al pulsarlo, se creará de forma automatizada la siguiente estructura de prueba en tu Firebase en pocos segundos:
*   **Sectores**: *Sector Norte*, *Sector Centro*, *Sector Sur*.
*   **Cuentas de prueba** (Contraseña para todas: `password123`):
    *   **Coordinador de Campaña**: `campana@test.com`
    *   **Coordinador de Brigada**: `brigada@test.com` (Asignado al Sector Norte)
    *   **Vacunador**: `vacunador@test.com` (Asignado al Sector Norte)

---

## 🛠️ Tecnologías Utilizadas

*   **Framework principal**: [Flutter](https://flutter.dev/) con lenguaje [Dart](https://dart.dev/).
*   **Base de Datos Relacional Local**: [SQLite](https://sqlite.org/) a través de [sqflite](https://pub.dev/packages/sqflite) y [path_provider](https://pub.dev/packages/path_provider).
*   **Base de Datos en la Nube y Almacenamiento**: [Cloud Firestore](https://firebase.google.com/docs/firestore), [Firebase Auth](https://firebase.google.com/docs/auth) y [Firebase Storage](https://firebase.google.com/docs/storage).
*   **Geolocalización**: [flutter_map](https://pub.dev/packages/flutter_map) + [latlong2](https://pub.dev/packages/latlong2) + [geolocator](https://pub.dev/packages/geolocator) para ubicación libre.
*   **Detección de Red**: [connectivity_plus](https://pub.dev/packages/connectivity_plus).
*   **Imágenes**: [image_picker](https://pub.dev/packages/image_picker).
