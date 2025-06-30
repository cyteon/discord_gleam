import discord_gleam/discord/snowflake
import gleam/dynamic/decode
import gleam/json

/// Packet sent by Discord when a role is deleted
pub type GuildRoleDeletePacket {
  GuildRoleDeletePacket(
    t: String,
    s: Int,
    op: Int,
    d: GuildRoleDeletePacketData,
  )
}

pub type GuildRoleDeletePacketData {
  GuildRoleDeletePacketData(
    guild_id: snowflake.Snowflake,
    role_id: snowflake.Snowflake,
  )
}

pub fn string_to_data(
  encoded: String,
) -> Result(GuildRoleDeletePacket, json.DecodeError) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)

    use d <- decode.field("d", {
      use guild_id <- decode.field("guild_id", snowflake.decoder())
      use role_id <- decode.field("role_id", snowflake.decoder())
      decode.success(GuildRoleDeletePacketData(guild_id:, role_id:))
    })

    decode.success(GuildRoleDeletePacket(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
}
