//// Low-level functions for interacting with the Discord API. \
//// Preferrably use the higher-level functions in src/discord_gleam.gleam.

import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/http/request
import discord_gleam/internal/error
import discord_gleam/types/channel
import discord_gleam/types/message
import discord_gleam/types/message_send_response
import discord_gleam/types/reply
import discord_gleam/types/slash_command
import discord_gleam/types/user
import discord_gleam/ws/packets/interaction_create
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
          user.string_to_data(resp.body)
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
            channel.string_to_data(resp.body)

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
) -> Result(Nil, error.DiscordError) {
  let data: String = message.to_string(message)
  logging.log(logging.Debug, "Sending DM: " <> data)

  let channel: Result(channel.Channel, error.DiscordError) =
    create_dm_channel(token, user_id)

  case channel {
    Ok(channel) -> {
      let _ = send_message(token, channel.id, message)

      Ok(Nil)
    }

    Error(err) -> {
      logging.log(logging.Error, "Failed to create DM channel")

      Error(err)
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

/// Wipes the global commands for the bot
pub fn wipe_global_commands(
  token: String,
  client_id: Snowflake(snowflake.Application),
) -> Result(Nil, error.DiscordError) {
  let request =
    request.new_auth_with_body(
      http.Put,
      "/applications/" <> snowflake.to_string(client_id) <> "/commands",
      token,
      "{}",
    )

  case httpc.send(request) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          logging.log(logging.Debug, "Wiped global commands")

          Ok(Nil)
        }
        _ -> {
          logging.log(logging.Error, "Failed to wipe global commands")

          Error(error.ApiError(status_code: resp.status, body: resp.body))
        }
      }
    }
    Error(err) -> {
      logging.log(logging.Error, "Failed to wipe global commands")

      Error(error.HttpError(err))
    }
  }
}

/// Wipes the guild commands for the bot
pub fn wipe_guild_commands(
  token: String,
  client_id: Snowflake(snowflake.Application),
  guild_id: Snowflake(snowflake.Guild),
) -> Result(Nil, error.DiscordError) {
  let request =
    request.new_auth_with_body(
      http.Put,
      "/applications/"
        <> snowflake.to_string(client_id)
        <> "/guilds/"
        <> snowflake.to_string(guild_id)
        <> "/commands",
      token,
      "{}",
    )

  case httpc.send(request) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          logging.log(logging.Debug, "Wiped guild commands")

          Ok(Nil)
        }
        _ -> {
          logging.log(logging.Error, "Failed to wipe guild commands")

          Error(error.ApiError(status_code: resp.status, body: resp.body))
        }
      }
    }
    Error(err) -> {
      logging.log(logging.Error, "Failed to wipe guild commands")

      Error(error.HttpError(err))
    }
  }
}

/// Register a new global slash command
pub fn register_global_command(
  token: String,
  client_id: Snowflake(snowflake.Application),
  command: slash_command.SlashCommand,
) -> Result(Nil, error.DiscordError) {
  let request =
    request.new_auth_with_body(
      http.Post,
      "/applications/" <> snowflake.to_string(client_id) <> "/commands",
      token,
      slash_command.command_to_string(command),
    )

  case httpc.send(request) {
    Ok(resp) -> {
      case resp.status {
        201 -> {
          logging.log(logging.Debug, "Added global command " <> command.name)

          Ok(Nil)
        }

        200 -> {
          logging.log(logging.Debug, "Updated global command " <> command.name)

          Ok(Nil)
        }

        _ -> {
          logging.log(
            logging.Error,
            "Failed to add global command " <> command.name,
          )

          Error(error.ApiError(status_code: resp.status, body: resp.body))
        }
      }
    }

    Error(err) -> {
      logging.log(
        logging.Error,
        "Failed to add global command " <> command.name,
      )

      Error(error.HttpError(err))
    }
  }
}

/// Register a new guild-specific slash command
pub fn register_guild_command(
  token: String,
  client_id: Snowflake(snowflake.Application),
  guild_id: Snowflake(snowflake.Guild),
  command: slash_command.SlashCommand,
) -> Result(Nil, error.DiscordError) {
  let request =
    request.new_auth_with_body(
      http.Post,
      "/applications/"
        <> snowflake.to_string(client_id)
        <> "/guilds/"
        <> snowflake.to_string(guild_id)
        <> "/commands",
      token,
      slash_command.command_to_string(command),
    )

  case httpc.send(request) {
    Ok(resp) -> {
      case resp.status {
        201 -> {
          logging.log(logging.Debug, "Added guild command " <> command.name)

          Ok(Nil)
        }

        200 -> {
          logging.log(logging.Debug, "Updated guild command " <> command.name)

          Ok(Nil)
        }

        _ -> {
          logging.log(
            logging.Error,
            "Failed to add guild command " <> command.name,
          )

          Error(error.ApiError(status_code: resp.status, body: resp.body))
        }
      }
    }
    Error(err) -> {
      logging.log(logging.Error, "Failed to add guild command " <> command.name)

      Error(error.HttpError(err))
    }
  }
}

/// Send a basic text reply to an interaction
pub fn interaction_send_text(
  interaction: interaction_create.InteractionCreatePacket,
  message: String,
  ephemeral: Bool,
) -> Result(Nil, error.DiscordError) {
  let request =
    request.new_with_body(
      http.Post,
      "/interactions/"
        <> snowflake.to_string(interaction.d.id)
        <> "/"
        <> interaction.d.token
        <> "/callback",
      slash_command.make_basic_text_reply(message, ephemeral),
    )

  case httpc.send(request) {
    Ok(resp) -> {
      case resp.status {
        204 -> {
          logging.log(logging.Debug, "Sent Interaction Response")

          Ok(Nil)
        }

        _ -> {
          logging.log(logging.Error, "Failed to send Interaction Response")

          Error(error.ApiError(status_code: resp.status, body: resp.body))
        }
      }
    }
    Error(err) -> {
      logging.log(logging.Error, "Error when sending Interaction Response")

      Error(error.HttpError(err))
    }
  }
}
