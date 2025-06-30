import discord_gleam/discord/snowflake
import discord_gleam/types/role
import gleam/dynamic/decode
import gleam/json

/// Packet sent by Discord when a role is created
pub type GuildRoleCreatePacket {
  GuildRoleCreatePacket(
    t: String,
    s: Int,
    op: Int,
    d: GuildRoleCreatePacketData,
  )
}

pub type GuildRoleCreatePacketData {
  GuildRoleCreatePacketData(guild_id: snowflake.Snowflake, role: role.Role)
}

pub fn string_to_data(
  encoded: String,
) -> Result(GuildRoleCreatePacket, json.DecodeError) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)

    use d <- decode.field("d", {
      use guild_id <- decode.field("guild_id", snowflake.decoder())
      use role <- decode.field("role", role.from_json_decoder())

      decode.success(GuildRoleCreatePacketData(guild_id:, role:))
    })

    decode.success(GuildRoleCreatePacket(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
}
