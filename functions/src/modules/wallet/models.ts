/**
 * EduTime - Wallet Module Models
 * 
 * TypeScript interfaces for the Wallet domain.
 * Handles time-based currency for the educational reward system.
 */

import { Timestamp } from "firebase-admin/firestore";

/**
 * Wallet - Stores user's earned time balance
 * 
 * The wallet tracks time earned through study sessions
 * that can be "spent" on leisure activities.
 */
export interface Wallet {
    /** Unique wallet ID (same as user UID) */
    id: string;

    /** Current balance in seconds */
    balanceSeconds: number;

    /** Total time earned since account creation (in seconds) */
    lifetimeEarned: number;

    /** Total time spent since account creation (in seconds) */
    lifetimeSpent: number;

    /** Last transaction timestamp */
    lastTransactionAt: Timestamp | null;

    /** Wallet creation timestamp */
    createdAt: Timestamp;

    /** Last update timestamp */
    updatedAt: Timestamp;
}

/**
 * Transaction types for wallet operations
 */
export enum TransactionType {
    /** Time earned from study session */
    EARN = "EARN",

    /** Time spent on leisure */
    SPEND = "SPEND",

    /** Manual adjustment by parent/admin */
    ADJUSTMENT = "ADJUSTMENT",

    /** Bonus time reward */
    BONUS = "BONUS",

    /** Penalty/deduction */
    PENALTY = "PENALTY",
}

/**
 * Transaction - Records wallet balance changes
 */
export interface Transaction {
    /** Unique transaction ID */
    id: string;

    /** Associated wallet ID */
    walletId: string;

    /** Type of transaction */
    type: TransactionType;

    /** Amount in seconds (positive for earn, negative for spend) */
    amountSeconds: number;

    /** Balance after this transaction */
    balanceAfter: number;

    /** Description of the transaction */
    description: string;

    /** Related session ID (if applicable) */
    sessionId?: string;

    /** Related subject ID (if applicable) */
    subjectId?: string;

    /** User who initiated the transaction (for adjustments) */
    initiatedBy?: string;

    /** Transaction timestamp */
    createdAt: Timestamp;
}

/**
 * Wallet statistics for reporting
 */
export interface WalletStats {
    /** User ID */
    userId: string;

    /** Current balance */
    currentBalance: number;

    /** Earnings today */
    earnedToday: number;

    /** Spent today */
    spentToday: number;

    /** Earnings this week */
    earnedThisWeek: number;

    /** Spent this week */
    spentThisWeek: number;

    /** Earnings this month */
    earnedThisMonth: number;

    /** Spent this month */
    spentThisMonth: number;

    /** Average daily earnings */
    averageDailyEarnings: number;
}

/**
 * Create a new wallet with default values
 */
export function createDefaultWallet(userId: string): Omit<Wallet, "id"> {
    const now = Timestamp.now();
    return {
        balanceSeconds: 0,
        lifetimeEarned: 0,
        lifetimeSpent: 0,
        lastTransactionAt: null,
        createdAt: now,
        updatedAt: now,
    };
}

/**
 * Validate wallet balance is sufficient for spending
 */
export function canSpend(wallet: Wallet, amountSeconds: number): boolean {
    return wallet.balanceSeconds >= amountSeconds && amountSeconds > 0;
}

/**
 * Format seconds to human-readable time string
 */
export function formatTime(seconds: number): string {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;

    if (hours > 0) {
        return `${hours}h ${minutes}m`;
    } else if (minutes > 0) {
        return `${minutes}m ${secs}s`;
    }
    return `${secs}s`;
}
