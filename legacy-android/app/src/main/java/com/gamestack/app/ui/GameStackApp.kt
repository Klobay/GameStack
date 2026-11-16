package com.gamestack.app.ui

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Snackbar
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import com.gamestack.app.model.Game
import com.gamestack.app.model.MainTab

@Composable
fun GameStackApp(vm: GameViewModel, onGoogle: () -> Unit) {
    val snackbar = remember { SnackbarHostState() }
    val notice = vm.message ?: vm.info
    LaunchedEffect(notice) {
        if (notice != null) {
            snackbar.showSnackbar(notice)
            vm.clearMessage()
        }
    }
    val signedIn = vm.session != null
    val holder = remember { arrayOfNulls<Game>(1) }
    vm.selectedGame?.let { holder[0] = it }
    val shownGame = vm.selectedGame ?: holder[0]

    AmbientBackground(top = signedIn && vm.selectedGame == null) {
        Scaffold(containerColor = Color.Transparent,
            snackbarHost = {
                SnackbarHost(snackbar) { data ->
                    Snackbar(data, shape = RoundedCornerShape(14.dp), containerColor = Panel, contentColor = Ink,
                        modifier = Modifier.padding(12.dp))
                }
            },
            bottomBar = {
                if (signedIn && vm.selectedGame == null) BottomNav(vm.tab) { vm.tab = it }
            }) { padding ->
            Box(Modifier.fillMaxSize().padding(padding)) {
                when {
                    vm.initializing -> Splash()
                    !signedIn -> AuthFlow(vm, onGoogle)
                    else -> AnimatedContent(targetState = vm.selectedGame != null, label = "detail",
                        transitionSpec = {
                            if (targetState) (fadeIn(tween(260)) + scaleIn(tween(260), initialScale = 0.96f)) togetherWith fadeOut(tween(140))
                            else fadeIn(tween(220)) togetherWith (fadeOut(tween(180)))
                        }) { showGame ->
                        if (showGame) {
                            if (shownGame != null) {
                                BackHandler { vm.closeGame() }
                                DetailScreen(game = shownGame, saved = vm.games.any { it.rawgId == shownGame.rawgId },
                                    isBusy = vm.busy, backLabel = if (vm.tab == MainTab.DISCOVER) "Discover" else "Library",
                                    onBack = vm::closeGame, onSave = vm::save, onRemove = vm::remove)
                            }
                        } else {
                            AnimatedContent(targetState = vm.tab, label = "tabs",
                                transitionSpec = {
                                    val direction = if (targetState.ordinal > initialState.ordinal) 1 else -1
                                    (slideInHorizontally(tween(300, easing = FastOutSlowInEasing)) { direction * it / 6 } + fadeIn(tween(300))) togetherWith
                                        (slideOutHorizontally(tween(300, easing = FastOutSlowInEasing)) { -direction * it / 6 } + fadeOut(tween(160)))
                                }) { tab ->
                                when (tab) {
                                    MainTab.LIBRARY -> LibraryScreen(vm)
                                    MainTab.DISCOVER -> DiscoverScreen(vm)
                                    MainTab.PROFILE -> ProfileScreen(vm)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun Splash() {
    val transition = rememberInfiniteTransition(label = "splash")
    val pulse by transition.animateFloat(0.92f, 1.08f, infiniteRepeatable(tween(900, easing = FastOutSlowInEasing), RepeatMode.Reverse), label = "pulse")
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        StackMark(Modifier.size(width = 50.dp, height = 56.dp).graphicsLayer { scaleX = pulse; scaleY = pulse })
    }
}

@Composable
private fun AuthFlow(vm: GameViewModel, onGoogle: () -> Unit) {
    var route by rememberSaveable { mutableStateOf("welcome") }
    BackHandler(route != "welcome") { route = if (route == "reset") "login" else "welcome" }
    AnimatedContent(targetState = route, label = "auth",
        transitionSpec = {
            val forward = initialState == "welcome" || (initialState == "login" && targetState != "welcome")
            if (forward) (slideInHorizontally(tween(320, easing = FastOutSlowInEasing)) { it / 4 } + fadeIn(tween(320))) togetherWith
                (slideOutHorizontally(tween(320, easing = FastOutSlowInEasing)) { -it / 4 } + fadeOut(tween(180)))
            else (slideInHorizontally(tween(320, easing = FastOutSlowInEasing)) { -it / 4 } + fadeIn(tween(320))) togetherWith
                (slideOutHorizontally(tween(320, easing = FastOutSlowInEasing)) { it / 4 } + fadeOut(tween(180)))
        }) { current ->
        if (current == "welcome") WelcomeScreen(vm, onGetStarted = { route = "signup" }, onSignIn = { route = "login" })
        else AuthScreen(vm, current, onMode = { route = it }, onGoogle = onGoogle)
    }
}
