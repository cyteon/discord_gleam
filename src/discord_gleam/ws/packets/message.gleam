import discord_gleam/types/message
import gleam/dynamic/decode
import gleam/json

// Packet sent by Discord when a message is sent
pub type MessagePacket {
  MessagePacket(t: String, s: Int, op: Int, d: message.Message)
}

pub fn from_json_string(
  encoded: String,
) -> Result(MessagePacket, json.DecodeError) {
  json.parse(from: encoded, using: json_decoder())
}

pub fn json_decoder() -> decode.Decoder(MessagePacket) {
  use t <- decode.field("t", decode.string)
  use s <- decode.field("s", decode.int)
  use op <- decode.field("op", decode.int)
  use d <- decode.field("d", message.json_decoder())

  decode.success(MessagePacket(t:, s:, op:, d:))
}
