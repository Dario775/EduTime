/**
 * EduTime - Family Module Models
 * 
 * TypeScript interfaces for family/household management.
 * Supports parent-child relationships and family settings.
 */

import { Timestamp } from "firebase-admin/firestore";

/**
 * User roles within the family
 */
export enum FamilyRole {
    /** Parent/Guardian - full control */
    PARENT = "PARENT",

    /** Child/Student - limited access */
    CHILD = "CHILD",

    /** Observer - view only access */
    OBSERVER = "OBSERVER",
}

/**
 * UserProfile - Extended user information
 */
export interface UserProfile {
    /** Firebase Auth UID */
    uid: string;

    /** Display name */
    displayName: string;

    /** Email address */
    email: string;

    /** Profile photo URL */
    photoURL?: string;

    /** User's role in their family */
    role: FamilyRole;

    /** Family ID the user belongs to */
    familyId?: string;

    /** FCM token for push notifications */
    fcmToken?: string;

    /** Device tokens for multi-device support */
    deviceTokens: string[];

    /** User's timezone */
    timezone: string;

    /** Preferred language */
    language: string;

    /** Date of birth (for age-appropriate features) */
    dateOfBirth?: Timestamp;

    /** Account status */
    status: "active" | "suspended" | "pending";

    /** Account creation timestamp */
    createdAt: Timestamp;

    /** Last update timestamp */
    updatedAt: Timestamp;

    /** Last login timestamp */
    lastLoginAt?: Timestamp;
}

/**
 * Time ratio settings for earning/spending
 */
export interface TimeRatioSettings {
    /** Default study to leisure ratio (e.g., 1.0 = 1:1, 0.5 = 2:1) */
    globalRatio: number;

    /** Subject-specific ratios (overrides global) */
    subjectRatios: Record<string, number>;

    /** Bonus multiplier for streaks */
    streakBonusMultiplier: number;

    /** Minimum streak days to apply bonus */
    streakBonusThreshold: number;

    /** Weekend ratio modifier */
    weekendModifier: number;
}

/**
 * Screen time limits configuration
 */
export interface ScreenTimeLimits {
    /** Daily leisure time limit in seconds (0 = unlimited) */
    dailyLeisureLimit: number;

    /** Required study time before leisure in seconds */
    studyBeforeLeisure: number;

    /** Bedtime start (HH:mm format) */
    bedtimeStart?: string;

    /** Bedtime end (HH:mm format) */
    bedtimeEnd?: string;

    /** Days bedtime is enforced (0=Sunday, 6=Saturday) */
    bedtimeDays: number[];

    /** Break reminder interval in minutes */
    breakReminderInterval: number;
}

/**
 * FamilyConfig - Family-wide settings and configuration
 */
export interface FamilyConfig {
    /** Unique family ID */
    id: string;

    /** Family display name */
    name: string;

    /** Family owner UID (primary parent) */
    ownerUid: string;

    /** List of parent UIDs */
    parentUids: string[];

    /** List of child UIDs */
    childUids: string[];

    /** PIN hash for parental controls (bcrypt) */
    pinHash?: string;

    /** Time ratio settings */
    settings: {
        /** Global time ratio configuration */
        timeRatio: TimeRatioSettings;

        /** Screen time limits for children */
        screenTimeLimits: ScreenTimeLimits;

        /** Allow children to modify their own goals */
        allowChildGoalModification: boolean;

        /** Require approval for leisure time spending */
        requireSpendingApproval: boolean;

        /** Send parent notifications for milestones */
        notifyOnMilestones: boolean;

        /** Send daily summary notifications */
        dailySummaryEnabled: boolean;

        /** Daily summary time (HH:mm format) */
        dailySummaryTime: string;
    };

    /** Family invite code (for joining) */
    inviteCode?: string;

    /** Invite code expiration */
    inviteCodeExpiresAt?: Timestamp;

    /** Family creation timestamp */
    createdAt: Timestamp;

    /** Last update timestamp */
    updatedAt: Timestamp;
}

/**
 * Family member summary for quick access
 */
export interface FamilyMemberSummary {
    uid: string;
    displayName: string;
    photoURL?: string;
    role: FamilyRole;
    status: "online" | "offline" | "studying";
    currentBalance?: number;
    todayStudyTime?: number;
}

/**
 * Create default family settings
 */
export function createDefaultFamilySettings(): FamilyConfig["settings"] {
    return {
        timeRatio: {
            globalRatio: 1.0,
            subjectRatios: {},
            streakBonusMultiplier: 1.1,
            streakBonusThreshold: 3,
            weekendModifier: 1.0,
        },
        screenTimeLimits: {
            dailyLeisureLimit: 7200, // 2 hours
            studyBeforeLeisure: 1800, // 30 minutes
            bedtimeStart: "21:00",
            bedtimeEnd: "07:00",
            bedtimeDays: [0, 1, 2, 3, 4], // Sunday-Thursday
            breakReminderInterval: 25, // Pomodoro default
        },
        allowChildGoalModification: true,
        requireSpendingApproval: false,
        notifyOnMilestones: true,
        dailySummaryEnabled: true,
        dailySummaryTime: "20:00",
    };
}

/**
 * Create default user profile
 */
export function createDefaultUserProfile(
    uid: string,
    email: string,
    displayName?: string
): Omit<UserProfile, "createdAt" | "updatedAt"> {
    return {
        uid,
        email,
        displayName: displayName ?? email.split("@")[0],
        role: FamilyRole.CHILD,
        deviceTokens: [],
        timezone: "America/Argentina/Buenos_Aires",
        language: "es",
        status: "active",
    };
}

/**
 * Generate a random invite code
 */
export function generateInviteCode(): string {
    const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    let code = "";
    for (let i = 0; i < 8; i++) {
        code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
}

/**
 * Validate PIN format (4-6 digits)
 */
export function isValidPin(pin: string): boolean {
    return /^\d{4,6}$/.test(pin);
}
