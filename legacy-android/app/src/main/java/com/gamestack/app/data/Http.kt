package com.gamestack.app.data

import com.gamestack.app.BuildConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.Dns
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import java.net.Inet6Address
import java.net.InetAddress
import java.util.concurrent.TimeUnit

class ApiException(message: String, val status: Int = -1) : IOException(message)

object Http {
    private val host = BuildConfig.SUPABASE_URL.trimEnd('/')
    private val client = OkHttpClient.Builder()
        .dns(object : Dns {
            override fun lookup(hostname: String): List<InetAddress> =
                Dns.SYSTEM.lookup(hostname).sortedBy { it is Inet6Address }
        })
        .connectTimeout(8, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .callTimeout(45, TimeUnit.SECONDS)
        .build()

    fun url(path: String): String = host + path

    suspend fun request(
        url: String,
        method: String = "GET",
        token: String? = null,
        body: String? = null,
        contentType: String = "application/json",
        headers: Map<String, String> = emptyMap(),
        bytes: ByteArray? = null,
        authenticated: Boolean = true
    ): String = withContext(Dispatchers.IO) {
        val requestBody = when {
            bytes != null -> bytes.toRequestBody(contentType.toMediaType())
            body != null -> body.toRequestBody(contentType.toMediaType())
            else -> if (method in listOf("POST", "PUT", "PATCH")) byteArrayOf().toRequestBody(contentType.toMediaType()) else null
        }
        val builder = Request.Builder().url(url).header("Accept", "application/json")
        if (authenticated) builder.header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
        if (token != null) builder.header("Authorization", "Bearer $token")
        headers.forEach { (key, value) -> builder.header(key, value) }
        val request = builder.method(method, requestBody).build()
        client.newCall(request).execute().use { response ->
            val text = response.body?.string() ?: ""
            if (!response.isSuccessful) {
                val json = runCatching { JSONObject(text) }.getOrNull()
                val reason = listOf("msg", "error_description", "message", "detail", "error")
                    .firstNotNullOfOrNull { key -> json?.optString(key)?.takeIf { it.isNotBlank() } }
                    ?: "Request failed (HTTP ${response.code})"
                throw ApiException(reason, response.code)
            }
            text
        }
    }

    suspend fun auth(path: String, body: JSONObject): JSONObject =
        JSONObject(request(url("/auth/v1/$path"), "POST", body = body.toString()))

    suspend fun rows(table: String, query: String, accessToken: String): JSONArray =
        JSONArray(request(url("/rest/v1/$table?$query"), token = accessToken))
}
