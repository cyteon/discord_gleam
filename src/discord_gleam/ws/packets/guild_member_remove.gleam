import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/user
import gleam/dynamic/decode
import gleam/json

pub type GuildMemberRemoveData {
  GuildMemberRemoveData(
    user: user.User,
    guild_id: Snowflake,
  )
}

/// Packet sent by Discord when a member is removed from a guild
pub type GuildMemberRemove {
  GuildMemberRemove(t: String, s: Int, op: Int, d: GuildMemberRemoveData)
}

pub fn string_to_data(
  encoded: String,
) -> Result(GuildMemberRemove, json.DecodeError) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)
    use d <- decode.field("d", {
      use user <- decode.field("user", user.from_json_decoder())
      use guild_id <- decode.field("guild_id", snowflake.decoder())
      decode.success(GuildMemberRemoveData(
        user:,
        guild_id:,
      ))
    })
    decode.success(GuildMemberRemove(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
}
