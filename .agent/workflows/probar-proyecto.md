---
description: Cómo iniciar y probar el proyecto EduTime
---

# Workflow: Probar EduTime

## Pre-requisitos

1. Flutter SDK instalado (versión 3.6.0 o superior)
2. Android Studio o VS Code con extensión Flutter
3. Un emulador Android o dispositivo físico conectado
4. Node.js 18+ (para Cloud Functions)

## Paso 1: Instalar Dependencias Flutter

```bash
cd c:\Users\Dario\Documents\GitHub\EduTime
flutter pub get
```

## Paso 2: Generar Código (Isar schemas)

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Paso 3: Crear Carpetas de Assets Faltantes

```bash
mkdir -p assets/images assets/icons assets/animations assets/fonts
```

## Paso 4: Descargar Fuentes Poppins

Descarga las fuentes Poppins de Google Fonts:
- https://fonts.google.com/specimen/Poppins
- Coloca los archivos .ttf en `assets/fonts/`

O comenta las fuentes en pubspec.yaml para usar la fuente predeterminada.

## Paso 5: Verificar Dispositivos

```bash
flutter devices
```

Asegúrate de tener al menos un dispositivo o emulador disponible.

## Paso 6: Ejecutar la App

// turbo
```bash
flutter run
```

O para modo debug con hot reload:

```bash
flutter run --debug
```

## Paso 7: Ejecutar Tests Unitarios

// turbo
```bash
flutter test test/domain/usecases/calculate_credit_test.dart
```

## Paso 8: Probar Cloud Functions (Opcional)

```bash
cd functions
npm install
npm run serve
```

Esto inicia el emulador de Firebase Functions en localhost.

## Solución de Problemas Comunes

### Error: Fuentes no encontradas
Comenta la sección `fonts:` en pubspec.yaml temporalmente.

### Error: Firebase no configurado
El proyecto puede ejecutarse sin Firebase en modo offline/demo.

### Error: Isar no genera
Ejecuta `dart run build_runner clean` y luego el build nuevamente.

### Error: Android SDK
Ejecuta `flutter doctor` para verificar la configuración.
