package com.gamestack.app.ui

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import coil.request.ImageRequest
import com.gamestack.app.model.Game
import com.gamestack.app.model.GameStatus
import com.gamestack.app.model.MainTab
import kotlinx.coroutines.delay

fun Modifier.bounceClick(enabled: Boolean = true, onClick: () -> Unit): Modifier = composed {
    val source = remember { MutableInteractionSource() }
    val pressed by source.collectIsPressedAsState()
    val scale by animateFloatAsState(if (pressed) 0.96f else 1f, spring(stiffness = Spring.StiffnessMedium), label = "press")
    this.graphicsLayer { scaleX = scale; scaleY = scale }
        .clickable(interactionSource = source, indication = null, enabled = enabled, onClick = onClick)
}

fun Modifier.shimmer(): Modifier = composed {
    val transition = rememberInfiniteTransition(label = "shimmer")
    val x by transition.animateFloat(-500f, 1400f, infiniteRepeatable(tween(1300, easing = LinearEasing)), label = "x")
    this.drawBehind {
        drawRect(Brush.linearGradient(listOf(Panel, Color(0xFF283029), Panel), start = Offset(x, 0f), end = Offset(x + 420f, 220f)))
    }
}

fun Modifier.entrance(index: Int = 0): Modifier = composed {
    val animate = index < 9
    val progress = remember { Animatable(if (animate) 0f else 1f) }
    LaunchedEffect(Unit) {
        if (animate) {
            delay(index * 50L)
            progress.animateTo(1f, tween(420, easing = FastOutSlowInEasing))
        }
    }
    this.graphicsLayer { alpha = progress.value; translationY = (1f - progress.value) * 40f }
}

@Composable
fun AmbientBackground(top: Boolean, modifier: Modifier = Modifier, content: @Composable BoxScope.() -> Unit) {
    val transition = rememberInfiniteTransition(label = "ambient")
    val drift by transition.animateFloat(0f, 1f, infiniteRepeatable(tween(9000, easing = LinearEasing), RepeatMode.Reverse), label = "drift")
    val limeY by animateFloatAsState(if (top) 0.17f else 0.365f, tween(600), label = "limeY")
    val limeX by animateFloatAsState(if (top) 0.35f else 0.36f, tween(600), label = "limeX")
    val tealY by animateFloatAsState(if (top) 0.36f else 0.55f, tween(600), label = "tealY")
    Box(modifier.fillMaxSize().background(Bg).drawBehind {
        val w = size.width
        val h = size.height
        drawRect(Brush.radialGradient(listOf(Lime.copy(alpha = 0.10f), Color.Transparent),
            center = Offset(w * (limeX + 0.03f * drift), h * (limeY + 0.015f * drift)), radius = w * 0.52f))
        drawRect(Brush.radialGradient(listOf(Teal.copy(alpha = 0.085f), Color.Transparent),
            center = Offset(w * (0.8f - 0.03f * drift), h * (tealY - 0.015f * drift)), radius = w * 0.5f))
        drawRect(Brush.radialGradient(listOf(Lime.copy(alpha = 0.05f), Color.Transparent),
            center = Offset(w * 0.5f, h * 1.01f), radius = w * 0.7f))
    }, content = content)
}

@Composable
fun StackMark(modifier: Modifier = Modifier) {
    androidx.compose.foundation.Canvas(modifier) {
        val w = size.width
        val h = size.height
        fun layer(top: Float, alpha: Float) {
            val path = Path().apply {
                moveTo(w / 2f, top)
                lineTo(w - 1f, top + h * 0.18f)
                lineTo(w / 2f, top + h * 0.36f)
                lineTo(1f, top + h * 0.18f)
                close()
            }
            drawPath(path, Lime.copy(alpha = alpha), style = Stroke(width = 2.dp.toPx(), join = StrokeJoin.Round))
        }
        layer(h * 0.56f, 0.45f)
        layer(h * 0.28f, 0.75f)
        layer(0f, 1f)
    }
}

