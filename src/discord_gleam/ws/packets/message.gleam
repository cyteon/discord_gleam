import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/user
import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result

/// Represents a message packet data structure, also used on message update
pub type MessagePacketData {
  MessagePacketData(
    content: String,
    id: Snowflake,
    guild_id: Option(Snowflake),
    channel_id: Snowflake,
    author: user.User,
  )
}

// Packet sent by Discord when a message is sent
pub type MessagePacket {
  MessagePacket(t: String, s: Int, op: Int, d: MessagePacketData)
}

pub fn string_to_data(encoded: String) -> Result(MessagePacket, json.DecodeError) {
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
      decode.success(MessagePacketData(
        content:,
        id:,
        guild_id:,
        channel_id:,
        author:,
      ))
    })
    decode.success(MessagePacket(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
}
