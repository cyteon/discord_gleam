import discord_gleam/discord/snowflake.{type Snowflake}
import gleam/dynamic/decode
import gleam/json
import gleam/result

pub type MessageDeletePacketData {
  MessageDeletePacketData(
    id: Snowflake,
    guild_id: Snowflake,
    channel_id: Snowflake,
  )
}

/// Packet sent by Discord when a message is deleted
pub type MessageDeletePacket {
  MessageDeletePacket(t: String, s: Int, op: Int, d: MessageDeletePacketData)
}

pub fn string_to_data(
  encoded: String,
) -> Result(MessageDeletePacket, json.DecodeError) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)
    use d <- decode.field("d", {
      use id <- decode.field("id", snowflake.decoder())
      use guild_id <- decode.field("guild_id", snowflake.decoder())
      use channel_id <- decode.field("channel_id", snowflake.decoder())
      decode.success(MessageDeletePacketData(id:, guild_id:, channel_id:))
    })
    decode.success(MessageDeletePacket(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
}
