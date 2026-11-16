package com.gamestack.app.ui

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.*
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.gamestack.app.model.*
import kotlin.math.roundToInt

@Composable
fun DetailScreen(game: Game, saved: Boolean, isBusy: Boolean, backLabel: String,
                 onBack: () -> Unit, onSave: (Game) -> Unit, onRemove: (Game) -> Unit) {
    var status by remember(game.rawgId, game.status) { mutableStateOf(game.status) }
    var horror by remember(game.rawgId, game.isHorror) { mutableStateOf(game.isHorror) }
    var hasRating by remember(game.rawgId, game.rating) { mutableStateOf(game.rating != null) }
    var rating by remember(game.rawgId, game.rating) { mutableFloatStateOf(game.rating ?: 8f) }
    var confirmDelete by remember { mutableStateOf(false) }
    val uriHandler = LocalUriHandler.current

    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
        Row(Modifier.fillMaxWidth().height(52.dp).padding(horizontal = 20.dp).bounceClick(onClick = onBack),
            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            Box(Modifier.size(width = 40.dp, height = 44.dp), contentAlignment = Alignment.Center) {
                Icon(Icons.AutoMirrored.Outlined.ArrowBack, "Back", Modifier.size(20.dp), tint = Ink)
            }
            Text(backLabel, color = Ink2, fontSize = 14.sp)
        }
        Column(Modifier.padding(start = 28.dp, end = 28.dp, top = 8.dp, bottom = 28.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.entrance(0)) {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(18.dp)) {
                    CoverImage(game.coverUrl, "Artwork for ${game.title}", Modifier.size(112.dp).clip(RoundedCornerShape(12.dp)))
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        if (saved) Text("IN YOUR COLLECTION", color = Lime, fontSize = 9.sp, letterSpacing = 1.1.sp, fontWeight = FontWeight.SemiBold)
                        Text(game.title, color = Ink, fontSize = 34.sp, lineHeight = 38.sp, letterSpacing = (-1.4).sp,
                            maxLines = 2, overflow = TextOverflow.Ellipsis)
                        game.releaseDate?.take(4)?.let { Text(it, color = Ink2, fontSize = 13.sp, lineHeight = 18.sp) }
                        if (game.genres.isNotEmpty()) Text(game.genres.take(3).joinToString(" · "), color = Muted, fontSize = 12.sp,
                            lineHeight = 18.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    }
                }
                if (game.description.isNotBlank()) Text(game.description, color = Ink2, fontSize = 13.sp, lineHeight = 20.sp,
                    maxLines = 2, overflow = TextOverflow.Ellipsis)
            }
            Column(verticalArrangement = Arrangement.spacedBy(20.dp), modifier = Modifier.entrance(1)) {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    SectionLabel("Where are you at?")
                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        GameStatus.entries.forEach { option -> StatusOption(option.label, status == option) { status = option } }
                    }
                }
                Row(Modifier.fillMaxWidth().height(72.dp).clip(RoundedCornerShape(14.dp)).background(Panel)
                    .border(1.dp, Border, RoundedCornerShape(14.dp)).clickable { horror = !horror }.padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text("Horror game", color = Ink, fontSize = 14.sp, fontWeight = FontWeight.Medium)
                        Text("Turn on to filter it as Horror in your library.", color = Muted, fontSize = 11.sp, lineHeight = 15.sp)
                    }
                    Toggle(horror) { horror = it }
                }
                Column(Modifier.animateContentSize(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Row(Modifier.fillMaxWidth().height(28.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        CheckBox(hasRating) { hasRating = it }
                        Text("My rating", color = Ink, fontSize = 14.sp, fontWeight = FontWeight.Medium, modifier = Modifier.weight(1f))
                        if (hasRating) Text(buildAnnotatedString {
                            withStyle(SpanStyle(color = Lime, fontSize = 24.sp, fontWeight = FontWeight.SemiBold, letterSpacing = (-0.8).sp)) { append("%.1f".format(rating)) }
                            withStyle(SpanStyle(color = Muted, fontSize = 12.sp)) { append(" / 10") }
                        })
                    }
                    if (hasRating) {
                        RatingSlider(rating) { rating = it }
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text("0", color = Muted, fontSize = 10.sp, lineHeight = 14.sp)
                            Text("10", color = Muted, fontSize = 10.sp, lineHeight = 14.sp)
                        }
                    }
                }
            }
            Column(verticalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.entrance(2)) {
                PrimaryButton(if (saved) "Update game" else "Add to library", {
                    onSave(game.copy(status = status, isHorror = horror, rating = if (hasRating) rating else null))
                }, Modifier.fillMaxWidth(), enabled = !isBusy, loading = isBusy, height = 50.dp, fontSize = 15.sp, weight = FontWeight.SemiBold)
                if (saved) SecondaryButton("Remove from collection", { confirmDelete = true }, Modifier.fillMaxWidth(), !isBusy,
                    contentColor = Ink2, height = 46.dp, radius = 18.dp)
                Text(buildAnnotatedString {
                    append("Game data by ")
                    withStyle(SpanStyle(fontWeight = FontWeight.SemiBold)) { append("RAWG") }
                    append(" · ")
                    withStyle(SpanStyle(textDecoration = TextDecoration.Underline)) { append("rawg.io") }
                }, color = Muted, fontSize = 10.sp, lineHeight = 18.sp, textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth().clickable { uriHandler.openUri("https://rawg.io/") })
            }
        }
    }

    if (confirmDelete) ConfirmDialog("Remove ${game.title}?", "You can add it again any time.", "Remove",
        onConfirm = { confirmDelete = false; onRemove(game) }, onDismiss = { confirmDelete = false }, danger = true)
}

