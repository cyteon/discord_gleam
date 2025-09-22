import discord_gleam/discord/snowflake.{type Snowflake}
import gleam/dynamic/decode
import gleam/option.{type Option, None, Some}
import gleam/string

pub type ActivityTimestamp {
  ActivityTimestamp(start: Option(Int), end: Option(Int))
}

pub type ActivityEmoji {
  ActivityEmoji(name: String, id: Option(Snowflake), animated: Option(Bool))
}

pub type ActivityParty {
  ActivityParty(id: Option(String), size: Option(#(Int, Int)))
}

pub type ActivityAssets {
  ActivityAssets(
    large_image: Option(String),
    large_text: Option(String),
    large_url: Option(String),
    small_image: Option(String),
    small_text: Option(String),
    small_url: Option(String),
  )
}

pub type ActivitySecrets {
  ActivitySecrets(
    join: Option(String),
    spectate: Option(String),
    match: Option(String),
  )
}

pub type ActivityButton {
  ActivityButton(label: String, url: String)
}

/// See https://discord.com/developers/docs/events/gateway-events#activity-object
pub type Activity {
  Activity(
    name: String,
    type_: Int,
    url: Option(String),
    created_at: Int,
    timestamps: Option(ActivityTimestamp),
    application_id: Option(Snowflake),
    status_display_type: Option(Int),
    details: Option(String),
    details_url: Option(String),
    state: Option(String),
    state_url: Option(String),
    emoji: Option(ActivityEmoji),
    party: Option(ActivityParty),
    assets: Option(ActivityAssets),
    secrets: Option(ActivitySecrets),
    instance: Option(Bool),
    flags: Option(Int),
    buttons: Option(List(ActivityButton)),
  )
}

pub fn from_json_decoder() -> decode.Decoder(Activity) {
  use name <- decode.field("name", decode.string)
  use type_ <- decode.field("type", decode.int)
  use url <- decode.optional_field("url", None, decode.optional(decode.string))
  use created_at <- decode.field("created_at", decode.int)
  use timestamps <- decode.optional_field(
    "timestamps",
    None,
    decode.optional(activity_timestamp_decoder()),
  )
  use application_id <- decode.optional_field(
    "application_id",
    None,
    decode.optional(snowflake.decoder()),
  )
  use status_display_type <- decode.optional_field(
    "status_display_type",
    None,
    decode.optional(decode.int),
  )
  use details <- decode.optional_field(
    "details",
    None,
    decode.optional(decode.string),
  )
  use details_url <- decode.optional_field(
    "details_url",
    None,
    decode.optional(decode.string),
  )
  use state <- decode.optional_field(
    "state",
    None,
    decode.optional(decode.string),
  )
  use state_url <- decode.optional_field(
    "state_url",
    None,
    decode.optional(decode.string),
  )
  use emoji <- decode.optional_field(
    "emoji",
    None,
    decode.optional(activity_emoji_decoder()),
  )
  use party <- decode.optional_field(
    "party",
    None,
    decode.optional(activity_party_decoder()),
  )
  use assets <- decode.optional_field(
    "assets",
    None,
    decode.optional(activity_assets_decoder()),
  )
  use secrets <- decode.optional_field(
    "secrets",
    None,
    decode.optional(activity_secrets_decoder()),
  )
  use instance <- decode.optional_field(
    "instance",
    None,
    decode.optional(decode.bool),
  )
  use flags <- decode.optional_field("flags", None, decode.optional(decode.int))
  use buttons <- decode.optional_field(
    "buttons",
    None,
    decode.optional(decode.list(of: activity_button_decoder())),
  )

  decode.success(Activity(
    name:,
    type_:,
    url:,
    created_at:,
    timestamps:,
    application_id:,
    status_display_type:,
    details:,
    details_url:,
    state:,
    state_url:,
    emoji:,
    party:,
    assets:,
    secrets:,
    instance:,
    flags:,
    buttons:,
  ))
}

fn activity_timestamp_decoder() {
  use start <- decode.optional_field("start", None, decode.optional(decode.int))
  use end <- decode.optional_field("end", None, decode.optional(decode.int))
  decode.success(ActivityTimestamp(start:, end:))
}

fn activity_emoji_decoder() {
  use name <- decode.field("name", decode.string)
  use id <- decode.optional_field(
    "id",
    None,
    decode.optional(snowflake.decoder()),
  )
  use animated <- decode.optional_field(
    "animated",
    None,
    decode.optional(decode.bool),
  )
  decode.success(ActivityEmoji(name:, id:, animated:))
}

fn activity_party_decoder() {
  use id <- decode.optional_field("id", None, decode.optional(decode.string))
  use size <- decode.optional_field(
    "size",
    None,
    decode.optional(decode.list(of: decode.int)),
  )

  case size {
    Some([current_size, max_size]) ->
      decode.success(ActivityParty(id:, size: Some(#(current_size, max_size))))
    Some(_) ->
      decode.failure(
        ActivityParty(None, None),
        "Expected list of two ints, but found " <> string.inspect(size),
      )
    None -> decode.success(ActivityParty(id:, size: None))
  }
}

fn activity_assets_decoder() {
  use large_image <- decode.optional_field(
    "large_image",
    None,
    decode.optional(decode.string),
  )
  use large_text <- decode.optional_field(
    "large_text",
    None,
    decode.optional(decode.string),
  )
  use large_url <- decode.optional_field(
    "large_url",
    None,
    decode.optional(decode.string),
  )
  use small_image <- decode.optional_field(
    "small_image",
    None,
    decode.optional(decode.string),
  )
  use small_text <- decode.optional_field(
    "small_text",
    None,
    decode.optional(decode.string),
  )
  use small_url <- decode.optional_field(
    "small_url",
    None,
    decode.optional(decode.string),
  )
  decode.success(ActivityAssets(
    large_image:,
    large_text:,
    large_url:,
    small_image:,
    small_text:,
    small_url:,
  ))
}

fn activity_secrets_decoder() {
  use join <- decode.optional_field(
    "join",
    None,
    decode.optional(decode.string),
  )
  use spectate <- decode.optional_field(
    "spectate",
    None,
    decode.optional(decode.string),
  )
  use match <- decode.optional_field(
    "match",
    None,
    decode.optional(decode.string),
  )
  decode.success(ActivitySecrets(join:, spectate:, match:))
}

fn activity_button_decoder() {
  use label <- decode.field("label", decode.string)
  use url <- decode.field("url", decode.string)
  decode.success(ActivityButton(label:, url:))
}
