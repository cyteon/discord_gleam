import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/activity
import gleam/dynamic/decode
import gleam/option.{type Option, None, Some}

pub type ClientStatus {
  ClientStatus(
    desktop: Option(String),
    mobile: Option(String),
    web: Option(String),
  )
}

// NOTE: `PRESENCE_UPDATE` packet includes only user id?

pub type PresenceUser {
  PresenceUser(id: Snowflake)
}

pub type Presence {
  Presence(
    user: PresenceUser,
    // NOTE: does not exist?
    // guild_id: Snowflake,
    status: String,
    activities: List(activity.Activity),
    client_status: ClientStatus,
  )
}

pub fn from_json_decoder() -> decode.Decoder(Presence) {
  use user <- decode.field("user", presence_user_decoder())
  // use guild_id <- decode.field("guild_id", snowflake.decoder())
  use status <- decode.field("status", decode.string)
  use activities <- decode.field(
    "activities",
    decode.list(activity.from_json_decoder()),
  )
  use client_status <- decode.field("client_status", client_status_decoder())

  decode.success(Presence(
    user:,
    // guild_id:,
    status:,
    activities:,
    client_status:,
  ))
}

pub fn presence_user_decoder() -> decode.Decoder(PresenceUser) {
  use id <- decode.field("id", snowflake.decoder())
  decode.success(PresenceUser(id:))
}

pub fn client_status_decoder() {
  use desktop <- decode.optional_field(
    "desktop",
    None,
    decode.string |> decode.map(Some),
  )
  use mobile <- decode.optional_field(
    "mobile",
    None,
    decode.string |> decode.map(Some),
  )
  use web <- decode.optional_field(
    "web",
    None,
    decode.string |> decode.map(Some),
  )

  decode.success(ClientStatus(desktop:, mobile:, web:))
}
