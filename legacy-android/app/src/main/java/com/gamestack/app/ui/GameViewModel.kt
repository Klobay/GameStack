package com.gamestack.app.ui

import android.app.Application
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import com.gamestack.app.data.Backend
import com.gamestack.app.data.SecureSessionStore
import com.gamestack.app.model.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream

class GameViewModel(application: Application) : AndroidViewModel(application) {
    private val store = SecureSessionStore(application)
    private val backend = Backend(store)

    var initializing by androidx.compose.runtime.mutableStateOf(true); private set
    var session by androidx.compose.runtime.mutableStateOf<AuthSession?>(null); private set
    var profile by androidx.compose.runtime.mutableStateOf(Profile()); private set
    var games by androidx.compose.runtime.mutableStateOf<List<Game>>(emptyList()); private set
    var results by androidx.compose.runtime.mutableStateOf<List<Game>>(emptyList()); private set
    var tab by androidx.compose.runtime.mutableStateOf(MainTab.LIBRARY)
    var category by androidx.compose.runtime.mutableStateOf(Category.ALL)
    var selectedGame by androidx.compose.runtime.mutableStateOf<Game?>(null)
    var busy by androidx.compose.runtime.mutableStateOf(false); private set
    var searching by androidx.compose.runtime.mutableStateOf(false); private set
    var message by androidx.compose.runtime.mutableStateOf<String?>(null); private set
    var info by androidx.compose.runtime.mutableStateOf<String?>(null); private set

    var trending by androidx.compose.runtime.mutableStateOf<List<Game>>(emptyList()); private set
    var trendingLoaded by androidx.compose.runtime.mutableStateOf(false); private set

    init {
        viewModelScope.launch {
            try { trending = backend.discover("", DiscoverFilter.ALL).filter { it.coverUrl != null }; if (results.isEmpty()) results = trending } catch (_: Exception) { }
            trendingLoaded = true
        }
        viewModelScope.launch {
            val existing = store.read()
            if (existing != null) {
                try { session = backend.fresh(existing); refresh() }
                catch (e: Exception) { store.clear(); message = "Please sign in again: ${friendly(e)}" }
            }
            initializing = false
        }
    }

    private fun friendly(e: Throwable): String = when {
        e is java.io.InterruptedIOException || e.message == "timeout" -> "The game catalogue is taking too long to respond. Please try again."
        e is java.net.UnknownHostException || e is java.net.ConnectException -> "No connection. Check your internet and try again."
        else -> e.message?.take(220) ?: "Something went wrong. Please try again."
    }
    fun notify(text: String) { message = text }
    fun clearMessage() { message = null; info = null }
    private fun fail(e: Throwable) { message = friendly(e) }

    private suspend fun validSession(): AuthSession {
        val current = session ?: error("Please sign in")
        return backend.fresh(current).also { session = it }
    }

    private suspend fun refresh() {
        val s = validSession()
        val fetched = backend.loadGames(s)
        val account = backend.loadProfile(s)
        games = fetched
        profile = account
    }

    fun reload() = viewModelScope.launch { busy = true; try { refresh() } catch (e: Exception) { fail(e) } finally { busy = false } }

    fun login(email: String, password: String) = viewModelScope.launch {
        busy = true; clearMessage()
        try { session = backend.login(email.trim(), password); refresh(); tab = MainTab.LIBRARY }
        catch (e: Exception) { fail(e) } finally { busy = false }
    }

    fun signUp(email: String, password: String, nickname: String) = viewModelScope.launch {
        busy = true; clearMessage()
        try {
            val loggedIn = backend.signUp(email.trim(), password, nickname.trim())
            if (loggedIn) { session = store.read(); refresh() }
            else info = "Account created! Check your inbox for the confirmation email, then log in."
        } catch (e: Exception) { fail(e) } finally { busy = false }
    }

    fun resetPassword(email: String) = viewModelScope.launch {
        busy = true; clearMessage()
        try { backend.sendReset(email.trim()); info = "If that address is registered, a recovery email has been sent." }
        catch (e: Exception) { fail(e) } finally { busy = false }
    }

    fun googleUrl(): String = backend.googleSignInUrl()
    fun finishGoogle(uri: Uri) = viewModelScope.launch {
        busy = true; clearMessage()
        try { session = backend.finishGoogleSignIn(uri); refresh(); tab = MainTab.LIBRARY }
        catch (e: Exception) { fail(e) } finally { busy = false }
    }

    fun logout() = viewModelScope.launch {
        busy = true
        try { backend.logout(session) } catch (_: Exception) { store.clear() }
        session = null; games = emptyList(); results = emptyList(); profile = Profile(); selectedGame = null
        busy = false
    }

