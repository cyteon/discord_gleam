import discord_gleam/discord/snowflake
import discord_gleam/http/request
import discord_gleam/internal/error
import discord_gleam/ws/packets/interaction_create
import gleam/http
import gleam/httpc
import logging

/// Send a basic text reply to an interaction
pub fn send_response(
  interaction: interaction_create.InteractionCreatePacketData,
  data: String,
) -> Result(Nil, error.DiscordError) {
  let request =
    request.new_with_body(
      http.Post,
      "/interactions/"
        <> snowflake.to_string(interaction.id)
        <> "/"
        <> interaction.token
        <> "/callback",
      data,
    )

  case httpc.send(request) {
    Ok(resp) -> {
      case resp.status {
        204 -> {
          logging.log(logging.Debug, "Sent interaction response")

          Ok(Nil)
        }

        429 -> {
          logging.log(
            logging.Error,
            "Failed to send interaction response: rate limited",
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
