import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/user
import gleam/dynamic/decode
import gleam/json
import gleam/option

pub type GuildBanAddPacketData {
  GuildBanAddPacketData(
    user: user.User,
    guild_id: Snowflake,
    delete_message_secs: option.Option(Int),
  )
}

/// Packet sent by Discord when a member is banned
pub type GuildBanAddPacket {
  GuildBanAddPacket(t: String, s: Int, op: Int, d: GuildBanAddPacketData)
}

pub fn string_to_data(
  encoded: String,
) -> Result(GuildBanAddPacket, json.DecodeError) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)
    use d <- decode.field("d", {
      use user <- decode.field("user", user.from_json_decoder())
      use guild_id <- decode.field("guild_id", snowflake.decoder())
      use delete_message_secs <- decode.optional_field(
        "delete_message_seconds",
        option.None,
        decode.int |> decode.map(option.Some),
      )
      decode.success(GuildBanAddPacketData(
        user:,
        guild_id:,
        delete_message_secs:,
      ))
    })
    decode.success(GuildBanAddPacket(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
}
