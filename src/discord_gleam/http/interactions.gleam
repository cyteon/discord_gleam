import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/http/request
import discord_gleam/internal/error
import discord_gleam/types/message
import discord_gleam/types/message_send_response
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

/// Edit the initial response to an interaction. \
/// For example used after deffering the response, to then send a reply
pub fn edit_original(
  interaction: interaction_create.InteractionCreatePacketData,
  data: String,
) -> Result(Nil, error.DiscordError) {
  let request =
    request.new_with_body(
      http.Patch,
      "/webhooks/"
        <> snowflake.to_string(interaction.application_id)
        <> "/"
        <> interaction.token
        <> "/messages/@original",
      data,
    )

  case httpc.send(request) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          logging.log(logging.Debug, "Edited interaction response")

          Ok(Nil)
        }

        429 -> {
          logging.log(
            logging.Error,
            "Failed to edit interaction response: rate limited",
          )

          Error(request.extract_ratelimit_error(resp))
        }

        _ -> {
          logging.log(logging.Error, "Failed to edit Interaction Response")

          Error(error.ApiError(status_code: resp.status, body: resp.body))
        }
      }
    }

    Error(err) -> {
      logging.log(logging.Error, "Error when editing Interaction Response")

      Error(error.HttpError(err))
    }
  }
}

/// Delete the original response to an interaction.
pub fn delete_original(
  interaction: interaction_create.InteractionCreatePacketData,
) -> Result(Nil, error.DiscordError) {
  let request =
    request.new(
      http.Delete,
      "/webhooks/"
        <> snowflake.to_string(interaction.application_id)
        <> "/"
        <> interaction.token
        <> "/messages/@original",
    )

  case httpc.send(request) {
    Ok(resp) -> {
      case resp.status {
        204 -> {
          logging.log(logging.Debug, "Deleted interaction response")

          Ok(Nil)
        }

        429 -> {
          logging.log(
            logging.Error,
            "Failed to delete interaction response: rate limited",
          )

          Error(request.extract_ratelimit_error(resp))
        }

        _ -> {
          logging.log(logging.Error, "Failed to delete Interaction Response")

          Error(error.ApiError(status_code: resp.status, body: resp.body))
        }
      }
    }

    Error(err) -> {
      logging.log(logging.Error, "Error when deleting Interaction Response")

      Error(error.HttpError(err))
    }
  }
}

/// Send a seperate followup message to an interaction.
pub fn send_followup(
  interaction: interaction_create.InteractionCreatePacketData,
  message: message.Message,
) -> Result(message_send_response.MessageSendResponse, error.DiscordError) {
  let request =
    request.new_with_body(
      http.Post,
      "/webhooks/"
        <> snowflake.to_string(interaction.application_id)
        <> "/"
        <> interaction.token,
      message.to_string(message),
    )

  case httpc.send(request) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          logging.log(logging.Debug, "Sent followup message")

          let response = message_send_response.from_json_string(resp.body)

          case response {
            Ok(response) -> {
              Ok(response)
            }

            Error(err) -> {
              logging.log(
                logging.Error,
                "Failed to decode followup message response",
              )

              Error(err)
            }
          }
        }

        429 -> {
          logging.log(
            logging.Error,
            "Failed to send followup message: rate limited",
          )

          Error(request.extract_ratelimit_error(resp))
        }

        _ -> {
          logging.log(logging.Error, "Failed to send followup message")

          Error(error.ApiError(status_code: resp.status, body: resp.body))
        }
      }
    }

    Error(err) -> {
      logging.log(logging.Error, "Error when sending followup message")

      Error(error.HttpError(err))
    }
  }
}

/// Edit a followup to an interaction.
pub fn edit_followup(
  interaction: interaction_create.InteractionCreatePacketData,
  message_id: Snowflake(snowflake.Message),
  message: message.Message,
) -> Result(message_send_response.MessageSendResponse, error.DiscordError) {
  let request =
    request.new_with_body(
      http.Patch,
      "/webhooks/"
        <> snowflake.to_string(interaction.application_id)
        <> "/"
        <> interaction.token
        <> "/messages/"
        <> snowflake.to_string(message_id),
      message.to_string(message),
    )

  case httpc.send(request) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          logging.log(logging.Debug, "Edited followup message")

          let response = message_send_response.from_json_string(resp.body)

          case response {
            Ok(response) -> {
              Ok(response)
            }

            Error(err) -> {
              logging.log(
                logging.Error,
                "Failed to decode followup message response",
              )

              Error(err)
            }
          }
        }

        429 -> {
          logging.log(
            logging.Error,
            "Failed to edit followup message: rate limited",
          )

          Error(request.extract_ratelimit_error(resp))
        }

        _ -> {
          logging.log(logging.Error, "Failed to edit followup message")

          Error(error.ApiError(status_code: resp.status, body: resp.body))
        }
      }
    }

    Error(err) -> {
      logging.log(logging.Error, "Error when editing followup message")

      Error(error.HttpError(err))
    }
  }
}

/// Delete a followup to an interaction.
pub fn delete_followup(
  interaction: interaction_create.InteractionCreatePacketData,
  message_id: Snowflake(snowflake.Message),
) -> Result(Nil, error.DiscordError) {
  let request =
    request.new(
      http.Delete,
      "/webhooks/"
        <> snowflake.to_string(interaction.application_id)
        <> "/"
        <> interaction.token
        <> "/messages/"
        <> snowflake.to_string(message_id),
    )

  case httpc.send(request) {
    Ok(resp) -> {
      case resp.status {
        204 -> {
          logging.log(logging.Debug, "Deleted followup message")

          Ok(Nil)
        }

        429 -> {
          logging.log(
            logging.Error,
            "Failed to delete followup message: rate limited",
          )

          Error(request.extract_ratelimit_error(resp))
        }

        _ -> {
          logging.log(logging.Error, "Failed to delete followup message")

          Error(error.ApiError(status_code: resp.status, body: resp.body))
        }
      }
    }

    Error(err) -> {
      logging.log(logging.Error, "Error when deleting followup message")

      Error(error.HttpError(err))
    }
  }
}
