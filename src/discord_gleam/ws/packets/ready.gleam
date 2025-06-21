import discord_gleam/types/user
import gleam/dynamic/decode
import gleam/json
import gleam/result

pub type ReadyData {
  ReadyData(
    v: Int,
    user: user.User,
    session_id: String,
    resume_gateway_url: String,
  )
}

// Packet sent by Discord when the client is authenticated and ready
pub type ReadyPacket {
  ReadyPacket(t: String, s: Int, op: Int, d: ReadyData)
}

pub fn string_to_data(encoded: String) -> Result(ReadyPacket, json.DecodeError) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)

    use d <- decode.field("d", {
      use v <- decode.field("v", decode.int)

      use user <- decode.field("user", user.from_json_decoder())

      use session_id <- decode.field("session_id", decode.string)
      use resume_gateway_url <- decode.field(
        "resume_gateway_url",
        decode.string,
      )

      decode.success(ReadyData(v:, user:, session_id:, resume_gateway_url:))
    })

    decode.success(ReadyPacket(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
}
