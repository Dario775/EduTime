/**
 * EduTime - Auth Module: Create Family
 * 
 * Cloud Function for creating a new family and setting up the owner as parent.
 * Using v1 API for compatibility.
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { CallableContext } from "firebase-functions/v1/https";

const db = admin.firestore();

// ============================================================
// TYPES
// ============================================================

interface CreateFamilyRequest {
    /** Family display name */
    familyName: string;

    /** Optional PIN for parental controls (4-6 digits) */
    pin?: string;

    /** Initial family settings (optional) */
    settings?: Partial<FamilySettings>;
}

interface FamilySettings {
    timeRatio: {
        globalRatio: number;
        subjectRatios: Record<string, number>;
        streakBonusMultiplier: number;
        streakBonusThreshold: number;
        weekendModifier: number;
    };
    screenTimeLimits: {
        dailyLeisureLimit: number;
        studyBeforeLeisure: number;
        bedtimeStart?: string;
        bedtimeEnd?: string;
        bedtimeDays: number[];
        breakReminderInterval: number;
    };
    allowChildGoalModification: boolean;
    requireSpendingApproval: boolean;
    notifyOnMilestones: boolean;
    dailySummaryEnabled: boolean;
    dailySummaryTime: string;
}

interface CreateFamilyResponse {
    success: boolean;
    familyId: string;
    inviteCode: string;
    message: string;
}

// ============================================================
// HELPER FUNCTIONS
// ============================================================

/**
 * Generate a random invite code
 */
