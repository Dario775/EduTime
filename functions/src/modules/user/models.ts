/**
 * EduTime - User Module Models
 * 
 * Core user models and types used across the application.
 */

import { Timestamp } from "firebase-admin/firestore";
import { FamilyRole } from "../family/models";

/**
 * Study session status
 */
export enum SessionStatus {
    /** Session in progress */
    ACTIVE = "ACTIVE",

    /** Session completed successfully */
    COMPLETED = "COMPLETED",

    /** Session paused */
    PAUSED = "PAUSED",

    /** Session cancelled/abandoned */
    CANCELLED = "CANCELLED",
}

/**
 * Study session type
 */
export enum SessionType {
    /** Pomodoro technique session */
    POMODORO = "POMODORO",

    /** Free-form study session */
    FREE = "FREE",

    /** Timed session with goal */
    TIMED = "TIMED",
}

/**
 * Study Session - Records individual study periods
 */
export interface StudySession {
    /** Unique session ID */
    id: string;

    /** User ID */
    userId: string;

    /** Subject being studied */
    subjectId?: string;

    /** Subject name (denormalized for quick access) */
    subjectName?: string;

    /** Session type */
    type: SessionType;

    /** Session status */
    status: SessionStatus;

    /** Planned duration in seconds */
    plannedDuration: number;

    /** Actual duration in seconds */
    actualDuration: number;

    /** Time earned in seconds (after ratio applied) */
    earnedTime: number;

    /** Start timestamp */
    startedAt: Timestamp;

    /** End timestamp (null if active) */
    endedAt?: Timestamp;

    /** Pause periods */
    pausePeriods: Array<{
        pausedAt: Timestamp;
        resumedAt?: Timestamp;
    }>;

    /** Total pause time in seconds */
    totalPauseTime: number;

    /** Notes about the session */
    notes?: string;

    /** Rating (1-5) */
    rating?: number;

    /** Was the goal met? */
    goalMet: boolean;

    /** Creation timestamp */
    createdAt: Timestamp;

    /** Last update timestamp */
    updatedAt: Timestamp;
}

/**
 * Subject - Study subjects/topics
 */
export interface Subject {
    /** Unique subject ID */
    id: string;

    /** User ID */
    userId: string;

    /** Subject name */
    name: string;

    /** Subject color (hex) */
    color: string;

    /** Subject icon name */
    icon: string;

    /** Custom time ratio for this subject (overrides family setting) */
    customRatio?: number;

    /** Total study time in seconds */
    totalStudyTime: number;

    /** Total sessions count */
    sessionCount: number;

    /** Is this subject archived? */
    isArchived: boolean;

    /** Display order */
    order: number;

    /** Creation timestamp */
    createdAt: Timestamp;

    /** Last update timestamp */
    updatedAt: Timestamp;
}

/**
 * Goal - Study goals
 */
export interface Goal {
    /** Unique goal ID */
    id: string;

    /** User ID */
    userId: string;

    /** Goal title */
    title: string;

    /** Goal description */
    description?: string;

    /** Target duration in seconds */
    targetDuration: number;

    /** Current progress in seconds */
    currentProgress: number;

    /** Goal type */
    type: "daily" | "weekly" | "monthly" | "custom";

    /** Subject ID (optional, for subject-specific goals) */
    subjectId?: string;

    /** Start date */
    startDate: Timestamp;

    /** End date */
    endDate: Timestamp;

    /** Is the goal completed? */
    isCompleted: boolean;

    /** Completion timestamp */
    completedAt?: Timestamp;

    /** Creation timestamp */
    createdAt: Timestamp;

    /** Last update timestamp */
    updatedAt: Timestamp;
}

/**
 * Achievement - Unlockable achievements
 */
export interface Achievement {
    /** Achievement ID */
    id: string;

    /** Achievement name */
    name: string;

    /** Achievement description */
    description: string;

    /** Icon name */
    icon: string;

    /** Achievement category */
    category: "streak" | "time" | "goals" | "social" | "special";

    /** Unlock criteria */
    criteria: {
        type: string;
        value: number;
    };

    /** XP reward */
    xpReward: number;

    /** Time bonus reward in seconds */
    timeBonusReward: number;
}

/**
 * UserAchievement - User's unlocked achievements
 */
export interface UserAchievement {
    /** User ID */
    userId: string;

    /** Achievement ID */
    achievementId: string;

    /** Unlock timestamp */
    unlockedAt: Timestamp;

    /** Was the reward claimed? */
    rewardClaimed: boolean;

    /** Reward claim timestamp */
    rewardClaimedAt?: Timestamp;
}

/**
 * User streak information
 */
export interface UserStreak {
    /** User ID */
    userId: string;

    /** Current streak in days */
    currentStreak: number;

    /** Longest streak ever */
    longestStreak: number;

    /** Last study date (YYYY-MM-DD) */
    lastStudyDate: string;

    /** Streak start date */
    streakStartDate?: Timestamp;

    /** Last update */
    updatedAt: Timestamp;
}
