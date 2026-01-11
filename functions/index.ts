/**
 * EduTime - Firebase Cloud Functions Entry Point
 *
 * Exports all Cloud Functions for the EduTime application.
 * Organized by module for maintainability.
 * Using v1 API for compatibility.
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import { CallableContext } from "firebase-functions/v1/https";

// Initialize Firebase Admin SDK
admin.initializeApp();

const db = admin.firestore();

// ============================================================
// AUTH MODULE - User and Family Management
// ============================================================

export {
    onUserCreate,
    onUserDelete,
    updateDailyStreaks,
} from "./src/index";

export {
    createFamily,
    joinFamily,
    regenerateInviteCode,
} from "./src/modules/auth/createFamily";

// ============================================================
// SYNC MODULE - Offline Activity Synchronization
// ============================================================

export {
    syncOfflineActivity,
} from "./src/modules/sync/syncOfflineActivity";

// ============================================================
// TRIGGERS - Firestore Document Triggers
// ============================================================

export {
    onWalletUpdate,
    onSessionComplete,
} from "./src/triggers/onWalletUpdate";

// ============================================================
// WALLET MODULE - Balance Management
// ============================================================

/**
 * Spend time from wallet
 *
 * Deducts time from a child's wallet for leisure activities.
 * Supports optional parent approval workflow.
 */
