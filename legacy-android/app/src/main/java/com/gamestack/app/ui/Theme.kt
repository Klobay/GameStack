package com.gamestack.app.ui

import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import com.gamestack.app.R
import androidx.compose.ui.unit.sp

val Bg = Color(0xFF101211)
val Panel = Color(0xFF1C201D)
val Border = Color(0xFF343B34)
val Ink = Color(0xFFF3F5ED)
val Ink2 = Color(0xFFD7DBD4)
val Muted = Color(0xFF929A90)
val Lime = Color(0xFFB9F35A)
val LimeDeep = Color(0xFF26351C)
val OnLime = Color(0xFF18210F)
val LimeSoft = Color(0xFFC4F568)
val Teal = Color(0xFF2DD4BF)
val Danger = Color(0xFFF08080)
val DangerBorder = Color(0xFF9E4C4C)

val Inter = FontFamily(
    Font(R.font.inter_regular, FontWeight.Normal),
    Font(R.font.inter_medium, FontWeight.Medium),
    Font(R.font.inter_semibold, FontWeight.SemiBold),
    Font(R.font.inter_bold, FontWeight.Bold),
    Font(R.font.inter_extrabold, FontWeight.ExtraBold)
)

private val scheme = darkColorScheme(
    primary = Lime, onPrimary = OnLime,
    secondary = Lime, onSecondary = OnLime,
    background = Bg, onBackground = Ink,
    surface = Bg, onSurface = Ink,
    surfaceVariant = Panel, onSurfaceVariant = Muted,
    surfaceContainer = Panel, surfaceContainerHigh = Panel,
    outline = Border, outlineVariant = Border,
    error = Danger,
    inverseSurface = Panel, inverseOnSurface = Ink
)

private val base = Typography()
private val typography = Typography(
    displayLarge = base.displayLarge.copy(fontFamily = Inter), displayMedium = base.displayMedium.copy(fontFamily = Inter),
    displaySmall = base.displaySmall.copy(fontFamily = Inter),
    headlineLarge = base.headlineLarge.copy(fontFamily = Inter, fontSize = 34.sp, fontWeight = FontWeight.Normal, letterSpacing = (-1.4).sp),
    headlineMedium = base.headlineMedium.copy(fontFamily = Inter), headlineSmall = base.headlineSmall.copy(fontFamily = Inter),
    titleLarge = base.titleLarge.copy(fontFamily = Inter),
    titleMedium = base.titleMedium.copy(fontFamily = Inter, fontSize = 15.sp, lineHeight = 20.sp, fontWeight = FontWeight.SemiBold, letterSpacing = (-0.3).sp),
    titleSmall = base.titleSmall.copy(fontFamily = Inter),
    bodyLarge = base.bodyLarge.copy(fontFamily = Inter), bodyMedium = base.bodyMedium.copy(fontFamily = Inter),
    bodySmall = base.bodySmall.copy(fontFamily = Inter),
    labelLarge = base.labelLarge.copy(fontFamily = Inter), labelMedium = base.labelMedium.copy(fontFamily = Inter),
    labelSmall = base.labelSmall.copy(fontFamily = Inter)
)

@Composable
fun GameStackTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = scheme, typography = typography, content = content)
}
