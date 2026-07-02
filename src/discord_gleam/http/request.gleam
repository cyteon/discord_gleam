//// This module contains functions to create http requests to discord

import discord_gleam/internal/error
import gleam/float
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/list

/// Create a base request to discord
pub fn new(method: http.Method, path: String) -> request.Request(String) {
  request.new()
  |> request.set_method(method)
  |> request.set_host("discord.com")
  |> request.set_path("/api/v10" <> path)
  |> request.prepend_header("accept", "application/json")
  |> request.prepend_header(
    "User-Agent",
    "DiscordBot (https://github.com/cyteon/discord_gleam, 3.0.0)",
  )
}

/// Create an unauthenticated request, with a body
pub fn new_with_body(
  method: http.Method,
  path: String,
  data: String,
) -> request.Request(String) {
  new(method, path)
  |> request.set_body(data)
  |> request.prepend_header("Content-Type", "application/json")
}

/// Create an authenticated request
pub fn new_auth(
  method: http.Method,
  path: String,
  token: String,
) -> request.Request(String) {
  new(method, path)
  |> request.prepend_header("Authorization", "Bot " <> token)
}

/// Create an authenticated request, with a body
pub fn new_auth_with_body(
  method: http.Method,
  path: String,
  token: String,
  data: String,
) -> request.Request(String) {
  new(method, path)
  |> request.prepend_header("Authorization", "Bot " <> token)
  |> request.set_body(data)
  |> request.prepend_header("Content-Type", "application/json")
}

/// Create an authenticated request with a custom header
pub fn new_auth_with_header(
  method: http.Method,
  path: String,
  token: String,
  header: #(String, String),
) -> request.Request(String) {
  new_auth(method, path, token)
  |> request.set_header(header.0, header.1)
}

/// Used to exctract the 429 error from a request
pub fn extract_ratelimit_error(
  resp: response.Response(String),
) -> error.DiscordError {
  let global = case list.key_find(resp.headers, "x-ratelimit-global") {
    Ok(_) -> True
    Error(_) -> False
  }

  case list.key_find(resp.headers, "retry-after") {
    Ok(retry_after) -> {
      case float.parse(retry_after) {
        Ok(retry_after) -> {
          error.RatelimitError(retry_after_secs: retry_after, global:)
        }

        Error(_) -> {
          error.ApiError(status_code: resp.status, body: resp.body)
        }
      }
    }

    Error(_) -> {
      error.ApiError(status_code: resp.status, body: resp.body)
    }
  }
}
