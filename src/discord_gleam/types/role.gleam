import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/internal/error
import gleam/dynamic/decode
import gleam/json
import gleam/option
import gleam/result

/// See https://discord.com/developers/docs/topics/permissions#role-object \
/// This is a simplified version of the channel object.
pub type Role {
  Role(
    id: Snowflake,
    name: String,
    color: option.Option(Int),
    hoist: Bool,
    icon: option.Option(String),
    unicode_emoji: option.Option(String),
    position: Int,
    permissions: String,
    managed: Bool,
    mentionable: Bool,
    flags: Int,
  )
}

/// Convert a JSON string to a role object
pub fn string_to_data(encoded: String) -> Result(Role, error.DiscordError) {
  json.parse(from: encoded, using: from_json_decoder())
  |> result.map_error(error.JsonDecodeError)
}

pub fn from_json_decoder() -> decode.Decoder(Role) {
  use id <- decode.field("id", snowflake.decoder())
  use name <- decode.field("name", decode.string)
  use color <- decode.optional_field(
    "color",
    option.None,
    decode.optional(decode.int),
  )
  use hoist <- decode.field("hoist", decode.bool)
  use icon <- decode.optional_field(
    "icon",
    option.None,
    decode.optional(decode.string),
  )
  use unicode_emoji <- decode.optional_field(
    "unicode_emoji",
    option.None,
    decode.optional(decode.string),
  )
  use position <- decode.field("position", decode.int)
  use permissions <- decode.field("permissions", decode.string)
  use managed <- decode.field("managed", decode.bool)
  use mentionable <- decode.field("mentionable", decode.bool)
  use flags <- decode.field("flags", decode.int)

  decode.success(Role(
    id:,
    name:,
    color:,
    hoist:,
    icon:,
    unicode_emoji:,
    position:,
    permissions:,
    managed:,
    mentionable:,
    flags:,
  ))
}
