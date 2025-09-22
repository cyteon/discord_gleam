import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/user
import gleam/dynamic/decode
import gleam/option.{type Option, None}

pub type GuildMember {
  GuildMember(
    user: user.User,
    nick: Option(String),
    avatar: Option(String),
    banner: Option(String),
    roles: List(Snowflake),
    // ISO8601 timestamp?
    joined_at: String,
    premium_since: Option(String),
    deaf: Bool,
    mute: Bool,
    flags: Int,
    pending: Option(Bool),
    permissions: Option(String),
    communication_disabled_until: Option(String),
    avatar_decoration: Option(user.AvatarDecoration),
  )
}

pub fn from_json_decoder() -> decode.Decoder(GuildMember) {
  use user <- decode.field("user", user.from_json_decoder())
  use nick <- decode.optional_field(
    "nick",
    None,
    decode.optional(decode.string),
  )
  use avatar <- decode.optional_field(
    "avatar",
    None,
    decode.optional(decode.string),
  )
  use banner <- decode.optional_field(
    "banner",
    None,
    decode.optional(decode.string),
  )
  use roles <- decode.field("roles", decode.list(of: snowflake.decoder()))
  use joined_at <- decode.field("joined_at", decode.string)
  use premium_since <- decode.optional_field(
    "premium_since",
    None,
    decode.optional(decode.string),
  )
  use deaf <- decode.field("deaf", decode.bool)
  use mute <- decode.field("mute", decode.bool)
  use flags <- decode.field("flags", decode.int)
  use pending <- decode.optional_field(
    "pending",
    None,
    decode.optional(decode.bool),
  )
  use permissions <- decode.optional_field(
    "permissions",
    None,
    decode.optional(decode.string),
  )
  use communication_disabled_until <- decode.optional_field(
    "communication_disabled_until",
    None,
    decode.optional(decode.string),
  )
  use avatar_decoration <- decode.optional_field(
    "avatar_decoration",
    None,
    decode.optional(user.avatar_decoration_decoder()),
  )

  decode.success(GuildMember(
    user:,
    nick:,
    avatar:,
    banner:,
    roles:,
    joined_at:,
    premium_since:,
    deaf:,
    mute:,
    flags:,
    pending:,
    permissions:,
    communication_disabled_until:,
    avatar_decoration:,
  ))
}
