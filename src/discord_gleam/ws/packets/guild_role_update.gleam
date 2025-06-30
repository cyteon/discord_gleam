import discord_gleam/discord/snowflake
import discord_gleam/types/role
import gleam/dynamic/decode
import gleam/json

/// Packet sent by Discord when a role is updated
pub type GuildRoleUpdatePacket {
  GuildRoleUpdatePacket(
    t: String,
    s: Int,
    op: Int,
    d: GuildRoleUpdatePacketData,
  )
}

pub type GuildRoleUpdatePacketData {
  GuildRoleUpdatePacketData(guild_id: snowflake.Snowflake, role: role.Role)
}

pub fn string_to_data(
  encoded: String,
) -> Result(GuildRoleUpdatePacket, json.DecodeError) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)

    use d <- decode.field("d", {
      use guild_id <- decode.field("guild_id", snowflake.decoder())
      use role <- decode.field("role", role.from_json_decoder())

      decode.success(GuildRoleUpdatePacketData(guild_id:, role:))
    })

    decode.success(GuildRoleUpdatePacket(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
}
