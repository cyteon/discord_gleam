import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/user
import gleam/dynamic/decode
import gleam/option.{type Option, None}

pub type Emoji {
  Emoji(
    id: Option(Snowflake(snowflake.Emoji)),
    name: Option(String),
    roles: Option(List(Snowflake(snowflake.Role))),
    user: Option(user.User),
    require_colons: Option(Bool),
    managed: Option(Bool),
    animated: Option(Bool),
    available: Option(Bool),
  )
}

pub fn json_decoder() -> decode.Decoder(Emoji) {
  use id <- decode.optional_field(
    "id",
    None,
    decode.optional(snowflake.decoder()),
  )

  use name <- decode.optional_field(
    "name",
    None,
    decode.optional(decode.string),
  )

  use roles <- decode.optional_field(
    "roles",
    None,
    decode.optional(decode.list(of: snowflake.decoder())),
  )

  use user <- decode.optional_field(
    "user",
    None,
    decode.optional(user.json_decoder()),
  )

  use require_colons <- decode.optional_field(
    "require_colons",
    None,
    decode.optional(decode.bool),
  )

  use managed <- decode.optional_field(
    "managed",
    None,
    decode.optional(decode.bool),
  )

  use animated <- decode.optional_field(
    "animated",
    None,
    decode.optional(decode.bool),
  )

  use available <- decode.optional_field(
    "available",
    None,
    decode.optional(decode.bool),
  )

  decode.success(Emoji(
    id:,
    name:,
    roles:,
    user:,
    require_colons:,
    managed:,
    animated:,
    available:,
  ))
}
