import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/guild_member
import gleam/dynamic/decode
import gleam/json

pub type GuildMemberAddPacketData {
  GuildMemberAddPacketData(
    guild_member: guild_member.GuildMember,
    guild_id: Snowflake(snowflake.Guild),
  )
}

/// Packet sent by Discord when a member is added to a guild
pub type GuildMemberAddPacket {
  GuildMemberAddPacket(t: String, s: Int, op: Int, d: GuildMemberAddPacketData)
}

pub fn from_json_string(
  encoded: String,
) -> Result(GuildMemberAddPacket, json.DecodeError) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)
    use guild_member <- decode.field("d", guild_member.json_decoder())
    use guild_id <- decode.field("d", {
      use guild_id <- decode.field("guild_id", snowflake.decoder())
      decode.success(guild_id)
    })

    decode.success(GuildMemberAddPacket(
      t:,
      s:,
      op:,
      d: GuildMemberAddPacketData(guild_member:, guild_id:),
    ))
  }

  json.parse(from: encoded, using: decoder)
}