@Composable
private fun StatusOption(label: String, selected: Boolean, onClick: () -> Unit) {
    val background by animateColorAsState(if (selected) LimeDeep else Panel, tween(200), label = "optionBg")
    val borderColor by animateColorAsState(if (selected) Lime else Border, tween(200), label = "optionBorder")
    val ring by animateColorAsState(if (selected) Lime else Muted, tween(200), label = "ring")
    val dot by animateDpAsState(if (selected) 8.dp else 0.dp, tween(200), label = "dot")
    Row(Modifier.fillMaxWidth().height(44.dp).bounceClick(onClick = onClick).clip(RoundedCornerShape(14.dp)).background(background)
        .border(1.dp, borderColor, RoundedCornerShape(14.dp)).padding(horizontal = 14.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Box(Modifier.size(18.dp).border(1.5.dp, ring, CircleShape), contentAlignment = Alignment.Center) {
            Box(Modifier.size(dot).clip(CircleShape).background(Lime))
        }
        Text(label, color = if (selected) Lime else Ink, fontSize = 14.sp, fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal)
    }
}

@Composable
private fun Toggle(checked: Boolean, onChange: (Boolean) -> Unit) {
    val track by animateColorAsState(if (checked) Lime else Bg, tween(200), label = "track")
    val borderColor by animateColorAsState(if (checked) Lime else Border, tween(200), label = "trackBorder")
    val thumb by animateColorAsState(if (checked) OnLime else Muted, tween(200), label = "thumb")
    val offset by animateDpAsState(if (checked) 20.dp else 4.dp, tween(200), label = "thumbOffset")
    Box(Modifier.size(width = 42.dp, height = 26.dp).clip(RoundedCornerShape(100.dp)).background(track)
        .border(1.dp, borderColor, RoundedCornerShape(100.dp)).clickable { onChange(!checked) }) {
        Box(Modifier.padding(start = offset - 1.dp).align(Alignment.CenterStart).size(18.dp).clip(CircleShape).background(thumb))
    }
}

@Composable
private fun CheckBox(checked: Boolean, onChange: (Boolean) -> Unit) {
    val background by animateColorAsState(if (checked) Lime else Color.Transparent, tween(160), label = "check")
    val borderColor by animateColorAsState(if (checked) Lime else Muted, tween(160), label = "checkBorder")
    Box(Modifier.size(18.dp).clip(RoundedCornerShape(5.dp)).background(background).border(1.5.dp, borderColor, RoundedCornerShape(5.dp))
        .clickable { onChange(!checked) }, contentAlignment = Alignment.Center) {
        if (checked) Icon(Icons.Outlined.Check, null, Modifier.size(12.dp), tint = OnLime)
    }
}

@Composable
private fun RatingSlider(value: Float, onChange: (Float) -> Unit) {
    BoxWithConstraints(Modifier.fillMaxWidth().height(28.dp)
        .pointerInput(Unit) {
            detectTapGestures { offset -> onChange(((offset.x / size.width * 10f).coerceIn(0f, 10f) * 2f).roundToInt() / 2f) }
        }
        .pointerInput(Unit) {
            detectHorizontalDragGestures { change, _ -> onChange(((change.position.x / size.width * 10f).coerceIn(0f, 10f) * 2f).roundToInt() / 2f) }
        }) {
        val width = maxWidth
        val thumbLeft = (width * (value / 10f) - 9.dp).coerceIn(0.dp, width - 18.dp)
        Box(Modifier.align(Alignment.CenterStart).fillMaxWidth().height(4.dp).clip(RoundedCornerShape(100.dp)).background(Border))
        Box(Modifier.align(Alignment.CenterStart).width(thumbLeft).height(4.dp).clip(RoundedCornerShape(100.dp)).background(Lime))
        Box(Modifier.align(Alignment.CenterStart).padding(start = thumbLeft).size(18.dp).shadow(2.dp, CircleShape).clip(CircleShape).background(Lime))
    }
}
