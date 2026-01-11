import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

/// OverlayScreen - Displayed when a blocked app is detected
/// 
/// This screen is shown as a system overlay (SYSTEM_ALERT_WINDOW)
/// to block access to restricted apps when the child has no time balance.
class OverlayScreen extends StatefulWidget {
  final String blockedAppName;
  final int remainingSeconds;
  final VoidCallback? onDismiss;
  final VoidCallback? onStudyPressed;
  
  const OverlayScreen({
    super.key,
    required this.blockedAppName,
    this.remainingSeconds = 0,
    this.onDismiss,
    this.onStudyPressed,
  });

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    }
    return '${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.85),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Lock Icon with Animation
                    _buildLockIcon(),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Title
                    Text(
                      '¡Tiempo Agotado!',
                      style: AppTypography.headlineLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    // Subtitle
                    Text(
                      'No tienes tiempo libre disponible',
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Blocked App Card
                    _buildBlockedAppCard(),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Remaining Time (if any)
                    if (widget.remainingSeconds > 0) ...[
                      _buildRemainingTimeCard(),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    
                    // Study Button
                    _buildStudyButton(),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    // Info Text
                    Text(
                      'Estudia para ganar más tiempo libre',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLockIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.error.withOpacity(0.3),
            AppColors.error.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: AppColors.error.withOpacity(0.5),
          width: 3,
        ),
      ),
      child: const Icon(
        Icons.lock_outline_rounded,
        size: 60,
        color: AppColors.error,
      ),
    );
  }
  
  Widget _buildBlockedAppCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(
              Icons.block_rounded,
              color: AppColors.error,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'App bloqueada',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white54,
                  ),
                ),
                Text(
                  widget.blockedAppName,
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRemainingTimeCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.warning.withOpacity(0.3),
            AppColors.warning.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Tiempo restante',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _formatTime(widget.remainingSeconds),
            style: AppTypography.displayMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStudyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.mediumImpact();
          widget.onStudyPressed?.call();
        },
        icon: const Icon(Icons.school_rounded),
        label: const Text('¡Empezar a Estudiar!'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          elevation: 8,
          shadowColor: AppColors.primary.withOpacity(0.4),
        ),
      ),
    );
  }
}

/// Compact overlay widget for inline display
class CompactOverlayBanner extends StatelessWidget {
  final String appName;
  final int remainingSeconds;
  final VoidCallback? onStudyPressed;
  
  const CompactOverlayBanner({
    super.key,
    required this.appName,
    required this.remainingSeconds,
    this.onStudyPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.timer_off_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sin tiempo para $appName',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '¡Estudia para ganar más!',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onStudyPressed,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            child: const Text('Estudiar'),
          ),
        ],
      ),
    );
  }
}
