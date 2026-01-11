package com.edutime.app.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.edutime.app.services.EduAccessibilityService
import com.edutime.app.services.OverlayService

/**
 * BootReceiver - Starts monitoring service on device boot
 * 
 * This receiver is triggered when the device boots up and
 * restarts the monitoring service if it was previously enabled.
 */
class BootReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "BootReceiver"
        private const val PREFS_NAME = "edutime_monitor_prefs"
        private const val KEY_MONITORING_ENABLED = "monitoring_enabled"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON" ||
            intent.action == "com.htc.intent.action.QUICKBOOT_POWERON") {
            
            Log.i(TAG, "Boot completed, checking if monitoring should start")
            
            // Check if monitoring was enabled before reboot
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val monitoringEnabled = prefs.getBoolean(KEY_MONITORING_ENABLED, false)
            
            if (monitoringEnabled) {
                // Check if accessibility service is still enabled
                if (EduAccessibilityService.isAccessibilityServiceEnabled(context)) {
                    Log.i(TAG, "Starting monitoring service after boot")
                    startOverlayService(context)
                } else {
                    Log.w(TAG, "Accessibility service not enabled, cannot start monitoring")
                }
            } else {
                Log.d(TAG, "Monitoring not enabled, skipping auto-start")
            }
        }
    }
    
    private fun startOverlayService(context: Context) {
        val intent = Intent(context, OverlayService::class.java)
        
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start overlay service", e)
        }
    }
}
