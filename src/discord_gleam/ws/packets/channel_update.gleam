import discord_gleam/types/channel
import gleam/dynamic/decode
import gleam/json

// Packet sent by Discord when a channel is updated
pub type ChannelUpdatePacket {
  ChannelUpdatePacket(t: String, s: Int, op: Int, d: channel.Channel)
}

pub fn string_to_data(
  encoded: String,
) -> Result(ChannelUpdatePacket, json.DecodeError) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)
    use d <- decode.field("d", channel.from_json_decoder())
    decode.success(ChannelUpdatePacket(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
}
