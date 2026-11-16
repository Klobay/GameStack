package com.gamestack.app.ui

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateIntAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CollectionsBookmark
import androidx.compose.material.icons.outlined.FilterAlt
import androidx.compose.material.icons.outlined.SearchOff
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.gamestack.app.model.*

@Composable
fun LibraryScreen(vm: GameViewModel) {
    var query by rememberSaveable { mutableStateOf("") }
    var statusRaw by rememberSaveable { mutableStateOf("") }
    val status = GameStatus.entries.firstOrNull { it.raw == statusRaw }
    val horrorOnly = vm.category == Category.HORROR
    val all = vm.games
    val filtered = all.filter { game ->
        (!horrorOnly || game.isHorror) &&
            (status == null || game.status == status) &&
            (query.isBlank() || game.title.contains(query.trim(), ignoreCase = true))
    }

    Column(Modifier.fillMaxSize()) {
        BrandBar()
        when {
            all.isEmpty() && vm.busy -> {
                ScreenTitle("My library", Modifier.padding(start = 28.dp, end = 28.dp, top = 10.dp, bottom = 20.dp))
                SkeletonGrid()
            }
            all.isEmpty() -> {
                ScreenTitle("My library", Modifier.padding(start = 28.dp, end = 28.dp, top = 10.dp))
                EmptyState(Icons.Outlined.CollectionsBookmark, "Your library is empty",
                    "Search the catalogue and add games you've played, are playing, or want to play.",
                    Modifier.padding(top = 40.dp)) {
                    PrimaryButton("Discover games", { vm.tab = MainTab.DISCOVER }, Modifier.fillMaxWidth(), height = 50.dp, fontSize = 15.sp, weight = FontWeight.SemiBold)
                }
            }
            else -> LazyVerticalGrid(columns = GridCells.Fixed(2),
                contentPadding = PaddingValues(start = 28.dp, end = 28.dp, top = 10.dp, bottom = 28.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                item(span = { GridItemSpan(maxLineSpan) }) {
                    Column(Modifier.padding(bottom = 4.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                        ScreenTitle("My library")
                        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            SearchBar(query, { query = it }, "Search your games")
                            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                                Box {
                                    Row(Modifier.fillMaxWidth().height(92.dp).clip(RoundedCornerShape(18.dp)).background(Panel)
                                        .border(1.dp, Border, RoundedCornerShape(18.dp)).padding(12.dp),
                                        horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                                        SummaryTile(all.size, "ALL", status == null, Modifier.weight(1f)) { statusRaw = "" }
                                        SummaryTile(all.count { it.status == GameStatus.PLAYING }, "PLAYING", status == GameStatus.PLAYING, Modifier.weight(1f)) { statusRaw = GameStatus.PLAYING.raw }
                                        SummaryTile(all.count { it.status == GameStatus.PLAYED }, "PLAYED", status == GameStatus.PLAYED, Modifier.weight(1f)) { statusRaw = GameStatus.PLAYED.raw }
                                        SummaryTile(all.count { it.status == GameStatus.WISHLIST }, "WISHLIST", status == GameStatus.WISHLIST, Modifier.weight(1f)) { statusRaw = GameStatus.WISHLIST.raw }
                                    }
                                    Box(Modifier.align(Alignment.CenterEnd).padding(end = 11.dp).size(width = 4.dp, height = 24.dp)
                                        .clip(RoundedCornerShape(100.dp)).background(Lime))
                                }
                                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
                                    Text("${filtered.size} ${if (filtered.size == 1) "GAME" else "GAMES"}", color = Ink2, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                                    val chipBackground by animateColorAsState(if (horrorOnly) LimeDeep else Panel, tween(200), label = "horror")
                                    val chipBorder by animateColorAsState(if (horrorOnly) Lime else Border, tween(200), label = "horrorBorder")
                                    Row(Modifier.bounceClick { vm.category = if (horrorOnly) Category.ALL else Category.HORROR }
                                        .clip(RoundedCornerShape(100.dp)).background(chipBackground).border(1.dp, chipBorder, RoundedCornerShape(100.dp))
                                        .padding(horizontal = 10.dp, vertical = 6.dp),
                                        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                        Icon(Icons.Outlined.FilterAlt, null, Modifier.size(12.dp), tint = if (horrorOnly) Lime else Ink2)
                                        Text("Horror only", color = if (horrorOnly) Lime else Ink2, fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
                                    }
                                }
                            }
                        }
                    }
                }
                if (filtered.isEmpty()) item(span = { GridItemSpan(maxLineSpan) }) {
                    EmptyState(Icons.Outlined.SearchOff, "No games match", "Try a different search, status or category.") {
                        SecondaryButton("Clear filters", { query = ""; statusRaw = ""; vm.category = Category.ALL }, Modifier.fillMaxWidth(), height = 48.dp)
                    }
                }
                itemsIndexed(filtered, key = { _, game -> game.rawgId }) { index, game ->
                    GameTile(game, { vm.openGame(game) }, Modifier.entrance(index)) {
                        GameTitle(game.title)
                        StatusTag(game.status)
                    }
                }
            }
        }
    }
}

@Composable
private fun SummaryTile(count: Int, label: String, selected: Boolean, modifier: Modifier = Modifier, onClick: () -> Unit) {
    val background by animateColorAsState(if (selected) Ink else Bg, tween(220), label = "tile")
    val numberColor by animateColorAsState(if (selected) OnLime else Ink2, tween(220), label = "number")
    val labelColor by animateColorAsState(if (selected) OnLime else Muted, tween(220), label = "label")
    val shown by animateIntAsState(count, tween(600), label = "count")
    Column(modifier.height(68.dp).bounceClick(onClick = onClick).clip(RoundedCornerShape(12.dp)).background(background),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(2.dp, Alignment.CenterVertically)) {
        Text("$shown", color = numberColor, fontSize = 20.sp, fontWeight = FontWeight.Bold, maxLines = 1)
        Text(label, color = labelColor, fontSize = 10.sp, fontWeight = FontWeight.SemiBold, maxLines = 1)
    }
}
