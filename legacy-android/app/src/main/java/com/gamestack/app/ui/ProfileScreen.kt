package com.gamestack.app.ui

import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.animation.core.tween
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.Logout
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.PhotoCamera
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.gamestack.app.model.GameStatus

@Composable
fun ProfileScreen(vm: GameViewModel) {
    var editing by rememberSaveable { mutableStateOf(false) }
    BackHandler(editing) { editing = false }
    AnimatedContent(targetState = editing, label = "profile",
        transitionSpec = {
            if (targetState) (slideInHorizontally(tween(280)) { it / 5 } + fadeIn(tween(280))) togetherWith (slideOutHorizontally(tween(280)) { -it / 5 } + fadeOut(tween(160)))
            else (slideInHorizontally(tween(280)) { -it / 5 } + fadeIn(tween(280))) togetherWith (slideOutHorizontally(tween(280)) { it / 5 } + fadeOut(tween(160)))
        }) { isEditing ->
        if (isEditing) EditProfile(vm) { editing = false } else ProfileOverview(vm) { editing = true }
    }
}

@Composable
private fun Avatar(vm: GameViewModel, size: Dp, textSize: Int) {
    val initials = vm.profile.nickname.trim().split(" ").filter { it.isNotEmpty() }.take(2)
        .joinToString("") { it.first().uppercase() }.ifEmpty { "?" }
    Box(Modifier.size(size).clip(CircleShape).background(LimeDeep).border(1.dp, Lime, CircleShape), contentAlignment = Alignment.Center) {
        if (vm.profile.avatarUrl != null) AsyncImage(vm.profile.avatarUrl, "Profile picture", Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
        else Text(initials, color = Lime, fontSize = textSize.sp, fontWeight = FontWeight.SemiBold, letterSpacing = (-0.7).sp)
    }
}

@Composable
private fun ProfileOverview(vm: GameViewModel, onEdit: () -> Unit) {
    var confirmLogout by remember { mutableStateOf(false) }
    var confirmDelete by remember { mutableStateOf(false) }
    val games = vm.games

    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
        BrandBar(height = 52.dp)
        Column(Modifier.padding(start = 28.dp, end = 28.dp, bottom = 28.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Box(Modifier.fillMaxWidth().height(201.dp)) {
                ScreenTitle("Profile", Modifier.entrance(0))
                Row(Modifier.padding(top = 46.dp).fillMaxWidth().height(80.dp).padding(top = 4.dp).entrance(1),
                    verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                    Avatar(vm, 68.dp, 23)
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(vm.profile.nickname, color = Ink, fontSize = 22.sp, fontWeight = FontWeight.SemiBold, letterSpacing = (-0.6).sp,
                            maxLines = 1, overflow = TextOverflow.Ellipsis)
                        Text(vm.session?.email ?: "", color = Muted, fontSize = 13.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    }
                }
                SecondaryButton("Edit profile", onEdit, Modifier.padding(top = 142.dp).fillMaxWidth().entrance(2), icon = Icons.Outlined.Edit,
                    contentColor = Lime, background = Panel, height = 44.dp, weight = FontWeight.SemiBold, iconSize = 15.dp)
            }
            Column(verticalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.padding(bottom = 10.dp).entrance(3)) {
                SectionLabel("My stats")
                Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(Panel)
                    .border(1.dp, Border, RoundedCornerShape(18.dp)).padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    StatRow("Total", games.size)
                    HorizontalDivider(color = Border)
                    StatRow("Played", games.count { it.status == GameStatus.PLAYED })
                    HorizontalDivider(color = Border)
                    StatRow("Playing", games.count { it.status == GameStatus.PLAYING })
                    HorizontalDivider(color = Border)
                    StatRow("Horror games played", games.count { it.isHorror && it.status == GameStatus.PLAYED })
                    HorizontalDivider(color = Border)
                    StatRow("Wishlist", games.count { it.status == GameStatus.WISHLIST })
                }
            }
            Column(verticalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.entrance(4)) {
                SectionLabel("Account")
                SecondaryButton("Log out", { confirmLogout = true }, Modifier.fillMaxWidth(), !vm.busy, background = Panel,
                    icon = Icons.AutoMirrored.Outlined.Logout)
                Column(Modifier.fillMaxWidth().drawBehind {
                    drawLine(Border, Offset(0f, 0f), Offset(size.width, 0f), strokeWidth = 1.dp.toPx())
                }.padding(top = 8.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text("Deleting your account permanently removes your profile and game library.", color = Muted, fontSize = 11.sp, lineHeight = 15.sp)
                    SecondaryButton("Delete account", { confirmDelete = true }, Modifier.fillMaxWidth(), !vm.busy,
                        icon = Icons.Outlined.DeleteOutline, contentColor = Danger, borderColor = DangerBorder)
                }
            }
        }
    }

    if (confirmLogout) ConfirmDialog("Log out?", "Your game collection stays safely in your account.", "Log out",
        onConfirm = { confirmLogout = false; vm.logout() }, onDismiss = { confirmLogout = false })
    if (confirmDelete) ConfirmDialog("Delete your account?", "This permanently removes your profile and every game in your library. This can't be undone.",
        "Delete", onConfirm = { confirmDelete = false; vm.deleteAccount() }, onDismiss = { confirmDelete = false }, danger = true)
}

@Composable
private fun StatRow(label: String, count: Int) {
    Row(Modifier.fillMaxWidth().height(26.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, color = Ink, fontSize = 13.sp, fontWeight = FontWeight.Medium)
        Text("$count", color = Ink2, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
    }
}

@Composable
private fun EditProfile(vm: GameViewModel, onClose: () -> Unit) {
    var name by rememberSaveable { mutableStateOf(vm.profile.nickname) }
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        if (uri != null) vm.uploadAvatar(uri)
    }
    val changed = name.trim() != vm.profile.nickname && name.trim().length in 2..32

    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).imePadding()) {
        Row(Modifier.fillMaxWidth().height(52.dp).padding(horizontal = 20.dp).bounceClick(onClick = onClose),
            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            Box(Modifier.size(width = 40.dp, height = 44.dp), contentAlignment = Alignment.Center) {
                Icon(Icons.AutoMirrored.Outlined.ArrowBack, "Back", Modifier.size(20.dp), tint = Ink)
            }
            Text("Profile", color = Ink2, fontSize = 14.sp)
        }
        Column(Modifier.padding(start = 28.dp, end = 28.dp, top = 8.dp, bottom = 28.dp)) {
            ScreenTitle("Edit profile", Modifier.entrance(0))
            Column(Modifier.fillMaxWidth().padding(top = 32.dp).entrance(1), horizontalAlignment = Alignment.CenterHorizontally) {
                Avatar(vm, 88.dp, 30)
                Row(Modifier.padding(top = 14.dp).height(32.dp).bounceClick(!vm.busy) {
                    picker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                }, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Icon(Icons.Outlined.PhotoCamera, null, Modifier.size(16.dp), tint = Lime)
                    Text("Change photo", color = Lime, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                }
            }
            Column(Modifier.padding(top = 36.dp), verticalArrangement = Arrangement.spacedBy(24.dp)) {
                FormField("Display name", name, { name = it }, "Your nickname", Modifier.entrance(2), labelSize = 13.sp)
                FormField("Email", vm.session?.email ?: "", {}, "", Modifier.entrance(3), readOnly = true, labelSize = 13.sp)
            }
            PrimaryButton("Save changes", { vm.updateNickname(name); onClose() }, Modifier.padding(top = 32.dp).fillMaxWidth().entrance(4),
                enabled = changed && !vm.busy, height = 54.dp, fontSize = 15.sp, weight = FontWeight.SemiBold)
        }
    }
}