@Composable
fun BrandBar(modifier: Modifier = Modifier, height: Dp = 64.dp) {
    Row(modifier.fillMaxWidth().height(height).padding(horizontal = 28.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        StackMark(Modifier.size(width = 25.dp, height = 28.dp))
        Text("GameStack", color = Ink, fontSize = 19.sp, letterSpacing = (-0.6).sp)
    }
}

@Composable
fun ScreenTitle(text: String, modifier: Modifier = Modifier) {
    Box(modifier.fillMaxWidth().height(44.dp), contentAlignment = Alignment.CenterStart) {
        Text(text, color = Ink, fontSize = 34.sp, letterSpacing = (-1.4).sp, maxLines = 1)
    }
}

@Composable
fun SectionLabel(text: String, modifier: Modifier = Modifier) {
    Text(text.uppercase(), modifier = modifier, color = Muted, fontSize = 10.sp, lineHeight = 14.sp, letterSpacing = 1.5.sp,
        fontWeight = FontWeight.SemiBold)
}

@Composable
fun PrimaryButton(text: String, onClick: () -> Unit, modifier: Modifier = Modifier, enabled: Boolean = true,
                  loading: Boolean = false, trailingIcon: ImageVector? = null, color: Color = Lime,
                  height: Dp = 56.dp, fontSize: TextUnit = 16.sp, weight: FontWeight = FontWeight.Bold) {
    val background by animateColorAsState(if (enabled) color else Panel, tween(200), label = "primary")
    Box(modifier.bounceClick(enabled && !loading, onClick).height(height).clip(RoundedCornerShape(18.dp)).background(background),
        contentAlignment = Alignment.Center) {
        if (loading) CircularProgressIndicator(Modifier.size(20.dp), color = OnLime, strokeWidth = 2.dp)
        else {
            Text(text, color = if (enabled) OnLime else Muted, fontWeight = weight, fontSize = fontSize)
            if (trailingIcon != null) Icon(trailingIcon, null, Modifier.align(Alignment.CenterEnd).padding(end = 21.dp).size(19.dp),
                tint = if (enabled) OnLime else Muted)
        }
    }
}

@Composable
fun SecondaryButton(text: String, onClick: () -> Unit, modifier: Modifier = Modifier, enabled: Boolean = true,
                    icon: ImageVector? = null, contentColor: Color = Ink, borderColor: Color = Border,
                    height: Dp = 48.dp, radius: Dp = 14.dp, background: Color = Color.Transparent,
                    fontSize: TextUnit = 14.sp, weight: FontWeight = FontWeight.Medium, iconSize: Dp = 17.dp,
                    leading: @Composable (() -> Unit)? = null) {
    val shape = RoundedCornerShape(radius)
    Row(modifier.bounceClick(enabled, onClick).height(height).clip(shape).background(background)
        .border(1.dp, borderColor, shape).alpha(if (enabled) 1f else 0.5f),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.Center) {
        if (leading != null) { leading(); Spacer(Modifier.width(12.dp)) }
        if (icon != null) { Icon(icon, null, Modifier.size(iconSize), tint = contentColor); Spacer(Modifier.width(8.dp)) }
        Text(text, color = contentColor, fontWeight = weight, fontSize = fontSize)
    }
}

@Composable
fun FormField(label: String, value: String, onValueChange: (String) -> Unit, placeholder: String,
              modifier: Modifier = Modifier, enabled: Boolean = true, password: Boolean = false,
              keyboardType: KeyboardType = KeyboardType.Text, imeAction: ImeAction = ImeAction.Next,
              onDone: (() -> Unit)? = null, readOnly: Boolean = false, labelSize: TextUnit = 14.sp) {
    var focused by remember { mutableStateOf(false) }
    val borderColor by animateColorAsState(if (focused) Lime else Border, tween(180), label = "field")
    Column(modifier.fillMaxWidth()) {
        Text(label, color = Ink, fontSize = labelSize, fontWeight = FontWeight.Medium)
        Spacer(Modifier.height(10.dp))
        Row(Modifier.fillMaxWidth().height(56.dp).clip(RoundedCornerShape(14.dp)).background(Panel)
            .border(1.dp, borderColor, RoundedCornerShape(14.dp)).padding(horizontal = 16.dp),
            verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.weight(1f), contentAlignment = Alignment.CenterStart) {
                if (value.isEmpty()) Text(placeholder, color = Muted, fontSize = 15.sp)
                BasicTextField(value, onValueChange, enabled = enabled, readOnly = readOnly, singleLine = true,
                    textStyle = TextStyle(color = Ink, fontSize = 15.sp, fontFamily = Inter),
                    cursorBrush = SolidColor(Lime),
                    visualTransformation = if (password) PasswordVisualTransformation() else VisualTransformation.None,
                    keyboardOptions = KeyboardOptions(keyboardType = keyboardType, imeAction = imeAction),
                    keyboardActions = KeyboardActions(onDone = { onDone?.invoke() }),
                    modifier = Modifier.fillMaxWidth().onFocusChanged { focused = it.isFocused })
            }
        }
    }
}

