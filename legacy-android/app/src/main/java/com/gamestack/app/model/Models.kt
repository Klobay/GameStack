package com.gamestack.app.model

import org.json.JSONArray
import org.json.JSONObject

enum class GameStatus(val raw: String, val label: String) {
    PLAYED("played", "Played"),
    PLAYING("currently_playing", "Currently playing"),
    WISHLIST("want_to_play", "Want to play");
    companion object { fun from(value: String) = entries.firstOrNull { it.raw == value } ?: WISHLIST }
}

enum class Category(val label: String) { ALL("All games"), HORROR("Horror games"), OTHER("Other games") }
enum class MainTab { LIBRARY, DISCOVER, PROFILE }

enum class DiscoverFilter(val label: String) {
    ALL("All"), HORROR("Horror"), OTHER("Other")
}

data class AuthSession(val accessToken: String, val refreshToken: String, val userId: String, val email: String,
                       val expiresAt: Long)
data class Profile(val nickname: String = "Player", val avatarUrl: String? = null)

data class Game(
    val rawgId: Long,
    val title: String,
    val coverUrl: String?,
    val description: String = "",
    val releaseDate: String? = null,
    val genres: List<String> = emptyList(),
    val status: GameStatus = GameStatus.WISHLIST,
    val isHorror: Boolean = false,
    val rating: Float? = null,
    val entryId: String? = null,
) {
    companion object {
        fun fromSearch(obj: JSONObject) = Game(
            rawgId = obj.optLong("id"),
            title = obj.optString("name", "Unknown game"),
            coverUrl = obj.optString("background_image").takeIf { it.startsWith("https://") },
            description = obj.optString("description_raw", ""),
            releaseDate = obj.optString("released").takeIf { it.isNotBlank() && it != "null" },
            genres = obj.optJSONArray("genres").namesList("name"),
            isHorror = obj.optJSONArray("tags").namesList("slug").any { it.contains("horror") }
        )
        fun fromSaved(obj: JSONObject): Game = Game(
            rawgId = obj.getLong("rawg_game_id"),
            title = obj.optString("game_title", "Unknown game"),
            coverUrl = obj.optString("cover_url").takeIf { it.startsWith("https://") },
            description = obj.optString("description", ""),
            releaseDate = obj.optString("release_date").takeIf { it.isNotBlank() && it != "null" },
            genres = obj.optJSONArray("genres").strings(),
            status = GameStatus.from(obj.optString("status")),
            isHorror = obj.optBoolean("is_horror", false),
            rating = if (obj.isNull("personal_rating")) null else obj.optDouble("personal_rating").toFloat(),
            entryId = obj.optString("id")
        )
    }
}

fun JSONArray?.strings(): List<String> = if (this == null) emptyList() else (0 until length()).mapNotNull { index -> optString(index).takeIf { it.isNotBlank() } }
fun JSONArray?.namesList(field: String): List<String> = if (this == null) emptyList() else (0 until length()).mapNotNull { index -> optJSONObject(index)?.optString(field)?.takeIf { it.isNotBlank() } }
fun List<String>.toJsonArray(): JSONArray = JSONArray().also { target -> forEach { target.put(it) } }
