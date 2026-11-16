package com.gamestack.app.ui

import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.ClickableText
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowForward
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.outlined.SportsEsports
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.gamestack.app.model.Game
import kotlinx.coroutines.delay

@Composable
fun WelcomeScreen(vm: GameViewModel, onGetStarted: () -> Unit, onSignIn: () -> Unit) {
    val covers = vm.trending
    var cycle by remember { mutableIntStateOf(0) }
    LaunchedEffect(covers.size) {
        if (covers.size > 3) while (true) {
            delay(4000)
            cycle++
        }
    }
    val transition = rememberInfiniteTransition(label = "welcome")
    val floatA by transition.animateFloat(-6f, 6f, infiniteRepeatable(tween(2700, easing = FastOutSlowInEasing), RepeatMode.Reverse), label = "a")
    val floatB by transition.animateFloat(5f, -5f, infiniteRepeatable(tween(3300, easing = FastOutSlowInEasing), RepeatMode.Reverse), label = "b")
    val floatC by transition.animateFloat(-4f, 7f, infiniteRepeatable(tween(2900, easing = FastOutSlowInEasing), RepeatMode.Reverse), label = "c")
    fun gameAt(offset: Int): Game? = if (covers.isEmpty()) null else covers[(cycle + offset) % covers.size]

    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
        BrandBar()
        BoxWithConstraints(Modifier.fillMaxWidth().entrance(0)) {
            val s = maxWidth.value / 393f
            Box(Modifier.fillMaxWidth().height((319 * s).dp)) {
                OrbitRing(s)
                PlacedCover(gameAt(1), vm.trendingLoaded, 116.3f, 151.3f, 139f, 201f, -13f, s) { floatB }
                PlacedCover(gameAt(2), vm.trendingLoaded, 280.6f, 153.3f, 132f, 202f, 13f, s) { floatC }
                PlacedCover(gameAt(0), vm.trendingLoaded, 199.9f, 142.1f, 175f, 247f, -4f, s) { floatA }
                PlacedChip(245.3f, 34.7f, 88.1f, 35.4f, 5f, s, { floatB }) {
                    Row(Modifier.clip(RoundedCornerShape(100.dp)).background(LimeSoft).padding(horizontal = 11.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        Icon(Icons.Filled.PlayArrow, null, Modifier.size(11.dp), tint = OnLime)
                        Text("PLAYING", color = OnLime, fontSize = 10.sp, fontWeight = FontWeight.ExtraBold, letterSpacing = 0.7.sp)
                    }
                }
                PlacedChip(92.5f, 264.6f, 125f, 38.6f, -5f, s, { floatC }) {
                    Row(Modifier.clip(RoundedCornerShape(100.dp)).background(Panel).border(1.dp, Border, RoundedCornerShape(100.dp))
                        .padding(horizontal = 11.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        Icon(Icons.Outlined.Add, null, Modifier.size(12.dp), tint = Ink)
                        Text("WANT TO PLAY", color = Ink, fontSize = 10.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 0.6.sp)
                    }
                }
            }
        }
        Column(Modifier.padding(start = 28.dp, end = 28.dp, top = 9.dp), verticalArrangement = Arrangement.spacedBy(15.dp)) {
            Text("DISCOVER · COLLECT · PLAY", color = LimeSoft, fontSize = 10.sp, letterSpacing = 1.9.sp,
                fontWeight = FontWeight.SemiBold, modifier = Modifier.entrance(1))
            Text("Your games, all in one place.", color = Ink, fontSize = 36.sp, lineHeight = 40.sp,
                letterSpacing = (-1.4).sp, modifier = Modifier.entrance(2))
            Text("Discover new games, build your library, and keep track of what you’ve played, what you’re playing, and what’s next.",
                color = Ink2, fontSize = 15.sp, lineHeight = 24.sp, modifier = Modifier.entrance(3))
        }
        Column(Modifier.padding(start = 28.dp, end = 28.dp, top = 32.dp).entrance(4), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            PrimaryButton("Get started", onGetStarted, Modifier.fillMaxWidth(), color = LimeSoft, trailingIcon = Icons.AutoMirrored.Outlined.ArrowForward)
            Box(Modifier.fillMaxWidth().height(44.dp).bounceClick(onClick = onSignIn), contentAlignment = Alignment.Center) {
                Text("I already have an account", color = Ink2, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
            }
        }
        Row(Modifier.align(Alignment.CenterHorizontally).padding(top = 32.dp, bottom = 16.dp), horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(width = 18.dp, height = 4.dp).clip(RoundedCornerShape(100.dp)).background(LimeSoft))
            Box(Modifier.size(4.dp).clip(RoundedCornerShape(100.dp)).background(Border))
            Box(Modifier.size(4.dp).clip(RoundedCornerShape(100.dp)).background(Border))
        }
    }
}

@Composable
private fun OrbitRing(s: Float) {
    androidx.compose.foundation.Canvas(Modifier.fillMaxSize()) {
        val w = 331f * s * density
        val h = 264f * s * density
        val cx = (31f + 371.8f / 2f) * s * density
        val cy = (-29.5f + 317.5f / 2f) * s * density
        rotate(-10f, pivot = Offset(cx, cy)) {
            drawOval(Lime.copy(alpha = 0.22f), topLeft = Offset(cx - w / 2f, cy - h / 2f), size = Size(w, h), style = Stroke(width = 1.dp.toPx()))
        }
    }
}

@Composable
private fun PlacedCover(game: Game?, loaded: Boolean, cx: Float, cy: Float, w: Float, h: Float, rotation: Float, s: Float, floatY: () -> Float) {
    val shape = RoundedCornerShape(14.dp)
    Box(Modifier.offset(((cx - w / 2f) * s).dp, ((cy - h / 2f) * s).dp).size((w * s).dp, (h * s).dp)
        .graphicsLayer { translationY = floatY().dp.toPx(); rotationZ = rotation }
        .shadow(16.dp, shape, ambientColor = Color.Black, spotColor = Color.Black).clip(shape).background(Panel).border(1.dp, Border, shape)) {
        Crossfade(targetState = game?.coverUrl, animationSpec = tween(700), label = "cover") { url ->
            when {
                url != null -> CoverImage(url, null, Modifier.fillMaxSize())
                !loaded -> Box(Modifier.fillMaxSize().shimmer())
                else -> Box(Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(LimeDeep, Panel))), contentAlignment = Alignment.Center) {
                    Icon(Icons.Outlined.SportsEsports, null, Modifier.size(34.dp), tint = Lime.copy(alpha = 0.7f))
                }
            }
        }
        Box(Modifier.fillMaxSize().background(Brush.verticalGradient(0.45f to Color.Transparent, 1f to Bg.copy(alpha = 0.95f))))
    }
}