@Composable
fun SearchBar(value: String, onValueChange: (String) -> Unit, placeholder: String, modifier: Modifier = Modifier,
              onSearch: (() -> Unit)? = null) {
    var focused by remember { mutableStateOf(false) }
    val borderColor by animateColorAsState(if (focused) Lime else Border, tween(180), label = "search")
    Row(modifier.fillMaxWidth().height(48.dp).clip(RoundedCornerShape(14.dp)).background(Panel)
        .border(1.dp, borderColor, RoundedCornerShape(14.dp)).padding(horizontal = 14.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Icon(Icons.Outlined.Search, null, Modifier.size(18.dp), tint = Muted)
        Box(Modifier.weight(1f), contentAlignment = Alignment.CenterStart) {
            if (value.isEmpty()) Text(placeholder, color = Muted, fontSize = 14.sp)
            BasicTextField(value, onValueChange, singleLine = true, textStyle = TextStyle(color = Ink, fontSize = 14.sp, fontFamily = Inter),
                cursorBrush = SolidColor(Lime),
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                keyboardActions = KeyboardActions(onSearch = { onSearch?.invoke() }),
                modifier = Modifier.fillMaxWidth().onFocusChanged { focused = it.isFocused })
        }
        if (value.isNotEmpty()) Icon(Icons.Outlined.Close, "Clear", Modifier.size(18.dp).clickable { onValueChange("") }, tint = Muted)
    }
}

@Composable
fun FilterChip(label: String, selected: Boolean, onClick: () -> Unit) {
    val background by animateColorAsState(if (selected) Lime else Panel, tween(200), label = "chip")
    val foreground by animateColorAsState(if (selected) OnLime else Ink2, tween(200), label = "chipText")
    Box(Modifier.bounceClick(onClick = onClick).height(32.dp).clip(RoundedCornerShape(50)).background(background)
        .border(1.dp, if (selected) Lime else Border, RoundedCornerShape(50)).padding(horizontal = 16.dp),
        contentAlignment = Alignment.Center) {
        Text(label, color = foreground, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
    }
}

@Composable
fun StatusTag(status: GameStatus) {
    val playing = status == GameStatus.PLAYING
    val icon = when (status) {
        GameStatus.PLAYING -> Icons.Outlined.PlayArrow
        GameStatus.PLAYED -> Icons.Outlined.Check
        GameStatus.WISHLIST -> Icons.Outlined.BookmarkBorder
    }
    val label = when (status) {
        GameStatus.PLAYING -> "Playing"
        GameStatus.PLAYED -> "Played"
        GameStatus.WISHLIST -> "Want to play"
    }
    Row(Modifier.height(20.dp).clip(RoundedCornerShape(6.dp)).background(if (playing) LimeDeep else Panel).padding(horizontal = 7.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
        Icon(icon, null, Modifier.size(10.dp), tint = if (playing) Lime else Ink2)
        Text(label, color = if (playing) Lime else Ink2, fontSize = 10.sp, fontWeight = FontWeight.SemiBold)
    }
}

@Composable
fun CoverImage(url: String?, description: String?, modifier: Modifier = Modifier) {
    Box(modifier.background(Panel), contentAlignment = Alignment.Center) {
        if (url != null) AsyncImage(
            model = ImageRequest.Builder(LocalContext.current).data(url).crossfade(350).build(),
            contentDescription = description, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
        else Icon(Icons.Outlined.SportsEsports, null, Modifier.size(30.dp), tint = Muted)
    }
}

@Composable
fun GameTile(game: Game, onClick: () -> Unit, modifier: Modifier = Modifier, detailSpacing: Dp = 6.dp,
             details: @Composable ColumnScope.() -> Unit) {
    Column(modifier.bounceClick(onClick = onClick), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        CoverImage(game.coverUrl, "Artwork for ${game.title}", Modifier.fillMaxWidth().height(164.dp).clip(RoundedCornerShape(12.dp)))
        Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(detailSpacing), content = details)
    }
}

@Composable
fun GameTitle(text: String, modifier: Modifier = Modifier) {
    Text(text, modifier = modifier, color = Ink, maxLines = 1, overflow = TextOverflow.Ellipsis, style = MaterialTheme.typography.titleMedium)
}

@Composable
fun SkeletonGrid(rows: Int = 2, modifier: Modifier = Modifier) {
    Column(modifier.fillMaxWidth().padding(horizontal = 28.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        repeat(rows) {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                repeat(2) {
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Box(Modifier.fillMaxWidth().height(164.dp).clip(RoundedCornerShape(12.dp)).shimmer())
                        Box(Modifier.width(96.dp).height(14.dp).clip(RoundedCornerShape(5.dp)).shimmer())
                        Box(Modifier.width(60.dp).height(12.dp).clip(RoundedCornerShape(5.dp)).shimmer())
                    }
                }
            }
        }
    }
}

@Composable
fun EmptyState(icon: ImageVector, title: String, detail: String, modifier: Modifier = Modifier, action: @Composable (() -> Unit)? = null) {
    val transition = rememberInfiniteTransition(label = "empty")
    val pulse by transition.animateFloat(1f, 1.08f, infiniteRepeatable(tween(1800, easing = FastOutSlowInEasing), RepeatMode.Reverse), label = "pulse")
    Column(modifier.fillMaxWidth().padding(horizontal = 36.dp, vertical = 36.dp).entrance(0),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Box(Modifier.size(72.dp).graphicsLayer { scaleX = pulse; scaleY = pulse }.clip(CircleShape).background(LimeDeep),
            contentAlignment = Alignment.Center) {
            Icon(icon, null, Modifier.size(32.dp), tint = Lime)
        }
        Spacer(Modifier.height(4.dp))
        Text(title, color = Ink, fontSize = 20.sp, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center)
        Text(detail, color = Muted, fontSize = 14.sp, lineHeight = 22.sp, textAlign = TextAlign.Center)
        if (action != null) {
            Spacer(Modifier.height(8.dp))
            action()
        }
    }
}

@Composable
fun ConfirmDialog(title: String, text: String, confirmLabel: String, onConfirm: () -> Unit, onDismiss: () -> Unit, danger: Boolean = false) {
    AlertDialog(onDismissRequest = onDismiss, containerColor = Panel, shape = RoundedCornerShape(22.dp),
        title = { Text(title, color = Ink, fontWeight = FontWeight.SemiBold) },
        text = { Text(text, color = Muted) },
        confirmButton = { TextButton(onClick = onConfirm) { Text(confirmLabel, color = if (danger) Danger else Lime, fontWeight = FontWeight.Bold) } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel", color = Ink2) } })
}

@Composable
fun BottomNav(selected: MainTab, onSelect: (MainTab) -> Unit) {
    Column(Modifier.fillMaxWidth().background(Bg)) {
        HorizontalDivider(color = Border)
        Row(Modifier.navigationBarsPadding().height(64.dp).padding(start = 28.dp, end = 28.dp, top = 8.dp)) {
            listOf(
                MainTab.LIBRARY to "Library",
                MainTab.DISCOVER to "Discover",
                MainTab.PROFILE to "Profile"
            ).forEach { (tab, label) ->
                val active = selected == tab
                val pill by animateColorAsState(if (active) LimeDeep else Color.Transparent, tween(220), label = "pill")
                val tint by animateColorAsState(if (active) Lime else Muted, tween(220), label = "tint")
                Column(Modifier.weight(1f).bounceClick { onSelect(tab) }, horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Box(Modifier.size(width = 52.dp, height = 28.dp).clip(RoundedCornerShape(50)).background(pill), contentAlignment = Alignment.Center) {
                        NavGlyph(tab, tint, Modifier.size(21.dp))
                    }
                    Text(label, color = tint, fontSize = 11.sp, fontWeight = if (active) FontWeight.SemiBold else FontWeight.Medium)
                }
            }
        }
    }
}

@Composable
fun NavGlyph(tab: MainTab, tint: Color, modifier: Modifier = Modifier) {
    androidx.compose.foundation.Canvas(modifier) {
        val k = size.width / 24f
        val stroke = Stroke(width = 2f * k, cap = androidx.compose.ui.graphics.StrokeCap.Round, join = StrokeJoin.Round)
        fun line(x1: Float, y1: Float, x2: Float, y2: Float) =
            drawLine(tint, Offset(x1 * k, y1 * k), Offset(x2 * k, y2 * k), strokeWidth = 2f * k, cap = androidx.compose.ui.graphics.StrokeCap.Round)
        when (tab) {
            MainTab.LIBRARY -> {
                line(16f, 6f, 20f, 20f)
                line(12f, 6f, 12f, 20f)
                line(8f, 8f, 8f, 20f)
                line(4f, 4f, 4f, 20f)
            }
            MainTab.DISCOVER -> {
                drawCircle(tint, radius = 10f * k, center = Offset(12f * k, 12f * k), style = stroke)
                val needle = Path().apply {
                    moveTo(16.24f * k, 7.76f * k)
                    lineTo(14.12f * k, 14.12f * k)
                    lineTo(7.76f * k, 16.24f * k)
                    lineTo(9.88f * k, 9.88f * k)
                    close()
                }
                drawPath(needle, tint, style = stroke)
            }
            MainTab.PROFILE -> {
                drawCircle(tint, radius = 5f * k, center = Offset(12f * k, 8f * k), style = stroke)
                drawArc(tint, 180f, 180f, false, Offset(4f * k, 13f * k), androidx.compose.ui.geometry.Size(16f * k, 16f * k), style = stroke)
            }
        }
    }
}
