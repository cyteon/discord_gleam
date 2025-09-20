import discord_gleam/types/presence
import gleam/dynamic/decode
import gleam/json

pub type PresenceUpdatePacket {
  PresenceUpdatePacket(t: String, s: Int, op: Int, d: presence.Presence)
}

pub fn string_to_data(
  encoded: String,
) -> Result(PresenceUpdatePacket, json.DecodeError) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)
    use d <- decode.field("d", presence.from_json_decoder())
    decode.success(PresenceUpdatePacket(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
}
