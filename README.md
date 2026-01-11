# EduTime 🎓⏱️

**App de gestión de tiempo educativo para niños con control parental**

Transforma el tiempo de estudio en tiempo de ocio. Los niños ganan minutos de apps/juegos por cada minuto que estudian.

## 🚀 Instalación en tu Celular (Sin Flutter)

### Opción 1: GitHub Actions (Recomendado)

1. **Sube el proyecto a GitHub**
   ```bash
   git add .
   git commit -m "Initial commit"
   git push origin main
   ```

2. **Ve a la pestaña Actions** en tu repositorio de GitHub

3. **Ejecuta el workflow** "Build Android APK"

4. **Descarga el APK** desde los artifacts cuando termine

5. **Instala en tu celular**:
   - Habilita "Instalar apps de origen desconocido"
   - Abre el APK descargado

### Opción 2: Zapp.run (En el navegador)

1. Ve a https://zapp.run
2. Crea un nuevo proyecto
3. Copia el código de `lib/main.dart`
4. Ejecuta en el navegador

## 📱 Funcionalidades

- ⏰ **Timer de estudio** - Pomodoro y modo libre
- 💰 **Sistema de créditos** - Gana tiempo por estudiar
- 🔒 **Control parental** - Bloqueo de apps
- 👨‍👩‍👧 **Modo familia** - Padres e hijos
- 📊 **Estadísticas** - Seguimiento de progreso
- 🔥 **Rachas** - Motivación por días consecutivos

## 🛠️ Para Desarrolladores

### Requisitos
- Flutter 3.6.0+
- Node.js 18+ (para Cloud Functions)
- Android Studio (opcional)

### Instalación Local
```bash
# Instalar dependencias
flutter pub get

# Generar código
dart run build_runner build

# Ejecutar
flutter run
```

### Estructura del Proyecto
```
lib/
├── core/           # Configuración, DI, Theme
├── data/           # Datasources, Schemas
├── domain/         # Entities, Usecases
└── presentation/   # UI, BLoCs, Pages
```

## 📄 Licencia

MIT License

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! Abre un Issue o Pull Request.
