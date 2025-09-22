import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/guild_member
import gleam/dynamic/decode
import gleam/json

pub type GuildMemberUpdateData {
  GuildMemberUpdateData(
    guild_member: guild_member.GuildMember,
    guild_id: Snowflake,
  )
}

/// Packet sent by Discord when a member is added to a guild
pub type GuildMemberUpdate {
  GuildMemberUpdate(t: String, s: Int, op: Int, d: GuildMemberUpdateData)
}

pub fn string_to_data(
  encoded: String,
) -> Result(GuildMemberUpdate, json.DecodeError) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)
    use guild_member <- decode.field("d", guild_member.from_json_decoder())
    use guild_id <- decode.field("d", {
      use guild_id <- decode.field("guild_id", snowflake.decoder())
      decode.success(guild_id)
    })

    decode.success(GuildMemberUpdate(
      t:,
      s:,
      op:,
      d: GuildMemberUpdateData(guild_member:, guild_id:),
    ))
  }

  json.parse(from: encoded, using: decoder)
}
