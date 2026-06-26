import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/http/request
import discord_gleam/internal/error
import discord_gleam/types/message
import discord_gleam/types/message_send_response
import discord_gleam/types/reply
import gleam/http
import gleam/httpc
import logging

/// Send a message to a channel
pub fn send_message(
  token: String,
  channel_id: Snowflake(snowflake.Channel),
  message: message.Message,
) -> Result(message_send_response.MessageSendResponse, error.DiscordError) {
  let data = message.to_string(message)

  logging.log(logging.Debug, "Sending message: " <> data)

  let request =
    request.new_auth_with_body(
      http.Post,
      "/channels/" <> snowflake.to_string(channel_id) <> "/messages",
      token,
      data,
    )

  case httpc.send(request) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          logging.log(logging.Debug, "Message sent")

          message_send_response.from_json_string(resp.body)
        }

        _ -> {
          logging.log(logging.Error, "Failed to send message")

          Error(error.ApiError(status_code: resp.status, body: resp.body))
        }
      }
    }

    Error(err) -> {
      logging.log(logging.Error, "Failed to send message")

      Error(error.HttpError(err))
    }
  }
}

/// Reply to a message
pub fn reply(
  token: String,
  channel_id: Snowflake(snowflake.Channel),
  message: reply.Reply,
) -> Result(Nil, error.DiscordError) {
  let data = reply.to_string(message)

  logging.log(logging.Debug, "Replying: " <> data)

  let request =
    request.new_auth_with_body(
      http.Post,
      "/channels/" <> snowflake.to_string(channel_id) <> "/messages",
      token,
      data,
    )

  case httpc.send(request) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          logging.log(logging.Debug, "Reply sent")

          Ok(Nil)
        }
        _ -> {
          logging.log(logging.Error, "Failed to send reply")

          Error(error.ApiError(status_code: resp.status, body: resp.body))
        }
      }
    }
    Error(err) -> {
      logging.log(logging.Error, "Failed to send reply")

      Error(error.HttpError(err))
    }
  }
}

/// Delete a message by channel id and message id
pub fn delete_message(
  token: String,
  channel_id: Snowflake(snowflake.Channel),
  message_id: Snowflake(snowflake.Message),
  reason: String,
) -> Result(Nil, error.DiscordError) {
  let request =
    request.new_auth_with_header(
      http.Delete,
      "/channels/"
        <> snowflake.to_string(channel_id)
        <> "/messages/"
        <> snowflake.to_string(message_id),
      token,
      #("X-Audit-Log-Reason", reason),
    )

  case httpc.send(request) {
    Ok(resp) -> {
      case resp.status {
        204 -> {
          logging.log(logging.Debug, "Deleted Message")

          Ok(Nil)
        }
        _ -> {
          logging.log(logging.Error, "Failed to delete message")

          Error(error.ApiError(status_code: resp.status, body: resp.body))
        }
      }
    }
    Error(err) -> {
      logging.log(logging.Error, "Failed to delete message")

      Error(error.HttpError(err))
    }
  }
}

/// Edit an message by channel id and message id
pub fn edit_message(
  token: String,
  channel_id: Snowflake(snowflake.Channel),
  message_id: Snowflake(snowflake.Message),
  message: message.Message,
) -> Result(Nil, error.DiscordError) {
  let data = message.to_string(message)

  logging.log(logging.Debug, "Editing message: " <> data)

  let request =
    request.new_auth_with_body(
      http.Patch,
      "/channels/"
        <> snowflake.to_string(channel_id)
        <> "/messages/"
        <> snowflake.to_string(message_id),
      token,
      data,
    )

  case httpc.send(request) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          logging.log(logging.Debug, "Message edited")

          Ok(Nil)
        }
        _ -> {
          logging.log(logging.Error, "Failed to edit message")

          Error(error.ApiError(status_code: resp.status, body: resp.body))
        }
      }
    }

    Error(err) -> {
      logging.log(logging.Error, "Failed to edit message")

      Error(error.HttpError(err))
    }
  }
}
