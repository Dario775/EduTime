package com.edutime.app.services

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import com.edutime.app.MainActivity
import com.edutime.app.R
import io.flutter.embedding.android.FlutterActivity

/**
 * OverlayService - Displays blocking overlay using SYSTEM_ALERT_WINDOW
 * 
 * This service creates a full-screen overlay that blocks access to
 * restricted apps when the child has no time balance.
 */
class OverlayService : Service() {
    
    companion object {
        private const val TAG = "OverlayService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "edutime_overlay_channel"
        
        const val ACTION_SHOW_OVERLAY = "com.edutime.app.SHOW_OVERLAY"
        const val ACTION_HIDE_OVERLAY = "com.edutime.app.HIDE_OVERLAY"
        const val ACTION_UPDATE_OVERLAY = "com.edutime.app.UPDATE_OVERLAY"
        
        const val EXTRA_APP_NAME = "app_name"
        const val EXTRA_PACKAGE_NAME = "package_name"
        const val EXTRA_REMAINING_SECONDS = "remaining_seconds"
        const val EXTRA_MESSAGE = "message"
        
        /**
         * Check if overlay permission is granted
         */
        fun canDrawOverlays(context: Context): Boolean {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Settings.canDrawOverlays(context)
            } else {
                true
            }
        }
        
