import gleam/dynamic/decode
import gleam/json

pub type HelloPacketData {
  HelloPacketData(heartbeat_interval: Int)
}

/// Packet returned by discord upon connecting to the gateway
pub type HelloPacket {
  HelloPacket(op: Int, d: HelloPacketData)
}

pub fn string_to_data(encoded: String) -> Result(HelloPacket, json.DecodeError) {
  let decoder = {
    use op <- decode.field("op", decode.int)
    use d <- decode.field("d", {
      use heartbeat_interval <- decode.field("heartbeat_interval", decode.int)
      decode.success(HelloPacketData(heartbeat_interval:))
    })
    decode.success(HelloPacket(op:, d:))
  }

  json.parse(from: encoded, using: decoder)
}
