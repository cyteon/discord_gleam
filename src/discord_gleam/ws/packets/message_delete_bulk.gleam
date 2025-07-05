import discord_gleam/discord/snowflake.{type Snowflake}
import gleam/dynamic/decode
import gleam/json

pub type MessageDeleteBulkPacketData {
  MessageDeleteBulkPacketData(
    ids: List(Snowflake),
    guild_id: Snowflake,
    channel_id: Snowflake,
  )
}

/// Packet sent by Discord when a message is deleted
pub type MessageDeleteBulkPacket {
  MessageDeleteBulkPacket(
    t: String,
    s: Int,
    op: Int,
    d: MessageDeleteBulkPacketData,
  )
}

pub fn string_to_data(
  encoded: String,
) -> Result(MessageDeleteBulkPacket, json.DecodeError) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)
    use d <- decode.field("d", {
      use ids <- decode.field("ids", decode.list(snowflake.decoder()))
      use guild_id <- decode.field("guild_id", snowflake.decoder())
      use channel_id <- decode.field("channel_id", snowflake.decoder())
      decode.success(MessageDeleteBulkPacketData(ids:, guild_id:, channel_id:))
    })
    decode.success(MessageDeleteBulkPacket(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
}
