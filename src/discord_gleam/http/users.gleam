import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/http/channels
import discord_gleam/http/request
import discord_gleam/internal/error
import discord_gleam/types/channel
import discord_gleam/types/message
import discord_gleam/types/message_send_response
import discord_gleam/types/user
import gleam/http
import gleam/httpc
import gleam/json
import logging

/// Get the current user
pub fn me(token: String) -> Result(user.User, error.DiscordError) {
  let request = request.new_auth(http.Get, "/users/@me", token)

  case httpc.send(request) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          user.from_json_string(resp.body)
        }

        _ -> Error(error.ApiError(status_code: resp.status, body: resp.body))
      }
    }

    Error(err) -> {
      logging.log(logging.Error, "Failed to get current user")

      Error(error.HttpError(err))
    }
  }
}

/// Create a DM channel, can be used to send direct messages where a direct message function is not created
pub fn create_dm_channel(
  token: String,
  user_id: Snowflake(snowflake.User),
) -> Result(channel.Channel, error.DiscordError) {
  let request =
    request.new_auth_with_body(
      http.Post,
      "/users/@me/channels",
      token,
      json.to_string(
        json.object([
          #("recipient_id", json.string(snowflake.to_string(user_id))),
        ]),
      ),
    )

  case httpc.send(request) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          logging.log(logging.Debug, "DM channel created")

          let channel: Result(channel.Channel, error.DiscordError) =
            channel.from_json_string(resp.body)

          case channel {
            Ok(channel) -> {
              Ok(channel)
            }

            Error(err) -> {
              logging.log(logging.Error, "Failed to decode DM channel")

              Error(err)
            }
          }
        }

        v -> {
          Error(error.ApiError(status_code: v, body: resp.body))
        }
      }
    }

    Error(err) -> {
      logging.log(logging.Error, "Failed to create DM channel")

      Error(error.HttpError(err))
    }
  }
}

/// Creates a DM channel, then sends a message with `send_message()`.
pub fn send_direct_message(
  token: String,
  user_id: Snowflake(snowflake.User),
  message: message.Message,
) -> Result(message_send_response.MessageSendResponse, error.DiscordError) {
  let data: String = message.to_string(message)
  logging.log(logging.Debug, "Sending DM: " <> data)

  let channel: Result(channel.Channel, error.DiscordError) =
    create_dm_channel(token, user_id)

  case channel {
    Ok(channel) -> {
      channels.send_message(token, channel.id, message)
    }

    Error(err) -> {
      logging.log(logging.Error, "Failed to create DM channel")

      Error(err)
    }
  }
}
