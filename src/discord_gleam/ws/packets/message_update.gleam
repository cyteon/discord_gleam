import discord_gleam/ws/packets/message
import gleam/dynamic/decode
import gleam/json

/// Packet sent by Discord when a message is updated
pub type MessageUpdatePacket {
  MessageUpdatePacket(t: String, s: Int, op: Int, d: message.MessagePacketData)
}

pub fn from_json_string(
  encoded: String,
) -> Result(MessageUpdatePacket, json.DecodeError) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)
    use d <- decode.field("d", message.data_json_decoder())

    decode.success(MessageUpdatePacket(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
}
