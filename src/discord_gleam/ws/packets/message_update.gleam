import discord_gleam/discord/snowflake
import discord_gleam/types/user
import discord_gleam/ws/packets/message
import gleam/dynamic/decode
import gleam/json
import gleam/option.{None, Some}
import gleam/result

/// Packet sent by Discord when a message is updated
pub type MessageUpdatePacket {
  MessageUpdatePacket(t: String, s: Int, op: Int, d: message.MessagePacketData)
}

pub fn string_to_data(
  encoded: String,
) -> Result(MessageUpdatePacket, json.DecodeError) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)
    use d <- decode.field("d", {
      use content <- decode.field("content", decode.string)
      use id <- decode.field("id", snowflake.decoder())
      use guild_id <- decode.optional_field(
        "guild_id",
        None,
        snowflake.decoder() |> decode.map(Some),
      )
      use channel_id <- decode.field("channel_id", snowflake.decoder())
      use author <- decode.field("author", user.from_json_decoder())

      decode.success(message.MessagePacketData(
        content:,
        id:,
        guild_id:,
        channel_id:,
        author:,
      ))
    })
    decode.success(MessageUpdatePacket(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
}
