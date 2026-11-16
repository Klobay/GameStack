package com.gamestack.app.ui

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.SearchOff
import androidx.compose.material.icons.outlined.WifiOff
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.gamestack.app.model.DiscoverFilter
import kotlinx.coroutines.delay

@Composable
fun DiscoverScreen(vm: GameViewModel) {
    var query by rememberSaveable { mutableStateOf("") }
    val focus = LocalFocusManager.current

    LaunchedEffect(query) {
        if (query.isNotBlank()) delay(450)
        if (query.isBlank() || query.trim().length >= 2) vm.discover(query)
    }

    Column(Modifier.fillMaxSize()) {
        BrandBar()
        Column(Modifier.padding(start = 28.dp, end = 28.dp, top = 10.dp, bottom = 20.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            ScreenTitle("Discover")
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                SearchBar(query, { query = it }, "Search games", onSearch = { focus.clearFocus(); vm.discover(query) })
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    DiscoverFilter.entries.forEach { filter ->
                        FilterChip(filter.label, vm.discoverFilter == filter) { vm.discover(query, filter) }
                    }
                }
            }
        }
        when {
            vm.results.isEmpty() && vm.discoverFailed && !vm.searching -> EmptyState(Icons.Outlined.WifiOff, "Can't reach the catalogue",
                "Check your connection and try again.") {
                PrimaryButton("Try again", { vm.discover(query) }, Modifier.fillMaxWidth(), height = 50.dp, fontSize = 15.sp, weight = FontWeight.SemiBold)
            }
            vm.results.isEmpty() && (vm.searching || !vm.trendingLoaded) -> SkeletonGrid(3)
            vm.results.isEmpty() -> EmptyState(Icons.Outlined.SearchOff, "No games found", "Try a different title or pick another filter.")
            else -> LazyVerticalGrid(columns = GridCells.Fixed(2),
                contentPadding = PaddingValues(start = 28.dp, end = 28.dp, bottom = 28.dp),
                verticalArrangement = Arrangement.spacedBy(20.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                itemsIndexed(vm.results, key = { _, game -> game.rawgId }) { index, game ->
                    val saved = vm.games.any { it.rawgId == game.rawgId }
                    GameTile(game, { focus.clearFocus(); vm.openGame(game) }, Modifier.entrance(index), detailSpacing = 4.dp) {
                        Row(Modifier.fillMaxWidth().height(20.dp), verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                            GameTitle(game.title, Modifier.weight(1f))
                            val tint by animateColorAsState(if (saved) Lime else Ink2, tween(220), label = "add")
                            Box(Modifier.size(20.dp).bounceClick(!saved) { vm.quickAdd(game) }, contentAlignment = Alignment.Center) {
                                Icon(if (saved) Icons.Outlined.Check else Icons.Outlined.Add,
                                    if (saved) "In your library" else "Add to library", Modifier.size(12.dp), tint = tint)
                            }
                        }
                        Text(listOfNotNull(game.releaseDate?.take(4)).plus(game.genres.take(2).joinToString(" ")).filter { it.isNotBlank() }
                            .joinToString(" · ").ifEmpty { "Video game" },
                            color = Muted, fontSize = 11.sp, lineHeight = 16.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    }
                }
            }
        }
    }
}