export const spendWalletTime = functions.https.onCall(
    async (data: {
        childId: string;
        amountSeconds: number;
        description: string;
        appPackage?: string;
    }, context: CallableContext) => {
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "User must be authenticated"
            );
        }

        const callerUid = context.auth.uid;
        const { childId, amountSeconds, description, appPackage } = data;

        // Validate amount
        if (!amountSeconds || amountSeconds <= 0) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Amount must be positive"
            );
        }

        // Check authorization
        const isOwner = callerUid === childId;
        if (!isOwner) {
            // Check if caller is parent
            const callerDoc = await db.collection("users").doc(callerUid).get();
            if (!callerDoc.exists || callerDoc.data()?.role !== "PARENT") {
                throw new functions.https.HttpsError(
                    "permission-denied",
                    "Not authorized"
                );
            }
        }

        // Get wallet
        const walletRef = db.collection("wallets").doc(childId);
        const walletDoc = await walletRef.get();

        if (!walletDoc.exists) {
            throw new functions.https.HttpsError(
                "not-found",
                "Wallet not found"
            );
        }

        const walletData = walletDoc.data()!;

        if (walletData.balanceSeconds < amountSeconds) {
            throw new functions.https.HttpsError(
                "failed-precondition",
                "Insufficient balance"
            );
        }

        // Perform transaction
        await db.runTransaction(async (transaction) => {
            // Deduct from wallet
            transaction.update(walletRef, {
                balanceSeconds: admin.firestore.FieldValue.increment(-amountSeconds),
                lifetimeSpent: admin.firestore.FieldValue.increment(amountSeconds),
                lastTransactionAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            // Create transaction record
            const txRef = db.collection("transactions").doc();
            transaction.set(txRef, {
                id: txRef.id,
                walletId: childId,
                type: "SPEND",
                amountSeconds: -amountSeconds,
                balanceAfter: walletData.balanceSeconds - amountSeconds,
                description,
                appPackage: appPackage || null,
                initiatedBy: callerUid,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        });

        return {
            success: true,
            newBalance: walletData.balanceSeconds - amountSeconds,
            amountSpent: amountSeconds,
        };
    }
);

/**
 * Add bonus time to wallet (parent only)
 */
export const addBonusTime = functions.https.onCall(
    async (data: {
        childId: string;
        amountSeconds: number;
        reason: string;
    }, context: CallableContext) => {
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "User must be authenticated"
            );
        }

        const callerUid = context.auth.uid;
        const { childId, amountSeconds, reason } = data;

        // Verify caller is parent
        const callerDoc = await db.collection("users").doc(callerUid).get();
        if (!callerDoc.exists || callerDoc.data()?.role !== "PARENT") {
            throw new functions.https.HttpsError(
                "permission-denied",
                "Only parents can add bonus time"
            );
        }

        // Verify child is in same family
        const childDoc = await db.collection("users").doc(childId).get();
        if (!childDoc.exists) {
            throw new functions.https.HttpsError("not-found", "Child not found");
        }

        if (childDoc.data()?.familyId !== callerDoc.data()?.familyId) {
            throw new functions.https.HttpsError(
                "permission-denied",
                "Child is not in your family"
            );
        }

        // Add bonus
        const walletRef = db.collection("wallets").doc(childId);

        await db.runTransaction(async (transaction) => {
            const walletDoc = await transaction.get(walletRef);
            const currentBalance = walletDoc.exists
                ? walletDoc.data()?.balanceSeconds || 0
                : 0;

            if (walletDoc.exists) {
                transaction.update(walletRef, {
                    balanceSeconds: admin.firestore.FieldValue.increment(amountSeconds),
                    lastTransactionAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            } else {
                transaction.set(walletRef, {
                    id: childId,
                    balanceSeconds: amountSeconds,
                    lifetimeEarned: 0,
                    lifetimeSpent: 0,
                    lastTransactionAt: admin.firestore.FieldValue.serverTimestamp(),
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }

            // Create transaction record
            const txRef = db.collection("transactions").doc();
            transaction.set(txRef, {
                id: txRef.id,
                walletId: childId,
                type: "BONUS",
                amountSeconds,
                balanceAfter: currentBalance + amountSeconds,
                description: reason || "Bonus from parent",
                initiatedBy: callerUid,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        });

        return {
            success: true,
            message: `Added ${Math.floor(amountSeconds / 60)} minutes bonus time`,
        };
    }
);

/**
 * Get wallet transaction history
 */
export const getTransactionHistory = functions.https.onCall(
    async (data: {
        walletId: string;
        limit?: number;
        startAfter?: string;
    }, context: CallableContext) => {
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "User must be authenticated"
            );
        }

        const callerUid = context.auth.uid;
        const { walletId, limit = 20, startAfter } = data;

        // Check authorization
        if (callerUid !== walletId) {
            const callerDoc = await db.collection("users").doc(callerUid).get();
            if (!callerDoc.exists || callerDoc.data()?.role !== "PARENT") {
                throw new functions.https.HttpsError(
                    "permission-denied",
                    "Not authorized to view this wallet"
                );
            }
        }

        let query = db
            .collection("transactions")
            .where("walletId", "==", walletId)
            .orderBy("createdAt", "desc")
            .limit(Math.min(limit, 50));

        if (startAfter) {
            const startDoc = await db.collection("transactions").doc(startAfter).get();
            if (startDoc.exists) {
                query = query.startAfter(startDoc);
            }
        }

        const snapshot = await query.get();
        const transactions = snapshot.docs.map((doc) => ({
            id: doc.id,
            ...doc.data(),
            createdAt: doc.data().createdAt?.toDate()?.toISOString(),
        }));

        return {
            transactions,
            hasMore: transactions.length === limit,
            lastId: transactions.length > 0
                ? transactions[transactions.length - 1].id
                : null,
        };
    }
);

/**
 * Get family dashboard data (parent only)
 */
export const getFamilyDashboard = functions.https.onCall(
    async (data: { familyId: string }, context: CallableContext) => {
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "User must be authenticated"
            );
        }

        const callerUid = context.auth.uid;
        const { familyId } = data;

        // Verify caller is parent in this family
        const familyDoc = await db.collection("families").doc(familyId).get();
        if (!familyDoc.exists) {
            throw new functions.https.HttpsError("not-found", "Family not found");
        }

        const familyData = familyDoc.data()!;
        if (!familyData.parentUids.includes(callerUid)) {
            throw new functions.https.HttpsError(
                "permission-denied",
                "Not a parent of this family"
            );
        }

        // Get all children data
        const childrenData = await Promise.all(
            familyData.childUids.map(async (childId: string) => {
                const [userDoc, walletDoc, streakDoc] = await Promise.all([
                    db.collection("users").doc(childId).get(),
                    db.collection("wallets").doc(childId).get(),
                    db.collection("streaks").doc(childId).get(),
                ]);

                // Get today's study time
                const today = new Date();
                today.setHours(0, 0, 0, 0);

                const todaySessions = await db
                    .collection("users")
                    .doc(childId)
                    .collection("sessions")
                    .where("startedAt", ">=", admin.firestore.Timestamp.fromDate(today))
                    .where("status", "==", "COMPLETED")
                    .get();

                const todayStudyTime = todaySessions.docs.reduce(
                    (sum, doc) => sum + (doc.data().actualDuration || 0),
                    0
                );

                return {
                    uid: childId,
                    displayName: userDoc.data()?.displayName || "Unknown",
                    photoURL: userDoc.data()?.photoUrl,
                    balance: walletDoc.data()?.balanceSeconds || 0,
                    lifetimeEarned: walletDoc.data()?.lifetimeEarned || 0,
                    currentStreak: streakDoc.data()?.currentStreak || 0,
                    todayStudyTime,
                    status: "offline", // TODO: Implement presence
                };
            })
        );

        return {
            familyName: familyData.name,
            children: childrenData,
            inviteCode: familyData.inviteCode,
            inviteCodeExpires: familyData.inviteCodeExpiresAt?.toDate()?.toISOString(),
        };
    }
);
