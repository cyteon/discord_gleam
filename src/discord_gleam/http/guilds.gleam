import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/http/request
import discord_gleam/internal/error
import gleam/http
import gleam/httpc
import logging

/// Kick a member from a server
pub fn kick_member(
  token: String,
  guild_id: Snowflake(snowflake.Guild),
  user_id: Snowflake(snowflake.User),
  reason: String,
) -> Result(Nil, error.DiscordError) {
  let request =
    request.new_auth_with_header(
      http.Delete,
      "/guilds/"
        <> snowflake.to_string(guild_id)
        <> "/members/"
        <> snowflake.to_string(user_id),
      token,
      #("X-Audit-Log-Reason", reason),
    )

  case httpc.send(request) {
    Ok(resp) -> {
      case resp.status {
        204 -> {
          logging.log(logging.Debug, "Kicked member")

          Ok(Nil)
        }

        _ -> {
          logging.log(logging.Error, "Failed to kick member")

          Error(error.ApiError(status_code: resp.status, body: resp.body))
        }
      }
    }
    Error(err) -> {
      logging.log(logging.Error, "Failed to kick member")

      Error(error.HttpError(err))
    }
  }
}

/// Ban a member from a server
pub fn ban_member(
  token: String,
  guild_id: Snowflake(snowflake.Guild),
  user_id: Snowflake(snowflake.User),
  reason: String,
) -> Result(Nil, error.DiscordError) {
  let request =
    request.new_auth_with_header(
      http.Put,
      "/guilds/"
        <> snowflake.to_string(guild_id)
        <> "/bans/"
        <> snowflake.to_string(user_id),
      token,
      #("X-Audit-Log-Reason", reason),
    )

  case httpc.send(request) {
    Ok(resp) -> {
      case resp.status {
        204 -> {
          logging.log(logging.Debug, "Banned member")

          Ok(Nil)
        }
        _ -> {
          logging.log(logging.Error, "Failed to ban member")

          Error(error.ApiError(status_code: resp.status, body: resp.body))
        }
      }
    }
    Error(err) -> {
      logging.log(logging.Error, "Failed to ban member")

      Error(error.HttpError(err))
    }
  }
}
