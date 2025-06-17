import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/channel
import gleam/dynamic/decode
import gleam/io
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result

// Packet sent by Discord when a channel is updated
pub type ChannelUpdatePacket {
  ChannelUpdatePacket(t: String, s: Int, op: Int, d: channel.Channel)
}

pub fn string_to_data(encoded: String) -> Result(ChannelUpdatePacket, String) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)
    use d <- decode.field("d", channel.from_json_decoder())
    decode.success(ChannelUpdatePacket(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
  |> result.map_error(fn(err) {
    io.debug(err)
    "Failed to decode ChannelUpdate packet"
  })
}
