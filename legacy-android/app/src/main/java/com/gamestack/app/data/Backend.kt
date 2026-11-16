package com.gamestack.app.data

import android.net.Uri
import com.gamestack.app.BuildConfig
import com.gamestack.app.model.AuthSession
import com.gamestack.app.model.DiscoverFilter
import com.gamestack.app.model.Game
import com.gamestack.app.model.GameStatus
import com.gamestack.app.model.Profile
import com.gamestack.app.model.strings
import com.gamestack.app.model.toJsonArray
import org.json.JSONArray
import org.json.JSONObject
import java.security.MessageDigest
import java.security.SecureRandom
import android.util.Base64
import java.net.URLEncoder

class Backend(private val store: SecureSessionStore) {
    private fun enc(value: String) = URLEncoder.encode(value, "UTF-8")

    private fun session(json: JSONObject): AuthSession {
        val user = json.optJSONObject("user") ?: throw ApiException("Could not retrieve account details")
        val session = AuthSession(
            json.getString("access_token"), json.getString("refresh_token"),
            user.getString("id"), user.optString("email"),
            System.currentTimeMillis() + json.optLong("expires_in", 3600) * 1000
        )
        store.write(session)
        return session
    }

    suspend fun login(email: String, password: String): AuthSession = session(Http.auth("token?grant_type=password",
        JSONObject().put("email", email).put("password", password)))

    suspend fun signUp(email: String, password: String, nickname: String): Boolean {
        val json = Http.auth("signup", JSONObject().put("email", email).put("password", password)
            .put("data", JSONObject().put("nickname", nickname)))
        val hasSession = json.has("access_token") && !json.isNull("access_token")
        if (hasSession) session(json)
        return hasSession
    }

    suspend fun sendReset(email: String) {
        Http.auth("recover", JSONObject().put("email", email))
    }

    fun googleSignInUrl(): String {
        val raw = ByteArray(48).also { SecureRandom().nextBytes(it) }
        val verifier = Base64.encodeToString(raw, Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING)
        store.savePkce(verifier)
        val hash = MessageDigest.getInstance("SHA-256").digest(verifier.toByteArray(Charsets.US_ASCII))
        val challenge = Base64.encodeToString(hash, Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING)
        return Http.url("/auth/v1/authorize?provider=google&redirect_to=${enc("gamestack://auth-callback")}" +
            "&code_challenge=$challenge&code_challenge_method=s256")
    }

    suspend fun finishGoogleSignIn(uri: Uri): AuthSession {
        val error = uri.getQueryParameter("error_description") ?: uri.getQueryParameter("error")
        if (error != null) throw ApiException(error)
        val code = uri.getQueryParameter("code") ?: throw ApiException("Google did not return an authorization code. Check the Supabase redirect allowlist.")
        val verifier = store.takePkce() ?: throw ApiException("Login session expired. Try Google login again.")
        return session(Http.auth("token?grant_type=pkce", JSONObject().put("auth_code", code).put("code_verifier", verifier)))
    }

    suspend fun fresh(current: AuthSession): AuthSession {
        if (current.expiresAt > System.currentTimeMillis() + 60_000) return current
        return session(Http.auth("token?grant_type=refresh_token", JSONObject().put("refresh_token", current.refreshToken)))
    }

    suspend fun logout(current: AuthSession?) {
        if (current != null) runCatching {
            Http.request(Http.url("/auth/v1/logout"), "POST", current.accessToken)
        }
        store.clear()
    }

    suspend fun loadProfile(session: AuthSession): Profile {
        val json = Http.rows("profiles", "select=nickname,avatar_url&id=eq.${enc(session.userId)}", session.accessToken)
            .optJSONObject(0)
        return Profile(json?.optString("nickname", "Player") ?: "Player",
            json?.optString("avatar_url")?.takeIf { it.startsWith("https://") })
    }

    suspend fun updateProfile(session: AuthSession, nickname: String, avatarUrl: String? = null) {
        val body = JSONObject().put("nickname", nickname)
        if (avatarUrl != null) body.put("avatar_url", avatarUrl)
        Http.request(Http.url("/rest/v1/profiles?id=eq.${enc(session.userId)}"), "PATCH", session.accessToken,
            body.toString(), headers = mapOf("Prefer" to "return=minimal"))
    }

    suspend fun uploadAvatar(session: AuthSession, image: ByteArray): String {
        val path = "${session.userId}/avatar.jpg"
        Http.request(Http.url("/storage/v1/object/avatars/$path"), "POST", session.accessToken,
            contentType = "image/jpeg", bytes = image, headers = mapOf("x-upsert" to "true"))
        return Http.url("/storage/v1/object/public/avatars/$path?v=${System.currentTimeMillis()}")
    }

    suspend fun loadGames(session: AuthSession): List<Game> {
        val json = Http.rows("user_games", "select=*&order=added_at.desc", session.accessToken)
        return (0 until json.length()).map { Game.fromSaved(json.getJSONObject(it)) }
    }

    suspend fun saveGame(session: AuthSession, game: Game): Unit {
        val body = JSONObject().put("user_id", session.userId).put("rawg_game_id", game.rawgId)
            .put("game_title", game.title).put("cover_url", game.coverUrl ?: JSONObject.NULL)
            .put("description", game.description.take(12_000)).put("release_date", game.releaseDate ?: JSONObject.NULL)
            .put("genres", game.genres.toJsonArray()).put("status", game.status.raw).put("is_horror", game.isHorror)
            .put("personal_rating", game.rating?.toDouble() ?: JSONObject.NULL)
        Http.request(Http.url("/rest/v1/user_games?on_conflict=user_id,rawg_game_id"), "POST", session.accessToken,
            body.toString(), headers = mapOf("Prefer" to "resolution=merge-duplicates,return=minimal"))
    }

    suspend fun deleteGame(session: AuthSession, rawgId: Long) {
        Http.request(Http.url("/rest/v1/user_games?user_id=eq.${enc(session.userId)}&rawg_game_id=eq.$rawgId"),
            "DELETE", session.accessToken)
    }

    suspend fun deleteAccount(session: AuthSession) {
        Http.request(Http.url("/rest/v1/rpc/delete_my_account"), "POST", session.accessToken, "{}")
        store.clear()
    }

    private suspend fun rawg(url: String): String =
        try { Http.request(url, authenticated = false) }
        catch (e: java.io.InterruptedIOException) { Http.request(url, authenticated = false) }

    suspend fun discover(term: String, filter: DiscoverFilter): List<Game> {
        val query = StringBuilder("key=${BuildConfig.RAWG_API_KEY}&page_size=24")
        if (term.isNotBlank()) query.append("&search=${enc(term)}") else query.append("&ordering=-added")
        if (filter == DiscoverFilter.HORROR) query.append("&tags=horror")
        val response = rawg("https://api.rawg.io/api/games?$query")
        val results = JSONObject(response).optJSONArray("results") ?: JSONArray()
        val games = (0 until results.length()).map { Game.fromSearch(results.getJSONObject(it)) }
        return if (filter == DiscoverFilter.OTHER) games.filter { !it.isHorror } else games
    }

    suspend fun detail(rawgId: Long): Game {
        val response = rawg("https://api.rawg.io/api/games/$rawgId?key=${BuildConfig.RAWG_API_KEY}")
        return Game.fromSearch(JSONObject(response))
    }
}
