package com.example.artisan_marketplace

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Reveal the Flutter brand screen immediately when its first frame is ready.
            splashScreen.setOnExitAnimationListener { splashView ->
                splashView.remove()
            }
        }
    }
}
