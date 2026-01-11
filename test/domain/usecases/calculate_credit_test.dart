import 'package:flutter_test/flutter_test.dart';

/// Unit tests for credit/time calculation logic
/// 
/// Tests the core business logic for:
/// - Study time to leisure time conversion
/// - Streak bonus calculations
/// - Subject-specific ratios
/// - Maximum limits and edge cases

void main() {
  group('CreditCalculator', () {
    late CreditCalculator calculator;
    
    setUp(() {
      calculator = CreditCalculator();
    });
    
    group('Basic Credit Calculation', () {
      test('should calculate credits with 1:1 ratio', () {
        final result = calculator.calculateCredits(
          studyDurationSeconds: 3600, // 1 hour
          globalRatio: 1.0,
        );
        
        expect(result.earnedSeconds, 3600);
        expect(result.bonusSeconds, 0);
        expect(result.totalSeconds, 3600);
      });
      
      test('should calculate credits with 2:1 ratio', () {
        final result = calculator.calculateCredits(
          studyDurationSeconds: 3600, // 1 hour study
          globalRatio: 2.0, // 2:1 ratio
        );
        
        // 1 hour study = 2 hours leisure
        expect(result.earnedSeconds, 7200);
      });
      
      test('should calculate credits with 0.5:1 ratio', () {
        final result = calculator.calculateCredits(
          studyDurationSeconds: 3600, // 1 hour study
          globalRatio: 0.5, // 0.5:1 ratio
        );
        
        // 1 hour study = 30 min leisure
        expect(result.earnedSeconds, 1800);
      });
      
      test('should return 0 for 0 study duration', () {
        final result = calculator.calculateCredits(
          studyDurationSeconds: 0,
          globalRatio: 1.0,
        );
        
        expect(result.earnedSeconds, 0);
        expect(result.totalSeconds, 0);
      });
      
      test('should handle negative duration gracefully', () {
        final result = calculator.calculateCredits(
          studyDurationSeconds: -100,
          globalRatio: 1.0,
        );
        
        expect(result.earnedSeconds, 0);
      });
    });
    
    group('Streak Bonus Calculation', () {
      test('should not apply bonus for streak below threshold', () {
        final result = calculator.calculateCredits(
          studyDurationSeconds: 3600,
          globalRatio: 1.0,
          currentStreak: 2,
          streakBonusThreshold: 3,
          streakBonusMultiplier: 1.1,
        );
        
        expect(result.bonusSeconds, 0);
        expect(result.totalSeconds, 3600);
      });
      
      test('should apply bonus for streak at threshold', () {
        final result = calculator.calculateCredits(
          studyDurationSeconds: 3600,
          globalRatio: 1.0,
          currentStreak: 3,
          streakBonusThreshold: 3,
          streakBonusMultiplier: 1.1,
        );
        
        // 10% bonus = 360 seconds
        expect(result.bonusSeconds, 360);
        expect(result.totalSeconds, 3960);
      });
      
      test('should apply bonus for streak above threshold', () {
        final result = calculator.calculateCredits(
          studyDurationSeconds: 3600,
          globalRatio: 1.0,
          currentStreak: 7,
          streakBonusThreshold: 3,
          streakBonusMultiplier: 1.2,
        );
        
        // 20% bonus = 720 seconds
        expect(result.bonusSeconds, 720);
        expect(result.totalSeconds, 4320);
      });
      
      test('should cap streak bonus multiplier at 1.5', () {
        final result = calculator.calculateCredits(
          studyDurationSeconds: 3600,
          globalRatio: 1.0,
          currentStreak: 30,
          streakBonusThreshold: 3,
          streakBonusMultiplier: 2.0, // Should be capped
        );
        
        // Max 50% bonus = 1800 seconds
        expect(result.bonusSeconds, lessThanOrEqualTo(1800));
      });
    });
    
    group('Subject-Specific Ratios', () {
      test('should apply subject ratio when provided', () {
        final result = calculator.calculateCredits(
          studyDurationSeconds: 3600,
          globalRatio: 1.0,
          subjectRatio: 1.5, // Math bonus
        );
        
        // Subject ratio overrides global
        expect(result.earnedSeconds, 5400); // 1.5x
      });
      
      test('should use global ratio when no subject ratio', () {
        final result = calculator.calculateCredits(
          studyDurationSeconds: 3600,
          globalRatio: 1.2,
          subjectRatio: null,
        );
        
        expect(result.earnedSeconds, 4320);
      });
      
      test('should combine subject ratio with streak bonus', () {
        final result = calculator.calculateCredits(
          studyDurationSeconds: 3600,
          globalRatio: 1.0,
          subjectRatio: 1.5,
          currentStreak: 5,
          streakBonusThreshold: 3,
          streakBonusMultiplier: 1.1,
        );
        
        // Base: 3600 * 1.5 = 5400
        // Bonus: 5400 * 0.1 = 540
        expect(result.earnedSeconds, 5400);
        expect(result.bonusSeconds, 540);
        expect(result.totalSeconds, 5940);
      });
    });
    
    group('Weekend Modifier', () {
      test('should apply weekend modifier on weekends', () {
        final result = calculator.calculateCredits(
          studyDurationSeconds: 3600,
          globalRatio: 1.0,
          weekendModifier: 1.25,
          isWeekend: true,
        );
        
        expect(result.earnedSeconds, 4500); // 25% bonus
      });
      
      test('should not apply weekend modifier on weekdays', () {
        final result = calculator.calculateCredits(
          studyDurationSeconds: 3600,
          globalRatio: 1.0,
          weekendModifier: 1.25,
          isWeekend: false,
        );
        
        expect(result.earnedSeconds, 3600);
      });
    });
    
    group('Maximum Limits', () {
      test('should respect daily earning limit', () {
        final result = calculator.calculateCredits(
          studyDurationSeconds: 36000, // 10 hours
          globalRatio: 1.0,
          maxDailyEarningSeconds: 14400, // 4 hour limit
        );
        
        expect(result.totalSeconds, lessThanOrEqualTo(14400));
      });
      
      test('should respect maximum balance', () {
        final result = calculator.calculateCredits(
          studyDurationSeconds: 3600,
          globalRatio: 1.0,
          currentBalance: 86000, // ~24 hours
          maxBalanceSeconds: 86400, // 24 hour max
        );
        
        // Should only earn up to max
        expect(result.totalSeconds, lessThanOrEqualTo(400));
      });
      
      test('should handle already at maximum balance', () {
        final result = calculator.calculateCredits(
          studyDurationSeconds: 3600,
          globalRatio: 1.0,
          currentBalance: 86400,
          maxBalanceSeconds: 86400,
        );
        
        expect(result.totalSeconds, 0);
      });
    });
    
    group('Edge Cases', () {
      test('should handle very small study durations', () {
        final result = calculator.calculateCredits(
          studyDurationSeconds: 1,
          globalRatio: 1.0,
        );
        
        expect(result.earnedSeconds, 1);
      });
      
      test('should handle fractional results by rounding down', () {
        final result = calculator.calculateCredits(
          studyDurationSeconds: 100,
          globalRatio: 0.33,
        );
        
        // 100 * 0.33 = 33
        expect(result.earnedSeconds, 33);
      });
      
      test('should handle maximum integer values', () {
        final result = calculator.calculateCredits(
          studyDurationSeconds: 2147483647, // Max int
          globalRatio: 1.0,
          maxDailyEarningSeconds: 14400,
        );
        
        expect(result.totalSeconds, 14400);
      });
    });
    
    group('Anti-Cheat Validation', () {
      test('should reject unrealistic study durations', () {
        final result = calculator.calculateCredits(
          studyDurationSeconds: 100000, // ~28 hours
          globalRatio: 1.0,
          maxSessionDurationSeconds: 28800, // 8 hour max
        );
        
        expect(result.isValid, false);
        expect(result.rejectionReason, 'DURATION_EXCEEDED');
      });
      
      test('should validate timestamps are reasonable', () {
        final now = DateTime.now();
        final futureTime = now.add(const Duration(hours: 1));
        
        final result = calculator.validateSession(
          startTime: now,
          endTime: futureTime,
          reportedDuration: 7200, // 2 hours (wrong)
        );
        
        expect(result.isValid, false);
      });
      
      test('should detect time manipulation', () {
        final now = DateTime.now();
        final pastTime = now.subtract(const Duration(hours: 2));
        
        final result = calculator.validateSession(
          startTime: pastTime,
          endTime: now,
          reportedDuration: 3600, // Only 1 hour (trying to cheat)
        );
        
        expect(result.isValid, false);
        expect(result.rejectionReason, 'DURATION_MISMATCH');
      });
    });
  });
  
  group('SpendCalculator', () {
    late SpendCalculator calculator;
    
    setUp(() {
      calculator = SpendCalculator();
    });
    
    test('should deduct exact amount', () {
      final result = calculator.spend(
        currentBalance: 3600,
        spendAmount: 1800,
      );
      
      expect(result.newBalance, 1800);
      expect(result.amountSpent, 1800);
    });
    
    test('should not allow spending more than balance', () {
      final result = calculator.spend(
        currentBalance: 1000,
        spendAmount: 2000,
      );
      
      expect(result.success, false);
      expect(result.error, 'INSUFFICIENT_BALANCE');
    });
    
    test('should allow spending entire balance', () {
      final result = calculator.spend(
        currentBalance: 1000,
        spendAmount: 1000,
      );
      
      expect(result.success, true);
      expect(result.newBalance, 0);
    });
    
    test('should reject negative spend amounts', () {
      final result = calculator.spend(
        currentBalance: 1000,
        spendAmount: -100,
      );
      
      expect(result.success, false);
    });
  });
}

