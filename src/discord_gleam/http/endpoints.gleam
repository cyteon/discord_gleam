//// Low-level functions for interacting with the Discord API. \
//// Preferrably use the higher-level functions in src/discord_gleam.gleam.

import discord_gleam/http/request
import discord_gleam/internal/error
import discord_gleam/types/channel
import discord_gleam/types/message
import discord_gleam/types/message_send_response
import discord_gleam/types/reply
import discord_gleam/types/slash_command
import discord_gleam/types/user
import discord_gleam/ws/packets/interaction_create
import gleam/dynamic
import gleam/hackney
import gleam/http
import gleam/http/response
import logging

/// Get the current user
pub fn me(token: String) -> Result(user.User, error.DiscordError) {
  let request = request.new_auth(http.Get, "/users/@me", token)
  case hackney.send(request) {
    Ok(resp) -> {
      case response.get_header(resp, "content-type") {
        Ok("application/json") -> {
          user.string_to_data(resp.body)
        }
        _ ->
          Error(
            error.InvalidFormat(
              dynamic.DecodeError(
                expected: "application/json content-type",
                found: "unknown",
                path: [],
              ),
            ),
          )
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
  channel_id: String,
  message: message.Message,
) -> Result(message_send_response.MessageSendResponse, error.DiscordError) {
  let data = message.to_string(message)

  logging.log(logging.Debug, "Sending message: " <> data)

  let request =
    request.new_auth_with_body(
      http.Post,
      "/channels/" <> channel_id <> "/messages",
      token,
      data,
    )

  case hackney.send(request) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          logging.log(logging.Debug, "Message sent")

          message_send_response.from_json_string(resp.body)
        }

        _ -> {
          logging.log(logging.Error, "Failed to send message")

          Error(error.GenericHttpError(
            status_code: resp.status,
            body: resp.body,
          ))
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
  user_id: String,
) -> Result(channel.Channel, error.DiscordError) {
  let request =
    request.new_auth_with_body(
      http.Post,
      "/users/@me/channels",
      token,
      "{ \"recipient_id\": \"" <> user_id <> "\" }",
    )

  case hackney.send(request) {
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
          Error(error.GenericHttpError(status_code: v, body: resp.body))
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
  user_id: String,
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
  channel_id: String,
  message: reply.Reply,
) -> Result(Nil, error.DiscordError) {
  let data = reply.to_string(message)

  logging.log(logging.Debug, "Replying: " <> data)

  let request =
    request.new_auth_with_body(
      http.Post,
      "/channels/" <> channel_id <> "/messages",
      token,
      data,
    )

  case hackney.send(request) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          logging.log(logging.Debug, "Reply sent")

          Ok(Nil)
        }
        _ -> {
          logging.log(logging.Error, "Failed to send reply")

          Error(error.GenericHttpError(
            status_code: resp.status,
            body: resp.body,
          ))
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
  guild_id: String,
  user_id: String,
  reason: String,
) -> Result(Nil, error.DiscordError) {
  let request =
    request.new_auth_with_header(
      http.Delete,
      "/guilds/" <> guild_id <> "/members/" <> user_id,
      token,
      #("X-Audit-Log-Reason", reason),
    )

  case hackney.send(request) {
    Ok(resp) -> {
      case resp.status {
        204 -> {
          logging.log(logging.Debug, "Kicked member")

          Ok(Nil)
        }

        _ -> {
          logging.log(logging.Error, "Failed to kick member")

          Error(error.GenericHttpError(
            status_code: resp.status,
            body: resp.body,
          ))
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
  guild_id: String,
  user_id: String,
  reason: String,
) -> Result(Nil, error.DiscordError) {
  let request =
    request.new_auth_with_header(
      http.Put,
      "/guilds/" <> guild_id <> "/bans/" <> user_id,
      token,
      #("X-Audit-Log-Reason", reason),
    )

  case hackney.send(request) {
    Ok(resp) -> {
      case resp.status {
        204 -> {
          logging.log(logging.Debug, "Banned member")

          Ok(Nil)
        }
        _ -> {
          logging.log(logging.Error, "Failed to ban member")

          Error(error.GenericHttpError(
            status_code: resp.status,
            body: resp.body,
          ))
        }
      }
    }
    Error(err) -> {
      logging.log(logging.Error, "Failed to ban member: ")

      Error(error.HttpError(err))
    }
  }
}

/// Delete a message by channel id and message id
pub fn delete_message(
  token: String,
  channel_id: String,
  message_id: String,
  reason: String,
) -> Result(Nil, error.DiscordError) {
  let request =
    request.new_auth_with_header(
      http.Delete,
      "/channels/" <> channel_id <> "/messages/" <> message_id,
      token,
      #("X-Audit-Log-Reason", reason),
    )

  case hackney.send(request) {
    Ok(resp) -> {
      case resp.status {
        204 -> {
          logging.log(logging.Debug, "Deleted Message")

          Ok(Nil)
        }
        _ -> {
          logging.log(logging.Error, "Failed to delete message")

          Error(error.GenericHttpError(
            status_code: resp.status,
            body: resp.body,
          ))
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
  channel_id: String,
  message_id: String,
  message: message.Message,
) -> Result(Nil, error.DiscordError) {
  let data = message.to_string(message)

  logging.log(logging.Debug, "Editing message: " <> data)

  let request =
    request.new_auth_with_body(
      http.Patch,
      "/channels/" <> channel_id <> "/messages/" <> message_id,
      token,
      data,
    )

  case hackney.send(request) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          logging.log(logging.Debug, "Message edited")

          Ok(Nil)
        }
        _ -> {
          logging.log(logging.Error, "Failed to edit message")

          Error(error.GenericHttpError(
            status_code: resp.status,
            body: resp.body,
          ))
        }
      }
    }

    Error(err) -> {
      logging.log(logging.Error, "Failed to edit message: ")

      Error(error.HttpError(err))
    }
  }
}

/// Wipes the global commands for the bot
pub fn wipe_global_commands(
  token: String,
  client_id: String,
) -> Result(Nil, error.DiscordError) {
  let request =
    request.new_auth_with_body(
      http.Put,
      "/applications/" <> client_id <> "/commands",
      token,
      "{}",
    )

  case hackney.send(request) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          logging.log(logging.Debug, "Wiped global commands")

          Ok(Nil)
        }
        _ -> {
          logging.log(logging.Error, "Failed to wipe global commands")

          Error(error.GenericHttpError(
            status_code: resp.status,
            body: resp.body,
          ))
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
  client_id: String,
  guild_id: String,
) -> Result(Nil, error.DiscordError) {
  let request =
    request.new_auth_with_body(
      http.Put,
      "/applications/" <> client_id <> "/guilds/" <> guild_id <> "/commands",
      token,
      "{}",
    )

  case hackney.send(request) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          logging.log(logging.Debug, "Wiped guild commands")

          Ok(Nil)
        }
        _ -> {
          logging.log(logging.Error, "Failed to wipe guild commands")

          Error(error.GenericHttpError(
            status_code: resp.status,
            body: resp.body,
          ))
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
  client_id: String,
  command: slash_command.SlashCommand,
) -> Result(Nil, error.DiscordError) {
  let request =
    request.new_auth_with_body(
      http.Post,
      "/applications/" <> client_id <> "/commands",
      token,
      slash_command.command_to_string(command),
    )

  case hackney.send(request) {
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

          Error(error.GenericHttpError(
            status_code: resp.status,
            body: resp.body,
          ))
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
  client_id: String,
  guild_id: String,
  command: slash_command.SlashCommand,
) -> Result(Nil, error.DiscordError) {
  let request =
    request.new_auth_with_body(
      http.Post,
      "/applications/" <> client_id <> "/guilds/" <> guild_id <> "/commands",
      token,
      slash_command.command_to_string(command),
    )

  case hackney.send(request) {
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

          Error(error.GenericHttpError(
            status_code: resp.status,
            body: resp.body,
          ))
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
        <> interaction.d.id
        <> "/"
        <> interaction.d.token
        <> "/callback",
      slash_command.make_basic_text_reply(message, ephemeral),
    )

  case hackney.send(request) {
    Ok(resp) -> {
      case resp.status {
        204 -> {
          logging.log(logging.Debug, "Sent Interaction Response")

          Ok(Nil)
        }

        _ -> {
          logging.log(logging.Error, "Failed to send Interaction Response")

          Error(error.GenericHttpError(
            status_code: resp.status,
            body: resp.body,
          ))
        }
      }
    }
    Error(err) -> {
      logging.log(logging.Error, "Error when sending Interaction Response")

      Error(error.HttpError(err))
    }
  }
}
