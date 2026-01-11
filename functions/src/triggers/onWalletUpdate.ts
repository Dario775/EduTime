/**
 * EduTime - Firestore Triggers: Wallet Updates
 * 
 * Triggers for wallet balance changes to send FCM notifications
 * and update related data. Using v1 API for compatibility.
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { Change, EventContext } from "firebase-functions";
import { DocumentSnapshot } from "firebase-admin/firestore";

const db = admin.firestore();
const messaging = admin.messaging();

// ============================================================
// WALLET UPDATE TRIGGER
// ============================================================

/**
 * Trigger when a wallet document is updated
 * 
 * Sends notifications for:
 * - Significant balance changes
 * - Low balance warnings
 * - Milestone achievements
 */
export const onWalletUpdate = functions.firestore
    .document("wallets/{walletId}")
    .onUpdate(async (change: Change<DocumentSnapshot>, context: EventContext) => {
        const { walletId } = context.params;
        const beforeData = change.before.data() || {};
        const afterData = change.after.data() || {};

        const balanceBefore = beforeData.balanceSeconds || 0;
        const balanceAfter = afterData.balanceSeconds || 0;
        const balanceChange = balanceAfter - balanceBefore;

        // Skip if no balance change
        if (balanceChange === 0) {
            return null;
        }

        functions.logger.info("Wallet updated", {
            walletId,
            balanceBefore,
            balanceAfter,
            balanceChange,
        });

        // Get user and family info
        const userDoc = await db.collection("users").doc(walletId).get();
        if (!userDoc.exists) {
            functions.logger.warn("User not found for wallet", { walletId });
            return null;
        }

        const userData = userDoc.data()!;
        const isChild = userData.role === "CHILD";

        // Get family config for notification settings
        let familyConfig = null;
        if (userData.familyId) {
            const familyDoc = await db.collection("families").doc(userData.familyId).get();
            familyConfig = familyDoc.exists ? familyDoc.data() : null;
        }

        const notifications: Promise<string | null>[] = [];

        // ============ Child Notifications ============
        if (userData.fcmToken) {
            // Balance earned notification
            if (balanceChange > 0 && balanceChange >= 300) { // 5+ minutes earned
                notifications.push(
                    sendNotification(userData.fcmToken, {
                        title: "⏰ ¡Tiempo ganado!",
                        body: `Has ganado ${formatDuration(balanceChange)} de tiempo libre`,
                        data: {
                            type: "BALANCE_EARNED",
                            amount: String(balanceChange),
                            newBalance: String(balanceAfter),
                        },
                    })
                );
            }

            // Low balance warning
            if (balanceAfter < 600 && balanceAfter > 0 && balanceBefore >= 600) {
                notifications.push(
                    sendNotification(userData.fcmToken, {
                        title: "⚠️ Tiempo bajo",
                        body: `Te quedan solo ${formatDuration(balanceAfter)} de tiempo libre`,
                        data: {
                            type: "LOW_BALANCE",
                            balance: String(balanceAfter),
                        },
                    })
                );
            }

            // Balance depleted
            if (balanceAfter === 0 && balanceBefore > 0) {
                notifications.push(
                    sendNotification(userData.fcmToken, {
                        title: "🚫 Sin tiempo",
                        body: "Se acabó tu tiempo libre. ¡Estudia para ganar más!",
                        data: {
                            type: "BALANCE_EMPTY",
                        },
                    })
                );
            }
        }

        // ============ Parent Notifications ============
        if (isChild && familyConfig?.settings?.notifyOnMilestones && userData.familyId) {
            const parentNotifications = await notifyParents(
                userData.familyId,
                userData.displayName || "Tu hijo/a",
                balanceChange,
                balanceAfter,
                afterData.lifetimeEarned || 0
            );
            notifications.push(...parentNotifications);
        }

        // ============ Milestone Checks ============
        const milestones = checkMilestones(
            beforeData.lifetimeEarned || 0,
            afterData.lifetimeEarned || 0
        );

        if (milestones.length > 0 && userData.fcmToken) {
            for (const milestone of milestones) {
                // Save achievement
                const achievementRef = db
                    .collection("users")
                    .doc(walletId)
                    .collection("achievements")
                    .doc(milestone.id);

                await achievementRef.set({
                    achievementId: milestone.id,
                    unlockedAt: admin.firestore.FieldValue.serverTimestamp(),
                    rewardClaimed: false,
                });

                // Send notification
                notifications.push(
                    sendNotification(userData.fcmToken, {
                        title: `🏆 ${milestone.title}`,
                        body: milestone.description,
                        data: {
                            type: "ACHIEVEMENT",
                            achievementId: milestone.id,
                        },
                    })
                );
            }
        }

        await Promise.all(notifications);

        return null;
    });

// ============================================================
// SESSION COMPLETION TRIGGER
// ============================================================

/**
 * Trigger when a study session is completed
 * 
 * Updates streak and sends completion notifications.
 */
export const onSessionComplete = functions.firestore
    .document("users/{userId}/sessions/{sessionId}")
    .onCreate(async (snapshot: DocumentSnapshot, context: EventContext) => {
        const { userId } = context.params;
        const sessionData = snapshot.data();

        if (!sessionData) return null;

        // Only process completed study sessions
        if (sessionData.status !== "COMPLETED" || sessionData.type === "leisure") {
            return null;
        }

        // Update streak
        await updateStreak(userId);

        // Update subject stats if applicable
        if (sessionData.subjectId) {
            await updateSubjectStats(
                userId,
                sessionData.subjectId,
                sessionData.actualDuration
            );
        }

        return null;
    });