@Composable
private fun PlacedChip(cx: Float, cy: Float, w: Float, h: Float, rotation: Float, s: Float, floatY: () -> Float, content: @Composable () -> Unit) {
    Box(Modifier.offset(((cx - w / 2f) * s).dp, ((cy - h / 2f) * s).dp).size((w * s).dp, (h * s).dp)
        .graphicsLayer { translationY = floatY().dp.toPx(); rotationZ = rotation }, contentAlignment = Alignment.Center) {
        content()
    }
}

@Composable
private fun GoogleMark(modifier: Modifier = Modifier) {
    androidx.compose.foundation.Canvas(modifier) {
        val stroke = size.width * 0.19f
        val inset = stroke / 2f
        val arcSize = Size(size.width - stroke, size.height - stroke)
        val topLeft = Offset(inset, inset)
        val style = Stroke(width = stroke, cap = StrokeCap.Butt)
        drawArc(Color(0xFFFBBC05), 135f, 90f, false, topLeft, arcSize, style = style)
        drawArc(Color(0xFFEA4335), 225f, 80f, false, topLeft, arcSize, style = style)
        drawArc(Color(0xFF34A853), 45f, 90f, false, topLeft, arcSize, style = style)
        drawArc(Color(0xFF4285F4), -30f, 75f, false, topLeft, arcSize, style = style)
        drawLine(Color(0xFF4285F4), Offset(size.width / 2f, size.height / 2f), Offset(size.width - inset, size.height / 2f), strokeWidth = stroke)
    }
}

