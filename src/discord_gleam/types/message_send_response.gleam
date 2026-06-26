import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/internal/error
import discord_gleam/types/user
import gleam/dynamic/decode
import gleam/json
import gleam/result

/// Data returned by discord when you send a message
pub type MessageSendResponse {
  MessageSendResponse(
    id: Snowflake(snowflake.Message),
    channel_id: Snowflake(snowflake.Channel),
    content: String,
    timestamp: String,
    author: user.User,
  )
}

/// Decode a string to a message send response
pub fn from_json_string(
  encoded: String,
) -> Result(MessageSendResponse, error.DiscordError) {
  let decoder = {
    use id <- decode.field("id", snowflake.decoder())
    use channel_id <- decode.field("channel_id", snowflake.decoder())
    use content <- decode.field("content", decode.string)
    use timestamp <- decode.field("timestamp", decode.string)
    use author <- decode.field("author", user.from_json_decoder())
    decode.success(MessageSendResponse(
      id:,
      channel_id:,
      content:,
      timestamp:,
      author:,
    ))
  }

  json.parse(from: encoded, using: decoder)
  |> result.map_error(error.JsonDecodeError)
}