// ============================================================
// HELPER FUNCTIONS
// ============================================================

/**
 * Send FCM notification
 */
async function sendNotification(
    token: string,
    notification: {
        title: string;
        body: string;
        data?: Record<string, string>;
    }
): Promise<string | null> {
    try {
        const message: admin.messaging.Message = {
            token,
            notification: {
                title: notification.title,
                body: notification.body,
            },
            data: notification.data,
            android: {
                priority: "high",
                notification: {
                    channelId: "edutime_main",
                    icon: "ic_notification",
                    color: "#2563EB",
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: "default",
                        badge: 1,
                    },
                },
            },
        };

        return await messaging.send(message);
    } catch (error: unknown) {
        const firebaseError = error as { code?: string };
        if (firebaseError.code === "messaging/registration-token-not-registered") {
            // Token is invalid, should be removed from user document
            functions.logger.warn("Invalid FCM token", { token });
        } else {
            functions.logger.error("Error sending notification", { error });
        }
        return null;
    }
}

/**
 * Notify all parents in a family
 */
async function notifyParents(
    familyId: string,
    childName: string,
    balanceChange: number,
    _newBalance: number,
    _lifetimeEarned: number
): Promise<Promise<string | null>[]> {
    const notifications: Promise<string | null>[] = [];

    const familyDoc = await db.collection("families").doc(familyId).get();
    if (!familyDoc.exists) return notifications;

    const familyData = familyDoc.data()!;
    const parentUids = familyData.parentUids || [];

    for (const parentUid of parentUids) {
        const parentDoc = await db.collection("users").doc(parentUid).get();
        if (!parentDoc.exists) continue;

        const parentData = parentDoc.data()!;
        if (!parentData.fcmToken) continue;

        // Significant earning notification
        if (balanceChange >= 1800) { // 30+ minutes
            notifications.push(
                sendNotification(parentData.fcmToken, {
                    title: "📚 Sesión de estudio",
                    body: `${childName} ganó ${formatDuration(balanceChange)} estudiando`,
                    data: {
                        type: "CHILD_STUDY",
                        childId: familyId,
                        duration: String(balanceChange),
                    },
                })
            );
        }
    }

    return notifications;
}

/**
 * Check for milestone achievements
 */
interface Milestone {
    id: string;
    title: string;
    description: string;
    threshold: number;
}

const MILESTONES: Milestone[] = [
    {
        id: "first_hour",
        title: "Primera hora",
        description: "¡Completaste tu primera hora de estudio!",
        threshold: 3600,
    },
    {
        id: "five_hours",
        title: "¡5 horas!",
        description: "Has estudiado 5 horas en total",
        threshold: 18000,
    },
    {
        id: "ten_hours",
        title: "Estudiante dedicado",
        description: "¡10 horas de estudio acumuladas!",
        threshold: 36000,
    },
    {
        id: "twentyfive_hours",
        title: "Camino al éxito",
        description: "25 horas de estudio completadas",
        threshold: 90000,
    },
    {
        id: "fifty_hours",
        title: "Experto",
        description: "¡50 horas de estudio! Increíble dedicación",
        threshold: 180000,
    },
    {
        id: "hundred_hours",
        title: "Maestro del tiempo",
        description: "100 horas de estudio. ¡Eres imparable!",
        threshold: 360000,
    },
];

function checkMilestones(beforeTotal: number, afterTotal: number): Milestone[] {
    return MILESTONES.filter(
        (m) => beforeTotal < m.threshold && afterTotal >= m.threshold
    );
}

/**
 * Format duration in seconds to human readable string
 */
function formatDuration(seconds: number): string {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);

    if (hours > 0 && minutes > 0) {
        return `${hours}h ${minutes}m`;
    } else if (hours > 0) {
        return `${hours}h`;
    } else {
        return `${minutes}m`;
    }
}

/**
 * Update user's study streak
 */
async function updateStreak(userId: string): Promise<void> {
    const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD

    const streakRef = db.collection("streaks").doc(userId);
    const streakDoc = await streakRef.get();

    if (!streakDoc.exists) {
        // Create new streak
        await streakRef.set({
            userId,
            currentStreak: 1,
            longestStreak: 1,
            lastStudyDate: today,
            streakStartDate: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
    }

    const streakData = streakDoc.data()!;
    const lastStudyDate = streakData.lastStudyDate;

    if (lastStudyDate === today) {
        // Already studied today, no update needed
        return;
    }

    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayStr = yesterday.toISOString().split("T")[0];

    let newStreak = 1;
    if (lastStudyDate === yesterdayStr) {
        // Continued streak
        newStreak = (streakData.currentStreak || 0) + 1;
    }

    const newLongest = Math.max(newStreak, streakData.longestStreak || 0);

    await streakRef.update({
        currentStreak: newStreak,
        longestStreak: newLongest,
        lastStudyDate: today,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}

/**
 * Update subject statistics
 */
async function updateSubjectStats(
    userId: string,
    subjectId: string,
    duration: number
): Promise<void> {
    const subjectRef = db
        .collection("users")
        .doc(userId)
        .collection("subjects")
        .doc(subjectId);

    await subjectRef.update({
        totalStudyTime: admin.firestore.FieldValue.increment(duration),
        sessionCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}