    var discoverFailed by androidx.compose.runtime.mutableStateOf(false); private set
    var discoverFilter by androidx.compose.runtime.mutableStateOf(DiscoverFilter.ALL); private set
    private var discoverJob: kotlinx.coroutines.Job? = null

    fun discover(term: String, filter: DiscoverFilter = discoverFilter) {
        discoverFilter = filter
        val clean = term.trim()
        if (clean.isNotEmpty() && clean.length < 2) return
        discoverJob?.cancel()
        if (clean.isEmpty() && filter == DiscoverFilter.ALL && trending.isNotEmpty()) {
            results = trending
            searching = false
            return
        }
        discoverJob = viewModelScope.launch {
            searching = true
            discoverFailed = false
            try { results = backend.discover(clean, filter) }
            catch (e: kotlinx.coroutines.CancellationException) { throw e }
            catch (e: Exception) { discoverFailed = true; fail(e) }
            finally { searching = false }
        }
    }

    fun quickAdd(game: Game) = viewModelScope.launch {
        try {
            backend.saveGame(validSession(), game.copy(status = GameStatus.WISHLIST))
            games = backend.loadGames(validSession())
            info = "${game.title} added to your library"
        } catch (e: Exception) { fail(e) }
    }

    fun openGame(game: Game) {
        selectedGame = games.firstOrNull { it.rawgId == game.rawgId } ?: game
        if (game.description.isBlank()) viewModelScope.launch {
            try {
                val full = backend.detail(game.rawgId)
                if (selectedGame?.rawgId == game.rawgId) {
                    selectedGame = selectedGame?.copy(
                        description = full.description,
                        genres = full.genres.ifEmpty { selectedGame?.genres ?: emptyList() },
                        coverUrl = full.coverUrl ?: selectedGame?.coverUrl,
                        releaseDate = full.releaseDate ?: selectedGame?.releaseDate
                    )
                }
            } catch (_: Exception) { }
        }
    }

    fun closeGame() { selectedGame = null }

    fun save(game: Game) = viewModelScope.launch {
        busy = true; clearMessage()
        try {
            backend.saveGame(validSession(), game)
            games = backend.loadGames(validSession())
            selectedGame = null
            info = "Saved to your collection"
        } catch (e: Exception) { fail(e) } finally { busy = false }
    }

    fun remove(game: Game) = viewModelScope.launch {
        busy = true; clearMessage()
        try {
            backend.deleteGame(validSession(), game.rawgId)
            games = backend.loadGames(validSession())
            selectedGame = null
            info = "Game removed"
        } catch (e: Exception) { fail(e) } finally { busy = false }
    }

    fun deleteAccount() = viewModelScope.launch {
        busy = true; clearMessage()
        try {
            backend.deleteAccount(validSession())
            session = null; games = emptyList(); results = emptyList(); profile = Profile(); selectedGame = null
        } catch (e: Exception) { fail(e) } finally { busy = false }
    }

    fun updateNickname(nickname: String) = viewModelScope.launch {
        if (nickname.trim().length !in 2..32) { message = "Nickname must be 2–32 characters."; return@launch }
        busy = true; clearMessage()
        try {
            backend.updateProfile(validSession(), nickname.trim())
            profile = profile.copy(nickname = nickname.trim())
            info = "Nickname updated"
        } catch (e: Exception) { fail(e) } finally { busy = false }
    }

    fun uploadAvatar(uri: Uri) = viewModelScope.launch {
        busy = true; clearMessage()
        try {
            val bytes = withContext(Dispatchers.IO) {
                val cr = getApplication<Application>().contentResolver
                val original = cr.openInputStream(uri)?.use { BitmapFactory.decodeStream(it) }
                    ?: throw IllegalArgumentException("Could not read that image")
                val ratio = minOf(1f, 768f / maxOf(original.width, original.height))
                val resized = Bitmap.createScaledBitmap(original, (original.width * ratio).toInt().coerceAtLeast(1),
                    (original.height * ratio).toInt().coerceAtLeast(1), true)
                val out = ByteArrayOutputStream()
                resized.compress(Bitmap.CompressFormat.JPEG, 82, out)
                if (resized !== original) resized.recycle()
                original.recycle()
                out.toByteArray()
            }
            val s = validSession()
            val newAvatar = backend.uploadAvatar(s, bytes)
            backend.updateProfile(s, profile.nickname, newAvatar)
            profile = profile.copy(avatarUrl = newAvatar)
            info = "Profile picture updated"
        } catch (e: Exception) { fail(e) } finally { busy = false }
    }
}