        /**
         * Open overlay permission settings
         */
        fun requestOverlayPermission(context: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    android.net.Uri.parse("package:${context.packageName}")
                )
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
            }
        }
    }
    
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var isOverlayShown = false
    private val handler = Handler(Looper.getMainLooper())
    
    // Listener for overlay events
    interface OnOverlayEventListener {
        fun onOverlayShown()
        fun onOverlayHidden()
        fun onStudyPressed()
    }
    
    private var overlayEventListener: OnOverlayEventListener? = null
    
    fun setOnOverlayEventListener(listener: OnOverlayEventListener?) {
        overlayEventListener = listener
    }
    
    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        createNotificationChannel()
        Log.i(TAG, "OverlayService created")
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_SHOW_OVERLAY -> {
                val appName = intent.getStringExtra(EXTRA_APP_NAME) ?: "App"
                val remainingSeconds = intent.getIntExtra(EXTRA_REMAINING_SECONDS, 0)
                showOverlay(appName, remainingSeconds)
            }
            ACTION_HIDE_OVERLAY -> {
                hideOverlay()
            }
            ACTION_UPDATE_OVERLAY -> {
                val remainingSeconds = intent.getIntExtra(EXTRA_REMAINING_SECONDS, 0)
                updateOverlayTime(remainingSeconds)
            }
        }
        
        // Start as foreground service
        startForeground(NOTIFICATION_ID, createNotification())
        
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onDestroy() {
        super.onDestroy()
        hideOverlay()
        Log.i(TAG, "OverlayService destroyed")
    }
    
    /**
     * Create notification channel for Android O+
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "EduTime Monitoring",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitoring app usage"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    /**
     * Create foreground notification
     */
    private fun createNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("EduTime")
            .setContentText("Monitoreando uso de apps")
            .setSmallIcon(android.R.drawable.ic_menu_recent_history)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
    
    /**
     * Show the blocking overlay
     */
    private fun showOverlay(appName: String, remainingSeconds: Int) {
        if (!canDrawOverlays(this)) {
            Log.w(TAG, "Cannot draw overlays - permission not granted")
            return
        }
        
        if (isOverlayShown) {
            // Update existing overlay
            updateOverlayContent(appName, remainingSeconds)
            return
        }
        
        handler.post {
            try {
                overlayView = createOverlayView(appName, remainingSeconds)
                
                val layoutParams = createLayoutParams()
                
                windowManager?.addView(overlayView, layoutParams)
                isOverlayShown = true
                overlayEventListener?.onOverlayShown()
                
                Log.i(TAG, "Overlay shown for: $appName")
            } catch (e: Exception) {
                Log.e(TAG, "Error showing overlay", e)
            }
        }
    }
    
    /**
     * Hide the blocking overlay
     */
    private fun hideOverlay() {
        handler.post {
            try {
                if (overlayView != null && isOverlayShown) {
                    windowManager?.removeView(overlayView)
                    overlayView = null
                    isOverlayShown = false
                    overlayEventListener?.onOverlayHidden()
                    Log.i(TAG, "Overlay hidden")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error hiding overlay", e)
            }
        }
    }
    
    /**
     * Update overlay time display
     */
    private fun updateOverlayTime(remainingSeconds: Int) {
        handler.post {
            overlayView?.findViewById<TextView>(R.id.tv_remaining_time)?.text = 
                formatTime(remainingSeconds)
        }
    }
    
    /**
     * Update overlay content
     */
    private fun updateOverlayContent(appName: String, remainingSeconds: Int) {
        handler.post {
            overlayView?.apply {
                findViewById<TextView>(R.id.tv_blocked_app)?.text = appName
                findViewById<TextView>(R.id.tv_remaining_time)?.text = formatTime(remainingSeconds)
            }
        }
    }
    
    /**
     * Create window layout parameters
     */
    private fun createLayoutParams(): WindowManager.LayoutParams {
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
        }
        
        return WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_FULLSCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER
        }
    }
    
    /**
     * Create the overlay view programmatically
     */
    private fun createOverlayView(appName: String, remainingSeconds: Int): View {
        val context = this
        
        return LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#E6000000")) // 90% opacity black
            setPadding(48, 48, 48, 48)
            
            // Lock Icon (using emoji as fallback)
            addView(TextView(context).apply {
                text = "🔒"
                textSize = 64f
                gravity = Gravity.CENTER
                setPadding(0, 0, 0, 32)
            })
            
            // Title
            addView(TextView(context).apply {
                text = "¡Tiempo Agotado!"
                textSize = 28f
                setTextColor(Color.WHITE)
                gravity = Gravity.CENTER
                setPadding(0, 0, 0, 16)
            })
            
            // Subtitle
            addView(TextView(context).apply {
                text = "No tienes tiempo libre disponible"
                textSize = 16f
                setTextColor(Color.parseColor("#B3FFFFFF"))
                gravity = Gravity.CENTER
                setPadding(0, 0, 0, 32)
            })
            
            // Blocked App Card
            addView(LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER
                setBackgroundColor(Color.parseColor("#1AFFFFFF"))
                setPadding(32, 24, 32, 24)
                
                addView(TextView(context).apply {
                    text = "⛔"
                    textSize = 24f
                    setPadding(0, 0, 16, 0)
                })
                
                addView(LinearLayout(context).apply {
                    orientation = LinearLayout.VERTICAL
                    
                    addView(TextView(context).apply {
                        text = "App bloqueada"
                        textSize = 12f
                        setTextColor(Color.parseColor("#80FFFFFF"))
                    })
                    
                    addView(TextView(context).apply {
                        id = R.id.tv_blocked_app
                        text = appName
                        textSize = 18f
                        setTextColor(Color.WHITE)
                    })
                })
            })
            
            // Spacer
            addView(View(context).apply {
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    32
                )
            })
            
            // Remaining Time (if any)
            if (remainingSeconds > 0) {
                addView(LinearLayout(context).apply {
                    orientation = LinearLayout.VERTICAL
                    gravity = Gravity.CENTER
                    setBackgroundColor(Color.parseColor("#33FFC107"))
                    setPadding(48, 24, 48, 24)
                    
                    addView(TextView(context).apply {
                        text = "Tiempo restante"
                        textSize = 14f
                        setTextColor(Color.parseColor("#FFC107"))
                        gravity = Gravity.CENTER
                    })
                    
                    addView(TextView(context).apply {
                        id = R.id.tv_remaining_time
                        text = formatTime(remainingSeconds)
                        textSize = 32f
                        setTextColor(Color.WHITE)
                        gravity = Gravity.CENTER
                    })
                })
                
                // Spacer
                addView(View(context).apply {
                    layoutParams = LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.MATCH_PARENT,
                        32
                    )
                })
            }
            
            // Study Button
            addView(Button(context).apply {
                text = "¡Empezar a Estudiar!"
                textSize = 16f
                setTextColor(Color.WHITE)
                setBackgroundColor(Color.parseColor("#2563EB"))
                setPadding(64, 24, 64, 24)
                
                setOnClickListener {
                    hideOverlay()
                    overlayEventListener?.onStudyPressed()
                    
                    // Open EduTime app
                    val intent = Intent(context, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        putExtra("action", "start_study")
                    }
                    startActivity(intent)
                }
            })
            
            // Info text
            addView(TextView(context).apply {
                text = "Estudia para ganar más tiempo libre"
                textSize = 12f
                setTextColor(Color.parseColor("#80FFFFFF"))
                gravity = Gravity.CENTER
                setPadding(0, 24, 0, 0)
            })
        }
    }
    
    /**
     * Format seconds to readable time string
     */
    private fun formatTime(seconds: Int): String {
        val hours = seconds / 3600
        val minutes = (seconds % 3600) / 60
        val secs = seconds % 60
        
        return when {
            hours > 0 -> "${hours}h ${minutes}m"
            minutes > 0 -> "${minutes}m ${secs}s"
            else -> "${secs}s"
        }
    }
}