function generateInviteCode(): string {
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
function isValidPin(pin: string): boolean {
    return /^\d{4,6}$/.test(pin);
}

/**
 * Simple hash PIN (in production, use bcrypt)
 * Note: Install bcrypt with `npm install bcrypt @types/bcrypt` for production
 */
async function hashPin(pin: string): Promise<string> {
    const crypto = await import("crypto");
    return crypto.createHash("sha256").update(pin).digest("hex");
}

/**
 * Get default family settings
 */
function getDefaultSettings(): FamilySettings {
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

// ============================================================
// MAIN FUNCTION
// ============================================================

/**
 * Create a new family
 *
 * The authenticated user becomes the family owner and first parent.
 * A unique invite code is generated for adding family members.
 */
export const createFamily = functions.https.onCall(
    async (data: CreateFamilyRequest, context: CallableContext): Promise<CreateFamilyResponse> => {
        // ============ Authentication ============
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "User must be authenticated"
            );
        }

        const ownerUid = context.auth.uid;
        const { familyName, pin, settings: customSettings } = data;

        // ============ Validation ============
        if (!familyName || familyName.trim().length < 2) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Family name must be at least 2 characters"
            );
        }

        if (familyName.length > 50) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Family name must be 50 characters or less"
            );
        }

        if (pin && !isValidPin(pin)) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "PIN must be 4-6 digits"
            );
        }

        // ============ Check Existing Family ============
        const userDoc = await db.collection("users").doc(ownerUid).get();

        if (!userDoc.exists) {
            throw new functions.https.HttpsError(
                "not-found",
                "User profile not found"
            );
        }

        const userData = userDoc.data()!;

        if (userData.familyId) {
            throw new functions.https.HttpsError(
                "already-exists",
                "User already belongs to a family"
            );
        }

        // ============ Create Family ============
        const familyRef = db.collection("families").doc();
        const inviteCode = generateInviteCode();
        const inviteCodeExpiresAt = new Date();
        inviteCodeExpiresAt.setDate(inviteCodeExpiresAt.getDate() + 7); // 7 days

        // Merge custom settings with defaults
        const defaultSettings = getDefaultSettings();
        const mergedSettings: FamilySettings = {
            ...defaultSettings,
            ...customSettings,
            timeRatio: {
                ...defaultSettings.timeRatio,
                ...customSettings?.timeRatio,
            },
            screenTimeLimits: {
                ...defaultSettings.screenTimeLimits,
                ...customSettings?.screenTimeLimits,
            },
        };

        // Hash PIN if provided
        let pinHash: string | null = null;
        if (pin) {
            pinHash = await hashPin(pin);
        }

        const familyData = {
            id: familyRef.id,
            name: familyName.trim(),
            ownerUid,
            parentUids: [ownerUid],
            childUids: [],
            pinHash,
            settings: mergedSettings,
            inviteCode,
            inviteCodeExpiresAt: admin.firestore.Timestamp.fromDate(inviteCodeExpiresAt),
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        // ============ Transaction ============
        await db.runTransaction(async (transaction) => {
            // Create family document
            transaction.set(familyRef, familyData);

            // Update user to PARENT role and assign family
            transaction.update(db.collection("users").doc(ownerUid), {
                role: "PARENT",
                familyId: familyRef.id,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            // Create wallet for the user if it doesn't exist
            const walletRef = db.collection("wallets").doc(ownerUid);
            const walletDoc = await transaction.get(walletRef);

            if (!walletDoc.exists) {
                transaction.set(walletRef, {
                    id: ownerUid,
                    balanceSeconds: 0,
                    lifetimeEarned: 0,
                    lifetimeSpent: 0,
                    lastTransactionAt: null,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
        });

        functions.logger.info("Family created", {
            familyId: familyRef.id,
            ownerUid,
            familyName: familyName.trim(),
        });

        return {
            success: true,
            familyId: familyRef.id,
            inviteCode,
            message: "Family created successfully",
        };
    }
);

/**
 * Join a family using invite code
 */
export const joinFamily = functions.https.onCall(
    async (data: { inviteCode: string; role?: "CHILD" | "PARENT" }, context: CallableContext) => {
        // ============ Authentication ============
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "User must be authenticated"
            );
        }

        const userUid = context.auth.uid;
        const { inviteCode, role = "CHILD" } = data;

        // ============ Validation ============
        if (!inviteCode || inviteCode.length !== 8) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Invalid invite code format"
            );
        }

        // ============ Find Family ============
        const familiesQuery = await db
            .collection("families")
            .where("inviteCode", "==", inviteCode.toUpperCase())
            .limit(1)
            .get();

        if (familiesQuery.empty) {
            throw new functions.https.HttpsError(
                "not-found",
                "Invalid or expired invite code"
            );
        }

        const familyDoc = familiesQuery.docs[0];
        const familyData = familyDoc.data();

        // Check expiration
        if (familyData.inviteCodeExpiresAt.toDate() < new Date()) {
            throw new functions.https.HttpsError(
                "failed-precondition",
                "Invite code has expired"
            );
        }

        // ============ Check User ============
        const userDoc = await db.collection("users").doc(userUid).get();

        if (!userDoc.exists) {
            throw new functions.https.HttpsError(
                "not-found",
                "User profile not found"
            );
        }

        const userData = userDoc.data()!;

        if (userData.familyId) {
            throw new functions.https.HttpsError(
                "already-exists",
                "User already belongs to a family"
            );
        }

        // ============ Join Family ============
        await db.runTransaction(async (transaction) => {
            // Update family members list
            const updateField = role === "PARENT" ? "parentUids" : "childUids";
            transaction.update(familyDoc.ref, {
                [updateField]: admin.firestore.FieldValue.arrayUnion(userUid),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            // Update user
            transaction.update(db.collection("users").doc(userUid), {
                role,
                familyId: familyDoc.id,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            // Create wallet for the user if it doesn't exist
            const walletRef = db.collection("wallets").doc(userUid);
            const walletDoc = await transaction.get(walletRef);

            if (!walletDoc.exists) {
                transaction.set(walletRef, {
                    id: userUid,
                    balanceSeconds: 0,
                    lifetimeEarned: 0,
                    lifetimeSpent: 0,
                    lastTransactionAt: null,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
        });

        functions.logger.info("User joined family", {
            userUid,
            familyId: familyDoc.id,
            role,
        });

        return {
            success: true,
            familyId: familyDoc.id,
            familyName: familyData.name,
            message: "Successfully joined family",
        };
    }
);

/**
 * Regenerate invite code (parent only)
 */
export const regenerateInviteCode = functions.https.onCall(
    async (data: { familyId: string }, context: CallableContext) => {
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "User must be authenticated"
            );
        }

        const userUid = context.auth.uid;
        const { familyId } = data;

        const familyDoc = await db.collection("families").doc(familyId).get();

        if (!familyDoc.exists) {
            throw new functions.https.HttpsError("not-found", "Family not found");
        }

        const familyData = familyDoc.data()!;

        if (!familyData.parentUids.includes(userUid)) {
            throw new functions.https.HttpsError(
                "permission-denied",
                "Only parents can regenerate invite codes"
            );
        }

        const newInviteCode = generateInviteCode();
        const expiresAt = new Date();
        expiresAt.setDate(expiresAt.getDate() + 7);

        await familyDoc.ref.update({
            inviteCode: newInviteCode,
            inviteCodeExpiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return {
            success: true,
            inviteCode: newInviteCode,
            expiresAt: expiresAt.toISOString(),
        };
    }
);
