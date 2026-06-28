import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/user
import gleam/dynamic/decode
import gleam/json

pub type GuildMemberRemovePacketData {
  GuildMemberRemovePacketData(
    user: user.User,
    guild_id: Snowflake(snowflake.Guild),
  )
}

/// Packet sent by Discord when a member is removed from a guild
pub type GuildMemberRemovePacket {
  GuildMemberRemovePacket(
    t: String,
    s: Int,
    op: Int,
    d: GuildMemberRemovePacketData,
  )
}

pub fn from_json_string(
  encoded: String,
) -> Result(GuildMemberRemovePacket, json.DecodeError) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)
    use d <- decode.field("d", {
      use user <- decode.field("user", user.json_decoder())
      use guild_id <- decode.field("guild_id", snowflake.decoder())
      decode.success(GuildMemberRemovePacketData(user:, guild_id:))
    })
    decode.success(GuildMemberRemovePacket(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
}
