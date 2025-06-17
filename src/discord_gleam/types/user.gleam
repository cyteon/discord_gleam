import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/internal/error
import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import gleam/result
import gleam/string

/// User object containing PartialUser and FullUser
/// FullUser is currently not implemented
pub type User {
  PartialUser(
    id: Snowflake,
    username: String,
    discriminator: String,
    avatar: Option(String),
  )
  FullUser(
    id: Snowflake,
    username: String,
    discriminator: String,
    avatar: Option(String),
    bot: Bool,
    system: Bool,
    mfa_enabled: Bool,
    banner: Option(String),
    accent_color: Option(Int),
    verified: Bool,
    email: Option(String),
    flags: Int,
    premium_type: Int,
    public_flags: Int,
  )
}

/// Decode a string to a PartialUser
pub fn string_to_data(encoded: String) -> Result(User, error.DiscordError) {
  case string.contains(encoded, "401: Unauthorized") {
    True -> {
      Error(error.Unauthorized("Error, 401, Unauthorized :c, is token correct?"))
    }
    False -> {
      let decoder = from_json_decoder()

      json.parse(from: encoded, using: from_json_decoder())
      |> result.map_error(error.JsonDecodeError)
    }
  }
}

pub fn from_json_decoder() -> decode.Decoder(User) {
  use id <- decode.field("id", snowflake.decoder())
  use username <- decode.field("username", decode.string)
  use discriminator <- decode.field("discriminator", decode.string)
  use avatar <- decode.field("avatar", decode.optional(decode.string))

  decode.success(PartialUser(id:, username:, discriminator:, avatar:))
}
