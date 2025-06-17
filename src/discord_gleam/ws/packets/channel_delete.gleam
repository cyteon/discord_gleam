import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/channel
import gleam/dynamic/decode
import gleam/io
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result

// Packet sent by Discord when a message is sent
pub type ChannelDeletePacket {
  ChannelDeletePacket(t: String, s: Int, op: Int, d: channel.Channel)
}

pub fn string_to_data(encoded: String) -> Result(ChannelDeletePacket, String) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)
    use d <- decode.field("d", channel.from_json_decoder())
    decode.success(ChannelDeletePacket(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
  |> result.map_error(fn(err) {
    io.debug(err)
    "Failed to decode ChannelDelete packet"
  })
}
