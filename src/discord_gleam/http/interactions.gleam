import discord_gleam/discord/snowflake
import discord_gleam/http/request
import discord_gleam/internal/error
import discord_gleam/types/slash_command
import discord_gleam/ws/packets/interaction_create
import gleam/http
import gleam/httpc
import logging

/// Send a basic text reply to an interaction
pub fn interaction_send_text(
  interaction: interaction_create.InteractionCreatePacketData,
  message: String,
  ephemeral: Bool,
) -> Result(Nil, error.DiscordError) {
  let request =
    request.new_with_body(
      http.Post,
      "/interactions/"
        <> snowflake.to_string(interaction.id)
        <> "/"
        <> interaction.token
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

        429 -> {
          logging.log(
            logging.Error,
            "Failed to send Interaction Response: rate limited",
          )

          Error(request.extract_ratelimit_error(resp))
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
