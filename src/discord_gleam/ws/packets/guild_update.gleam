import discord_gleam/types/guild
import gleam/dynamic/decode
import gleam/json

pub type GuildUpdatePacket {
  GuildUpdatePacket(t: String, s: Int, op: Int, d: guild.Guild)
}

pub fn from_json_string(
  encoded: String,
) -> Result(GuildUpdatePacket, json.DecodeError) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)
    use d <- decode.field("d", guild.json_decoder())
    decode.success(GuildUpdatePacket(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
}
