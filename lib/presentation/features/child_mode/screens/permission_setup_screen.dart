import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/monitor_bloc.dart';

/// PermissionSetupScreen - Guides users through required permissions
/// 
/// Explains why each permission is needed and guides users to enable them.
class PermissionSetupScreen extends StatefulWidget {
  const PermissionSetupScreen({super.key});

  @override
  State<PermissionSetupScreen> createState() => _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends State<PermissionSetupScreen> {
  bool _accessibilityEnabled = false;
  bool _overlayEnabled = false;
  bool _isChecking = false;
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }
  
  Future<void> _checkPermissions() async {
    setState(() => _isChecking = true);
    
    const channel = MethodChannel('com.edutime.app/monitor');
    
    try {
      final accessibilityResult = await channel.invokeMethod<bool>('checkAccessibilityPermission');
      final overlayResult = await channel.invokeMethod<bool>('checkOverlayPermission');
      
      setState(() {
        _accessibilityEnabled = accessibilityResult ?? false;
        _overlayEnabled = overlayResult ?? false;
        _isChecking = false;
      });
      
      // If all permissions granted, proceed
      if (_accessibilityEnabled && _overlayEnabled) {
        _onAllPermissionsGranted();
      }
    } on PlatformException catch (e) {
      debugPrint('Error checking permissions: $e');
      setState(() => _isChecking = false);
    }
  }
  
  void _onAllPermissionsGranted() {
    // Navigate to next screen or start monitoring
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('¡Permisos configurados correctamente!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allGranted = _accessibilityEnabled && _overlayEnabled;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const Spacer(flex: 1),
                
                // Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    allGranted ? Icons.check_circle_rounded : Icons.security_rounded,
                    size: 50,
                    color: allGranted ? AppColors.success : AppColors.primary,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Title
                Text(
                  allGranted
                      ? '¡Todo Listo!'
                      : 'Configurar Permisos',
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // Subtitle
                Text(
                  allGranted
                      ? 'Los permisos están configurados correctamente'
                      : 'EduTime necesita algunos permisos para funcionar correctamente',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                
                // Permission Cards
                _buildPermissionCard(
                  icon: Icons.accessibility_new_rounded,
                  title: 'Accesibilidad',
                  description: 'Para detectar qué aplicaciones se están usando',
                  isEnabled: _accessibilityEnabled,
                  onTap: _requestAccessibilityPermission,
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                _buildPermissionCard(
                  icon: Icons.layers_rounded,
                  title: 'Superposición',
                  description: 'Para mostrar alertas cuando se agota el tiempo',
                  isEnabled: _overlayEnabled,
                  onTap: _requestOverlayPermission,
                ),
                
                const Spacer(flex: 2),
                
                // Refresh button
                if (_isChecking)
                  const CircularProgressIndicator()
                else
                  TextButton.icon(
                    onPressed: _checkPermissions,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Verificar permisos'),
                  ),
                
                const SizedBox(height: AppSpacing.md),
                
                // Continue button
                if (allGranted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to child mode setup
                        Navigator.of(context).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                      ),
                      child: const Text(
                        'Continuar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: isEnabled ? null : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isEnabled
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  icon,
                  color: isEnabled ? AppColors.success : AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (isEnabled)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    'Activar',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _requestAccessibilityPermission() async {
    HapticFeedback.mediumImpact();
    
    const channel = MethodChannel('com.edutime.app/monitor');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso de Accesibilidad'),
        content: const Text(
          'Se abrirán los ajustes del sistema. Busca "EduTime Monitor" '
          'en la lista y actívalo.\n\n'
          'Este permiso es necesario para detectar qué apps se están usando.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await channel.invokeMethod<void>('requestAccessibilityPermission');
            },
            child: const Text('Abrir Ajustes'),
          ),
        ],
      ),
    );
    
    // Check again after a delay
    await Future.delayed(const Duration(seconds: 1));
    _checkPermissions();
  }
  
  Future<void> _requestOverlayPermission() async {
    HapticFeedback.mediumImpact();
    
    const channel = MethodChannel('com.edutime.app/monitor');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso de Superposición'),
        content: const Text(
          'Se abrirán los ajustes del sistema. Activa el permiso '
          '"Mostrar sobre otras apps" para EduTime.\n\n'
          'Este permiso es necesario para mostrar alertas de bloqueo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await channel.invokeMethod<void>('requestOverlayPermission');
            },
            child: const Text('Abrir Ajustes'),
          ),
        ],
      ),
    );
    
    // Check again after a delay
    await Future.delayed(const Duration(seconds: 1));
    _checkPermissions();
  }
}