// ============================================================
// IMPLEMENTATION CLASSES FOR TESTING
// ============================================================

/// Credit calculation result
class CreditResult {
  final int earnedSeconds;
  final int bonusSeconds;
  final int totalSeconds;
  final bool isValid;
  final String? rejectionReason;
  
  CreditResult({
    required this.earnedSeconds,
    this.bonusSeconds = 0,
    required this.totalSeconds,
    this.isValid = true,
    this.rejectionReason,
  });
}

/// Spend calculation result
class SpendResult {
  final bool success;
  final int newBalance;
  final int amountSpent;
  final String? error;
  
  SpendResult({
    required this.success,
    required this.newBalance,
    required this.amountSpent,
    this.error,
  });
}

/// Session validation result
class SessionValidation {
  final bool isValid;
  final String? rejectionReason;
  
  SessionValidation({
    required this.isValid,
    this.rejectionReason,
  });
}

/// Credit calculator implementation
class CreditCalculator {
  static const int maxBonusMultiplier = 150; // 1.5x as percentage
  static const int maxSessionDuration = 28800; // 8 hours
  static const int maxDailyEarning = 14400; // 4 hours default
  static const int maxBalance = 86400; // 24 hours default
  
  CreditResult calculateCredits({
    required int studyDurationSeconds,
    required double globalRatio,
    double? subjectRatio,
    int currentStreak = 0,
    int streakBonusThreshold = 3,
    double streakBonusMultiplier = 1.0,
    double weekendModifier = 1.0,
    bool isWeekend = false,
    int? maxDailyEarningSeconds,
    int? maxBalanceSeconds,
    int currentBalance = 0,
    int? maxSessionDurationSeconds,
  }) {
    // Validate input
    if (studyDurationSeconds <= 0) {
      return CreditResult(earnedSeconds: 0, totalSeconds: 0);
    }
    
    // Check for unrealistic duration
    final maxSession = maxSessionDurationSeconds ?? maxSessionDuration;
    if (studyDurationSeconds > maxSession) {
      return CreditResult(
        earnedSeconds: 0,
        totalSeconds: 0,
        isValid: false,
        rejectionReason: 'DURATION_EXCEEDED',
      );
    }
    
    // Calculate base credits
    final ratio = subjectRatio ?? globalRatio;
    int earnedSeconds = (studyDurationSeconds * ratio).floor();
    
    // Apply weekend modifier
    if (isWeekend && weekendModifier > 1.0) {
      earnedSeconds = (earnedSeconds * weekendModifier).floor();
    }
    
    // Calculate streak bonus
    int bonusSeconds = 0;
    if (currentStreak >= streakBonusThreshold && streakBonusMultiplier > 1.0) {
      // Cap the multiplier
      final cappedMultiplier = streakBonusMultiplier > 1.5 ? 1.5 : streakBonusMultiplier;
      final bonusPercentage = cappedMultiplier - 1.0;
      bonusSeconds = (earnedSeconds * bonusPercentage).floor();
    }
    
    int totalSeconds = earnedSeconds + bonusSeconds;
    
    // Apply daily limit
    final dailyLimit = maxDailyEarningSeconds ?? maxDailyEarning;
    if (totalSeconds > dailyLimit) {
      totalSeconds = dailyLimit;
      // Recalculate bonus proportionally
      bonusSeconds = (bonusSeconds * dailyLimit / (earnedSeconds + bonusSeconds)).floor();
      earnedSeconds = totalSeconds - bonusSeconds;
    }
    
    // Apply maximum balance
    final maxBal = maxBalanceSeconds ?? maxBalance;
    final remainingCapacity = maxBal - currentBalance;
    if (remainingCapacity <= 0) {
      return CreditResult(earnedSeconds: 0, bonusSeconds: 0, totalSeconds: 0);
    }
    if (totalSeconds > remainingCapacity) {
      totalSeconds = remainingCapacity;
    }
    
    return CreditResult(
      earnedSeconds: earnedSeconds,
      bonusSeconds: bonusSeconds,
      totalSeconds: totalSeconds,
    );
  }
  
  SessionValidation validateSession({
    required DateTime startTime,
    required DateTime endTime,
    required int reportedDuration,
  }) {
    final actualDuration = endTime.difference(startTime).inSeconds;
    final tolerance = actualDuration * 0.1; // 10% tolerance
    
    if ((actualDuration - reportedDuration).abs() > tolerance) {
      return SessionValidation(
        isValid: false,
        rejectionReason: 'DURATION_MISMATCH',
      );
    }
    
    return SessionValidation(isValid: true);
  }
}

/// Spend calculator implementation
class SpendCalculator {
  SpendResult spend({
    required int currentBalance,
    required int spendAmount,
  }) {
    if (spendAmount <= 0) {
      return SpendResult(
        success: false,
        newBalance: currentBalance,
        amountSpent: 0,
        error: 'INVALID_AMOUNT',
      );
    }
    
    if (spendAmount > currentBalance) {
      return SpendResult(
        success: false,
        newBalance: currentBalance,
        amountSpent: 0,
        error: 'INSUFFICIENT_BALANCE',
      );
    }
    
    return SpendResult(
      success: true,
      newBalance: currentBalance - spendAmount,
      amountSpent: spendAmount,
    );
  }
}
