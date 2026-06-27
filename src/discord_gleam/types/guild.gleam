import discord_gleam/discord/snowflake.{type Snowflake}
import gleam/dynamic/decode

/// See https://discord.com/developers/docs/resources/guild#guild-resource \
pub type Guild {
  UnavailableGuild(id: Snowflake(snowflake.Guild), unavailable: Bool)
  // TODO: Implement guild structure
  Guild(id: Snowflake(snowflake.Guild))
}

pub fn json_decoder() -> decode.Decoder(Guild) {
  use id <- decode.field("id", snowflake.decoder())
  use unavailable <- decode.optional_field("unavailable", False, decode.bool)

  case unavailable {
    True -> decode.success(UnavailableGuild(id:, unavailable:))
    False -> decode.success(Guild(id:))
  }
}
