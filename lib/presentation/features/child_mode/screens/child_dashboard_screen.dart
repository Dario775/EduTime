import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/monitor_bloc.dart';

/// ChildDashboardScreen - Main dashboard for child users
/// 
/// Shows time balance, quick actions, and current status.
class ChildDashboardScreen extends StatelessWidget {
  const ChildDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MonitorBloc, MonitorState>(
      builder: (context, state) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
                stops: const [0.0, 0.3],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(context, state),
                  
                  // Main Content
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppSpacing.radiusXl),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppSpacing.radiusXl),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Balance Card
                              _buildBalanceCard(context, state),
                              
                              const SizedBox(height: AppSpacing.xl),
                              
                              // Quick Actions
                              Text(
                                'Acciones Rápidas',
                                style: AppTypography.titleLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              
                              const SizedBox(height: AppSpacing.md),
                              
                              _buildQuickActions(context),
                              
                              const SizedBox(height: AppSpacing.xl),
                              
                              // Today's Stats
                              Text(
                                'Hoy',
                                style: AppTypography.titleLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              
                              const SizedBox(height: AppSpacing.md),
                              
                              _buildTodayStats(context),
                              
                              const SizedBox(height: AppSpacing.xl),
                              
                              // Status Card
                              if (state is MonitorActive)
                                _buildStatusCard(context, state),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildHeader(BuildContext context, MonitorState state) {
    String greeting = _getGreeting();
    
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Estudiante', // TODO: Get from user data
                  style: AppTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Profile Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBalanceCard(BuildContext context, MonitorState state) {
    int balanceSeconds = 0;
    bool isLow = false;
    bool isCritical = false;
    
    if (state is MonitorActive) {
      balanceSeconds = state.currentBalance;
      isLow = state.isBalanceLow;
      isCritical = state.isBalanceCritical;
    }
    
    final hours = balanceSeconds ~/ 3600;
    final minutes = (balanceSeconds % 3600) ~/ 60;
    
    Color cardColor = AppColors.success;
    if (isCritical) {
      cardColor = AppColors.error;
    } else if (isLow) {
      cardColor = AppColors.warning;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor,
            cardColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCritical
                    ? Icons.timer_off_rounded
                    : Icons.timer_rounded,
                color: Colors.white.withOpacity(0.8),
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Tiempo Disponible',
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$hours',
                style: AppTypography.displayLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'h ',
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
              Text(
                '$minutes',
                style: AppTypography.displayLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'm',
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
          if (isCritical) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              '¡Estudia para ganar más tiempo!',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.school_rounded,
            title: 'Estudiar',
            color: AppColors.primary,
            onTap: () {
              // Navigate to study session
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.history_rounded,
            title: 'Historial',
            color: AppColors.secondary,
            onTap: () {
              // Navigate to history
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.emoji_events_rounded,
            title: 'Logros',
            color: AppColors.warning,
            onTap: () {
              // Navigate to achievements
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildTodayStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.access_time_rounded,
            value: '2h 30m',
            label: 'Estudiado',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            value: '7',
            label: 'Días seguidos',
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatusCard(BuildContext context, MonitorActive state) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: state.isBlockingEnabled
            ? AppColors.success.withOpacity(0.1)
            : AppColors.textSecondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: state.isBlockingEnabled
              ? AppColors.success.withOpacity(0.3)
              : AppColors.textSecondary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            state.isBlockingEnabled
                ? Icons.shield_rounded
                : Icons.shield_outlined,
            color: state.isBlockingEnabled
                ? AppColors.success
                : AppColors.textSecondary,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.isBlockingEnabled
                      ? 'Protección Activa'
                      : 'Protección Pausada',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  state.isBlockingEnabled
                      ? 'Las apps se bloquearán cuando no tengas tiempo'
                      : 'Las apps no se bloquearán temporalmente',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '¡Buenos días! ☀️';
    } else if (hour < 18) {
      return '¡Buenas tardes! 🌤️';
    } else {
      return '¡Buenas noches! 🌙';
    }
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
