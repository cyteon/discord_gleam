import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/http/request
import discord_gleam/internal/error
import discord_gleam/types/slash_command
import gleam/http
import gleam/httpc
import logging

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
      "[]",
    )

  case httpc.send(request) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          logging.log(logging.Debug, "Wiped global commands")

          Ok(Nil)
        }

        429 -> {
          logging.log(
            logging.Error,
            "Failed to wipe global commands: rate limited",
          )

          Error(request.extract_ratelimit_error(resp))
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
      "[]",
    )

  case httpc.send(request) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          logging.log(logging.Debug, "Wiped guild commands")

          Ok(Nil)
        }

        429 -> {
          logging.log(
            logging.Error,
            "Failed to wipe guild commands: rate limited",
          )

          Error(request.extract_ratelimit_error(resp))
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

        429 -> {
          logging.log(
            logging.Error,
            "Failed to add global command " <> command.name <> ": rate limited",
          )

          Error(request.extract_ratelimit_error(resp))
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

        429 -> {
          logging.log(
            logging.Error,
            "Failed to add guild command " <> command.name <> ": rate limited",
          )

          Error(request.extract_ratelimit_error(resp))
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
