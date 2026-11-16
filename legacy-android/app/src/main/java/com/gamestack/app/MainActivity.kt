package com.gamestack.app

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.compose.material3.*
import androidx.compose.foundation.layout.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.Alignment
import com.gamestack.app.ui.*

class MainActivity : ComponentActivity() {
    private var pendingAuthUri by androidx.compose.runtime.mutableStateOf<android.net.Uri?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (intent?.data?.scheme == "gamestack") pendingAuthUri = intent?.data
        val barStyle = androidx.activity.SystemBarStyle.dark(android.graphics.Color.TRANSPARENT)
        enableEdgeToEdge(statusBarStyle = barStyle, navigationBarStyle = barStyle)
        setContent {
            val vm: GameViewModel = viewModel()
            val uri = pendingAuthUri
            androidx.compose.runtime.LaunchedEffect(uri) {
                if (uri != null) { vm.finishGoogle(uri); pendingAuthUri = null }
            }
            GameStackTheme {
                GameStackApp(vm, onGoogle = {
                    val url = vm.googleUrl()
                    startActivity(Intent(Intent.ACTION_VIEW, android.net.Uri.parse(url)))
                })
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.data?.scheme == "gamestack") pendingAuthUri = intent.data
    }
}
