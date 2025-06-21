import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/user
import gleam/dynamic/decode
import gleam/json
import gleam/result

pub type GuildBanRemovePacketData {
  GuildBanRemovePacketData(user: user.User, guild_id: Snowflake)
}

/// Packet sent by Discord when a message is deleted
pub type GuildBanRemovePacket {
  GuildBanRemovePacket(t: String, s: Int, op: Int, d: GuildBanRemovePacketData)
}

pub fn string_to_data(
  encoded: String,
) -> Result(GuildBanRemovePacket, json.DecodeError) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)
    use d <- decode.field("d", {
      use user <- decode.field("user", user.from_json_decoder())
      use guild_id <- decode.field("guild_id", snowflake.decoder())
      decode.success(GuildBanRemovePacketData(user:, guild_id:))
    })
    decode.success(GuildBanRemovePacket(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
}