@Composable
fun AuthScreen(vm: GameViewModel, mode: String, onMode: (String) -> Unit, onGoogle: () -> Unit) {
    var email by rememberSaveable { mutableStateOf("") }
    var password by rememberSaveable { mutableStateOf("") }
    var nickname by rememberSaveable { mutableStateOf("") }
    val submit = {
        if (!vm.busy) {
            val problem = when {
                mode == "signup" && nickname.trim().length < 2 -> "Choose a nickname with at least 2 characters."
                !email.contains('@') -> "Enter a valid email address."
                mode != "reset" && password.length < 6 -> "Your password needs at least 6 characters."
                else -> null
            }
            if (problem != null) vm.notify(problem) else when (mode) {
                "signup" -> vm.signUp(email, password, nickname)
                "reset" -> vm.resetPassword(email)
                else -> vm.login(email, password)
            }
        }
    }

    Column(Modifier.fillMaxSize().imePadding()) {
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState())) {
            BrandBar()
            Column(Modifier.padding(start = 28.dp, end = 28.dp, top = 60.dp)) {
                Text(when (mode) { "signup" -> "Create account"; "reset" -> "Reset password"; else -> "Welcome back," },
                    color = Ink, fontSize = 36.sp, lineHeight = 40.sp, letterSpacing = (-1.4).sp, modifier = Modifier.entrance(0))
                Column(Modifier.padding(top = 36.dp), verticalArrangement = Arrangement.spacedBy(22.dp)) {
                    if (mode == "signup") FormField("Nickname", nickname, { nickname = it }, "Choose a nickname", Modifier.entrance(1))
                    FormField("Email", email, { email = it }, "Enter your email", Modifier.entrance(2), keyboardType = KeyboardType.Email,
                        imeAction = if (mode == "reset") ImeAction.Done else ImeAction.Next, onDone = { submit() })
                    if (mode != "reset") FormField("Password", password, { password = it },
                        if (mode == "signup") "Create a password" else "Enter your password", Modifier.entrance(3),
                        password = true, keyboardType = KeyboardType.Password, imeAction = ImeAction.Done, onDone = { submit() })
                }
                if (mode == "login") Box(Modifier.fillMaxWidth().height(52.dp), contentAlignment = Alignment.CenterEnd) {
                    Text("Forgot password?", color = LimeSoft, fontSize = 13.sp, fontWeight = FontWeight.Medium,
                        modifier = Modifier.clickable { onMode("reset") })
                } else Spacer(Modifier.height(28.dp))
                Column(Modifier.padding(top = if (mode == "login") 8.dp else 0.dp), verticalArrangement = Arrangement.spacedBy(28.dp)) {
                    PrimaryButton(when (mode) { "signup" -> "Create account"; "reset" -> "Send recovery email"; else -> "Log in" },
                        { submit() }, Modifier.fillMaxWidth().entrance(4), loading = vm.busy, color = LimeSoft)
                    if (mode != "reset") Column(verticalArrangement = Arrangement.spacedBy(24.dp)) {
                        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                            HorizontalDivider(Modifier.weight(1f), color = Border)
                            Text("OR", color = Muted, fontSize = 11.sp, fontWeight = FontWeight.Medium, letterSpacing = 1.sp)
                            HorizontalDivider(Modifier.weight(1f), color = Border)
                        }
                        SecondaryButton("Continue with Google", onGoogle, Modifier.fillMaxWidth(), !vm.busy, height = 56.dp, radius = 18.dp,
                            fontSize = 15.sp, weight = FontWeight.SemiBold, leading = { GoogleMark(Modifier.size(20.dp)) })
                    }
                }
                Spacer(Modifier.height(24.dp))
            }
        }
        if (mode != "reset") {
            val prompt = if (mode == "login") "Don’t have an account? " else "Already have an account? "
            val action = if (mode == "login") "Sign up" else "Log in"
            val text = buildAnnotatedString {
                withStyle(SpanStyle(color = Ink2)) { append(prompt) }
                withStyle(SpanStyle(color = LimeSoft, fontWeight = FontWeight.SemiBold)) { append(action) }
                withStyle(SpanStyle(color = Ink2)) { append(".") }
            }
            ClickableText(text, Modifier.align(Alignment.CenterHorizontally).padding(top = 8.dp, bottom = 28.dp),
                style = TextStyle(fontSize = 13.sp, lineHeight = 20.sp, textAlign = TextAlign.Center, fontFamily = Inter)) {
                onMode(if (mode == "login") "signup" else "login")
            }
        } else {
            Text("Back to log in", color = LimeSoft, fontSize = 13.sp, fontWeight = FontWeight.SemiBold,
                modifier = Modifier.align(Alignment.CenterHorizontally).clickable { onMode("login") }.padding(top = 8.dp, bottom = 28.dp))
        }
    }
}
