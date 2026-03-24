package com.example.artemis_mobile

import android.content.Context
import android.content.res.Configuration
import io.flutter.embedding.android.FlutterActivity
import java.util.Locale

class MainActivity : FlutterActivity() {
    override fun attachBaseContext(newBase: Context) {
        val tr = Locale("tr", "TR")
        Locale.setDefault(tr)
        val cfg = Configuration(newBase.resources.configuration)
        cfg.setLocale(tr)
        super.attachBaseContext(newBase.createConfigurationContext(cfg))
    }
}
