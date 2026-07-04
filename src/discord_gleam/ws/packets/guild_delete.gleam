import discord_gleam/discord/snowflake.{type Snowflake}
import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None}

pub type GuildDeleteData {
  GuildDeleteData(id: Snowflake(snowflake.Guild), unavailable: Option(Bool))
}

pub type GuildDeletePacket {
  GuildDeletePacket(t: String, s: Int, op: Int, d: GuildDeleteData)
}

pub fn from_json_string(
  encoded: String,
) -> Result(GuildDeletePacket, json.DecodeError) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)
    use d <- decode.field("d", {
      use id <- decode.field("id", snowflake.decoder())
      use unavailable <- decode.optional_field(
        "unavailable",
        None,
        decode.optional(decode.bool),
      )

      decode.success(GuildDeleteData(id:, unavailable:))
    })
    decode.success(GuildDeletePacket(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
}
