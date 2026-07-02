import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/channel
import discord_gleam/types/embed
import discord_gleam/types/user
import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None}

/// Represents a message packet data structure, also used on message update
pub type MessagePacketData {
  MessagePacketData(
    id: Snowflake(snowflake.Message),
    guild_id: Option(Snowflake(snowflake.Guild)),
    channel_id: Snowflake(snowflake.Channel),
    author: user.User,
    content: String,
    timestamp: String,
    edited_timestamp: Option(String),
    tts: Bool,
    mention_everyone: Bool,
    mentions: List(user.User),
    mention_roles: List(Snowflake(snowflake.Role)),
    // todo: mention_channels: list of channel mention objects
    // todo: attachments: list of attachment objects
    embeds: List(embed.Embed),
    // todo: reactions: list of reaction objects
    nonce: Option(String),
    pinned: Bool,
    webhook_id: Option(Snowflake(snowflake.Webhook)),
    // todo: make this a message type enum
    type_: Int,
    // todo: activity: message activity object
    // todo: application: partial application object
    application_id: Option(Snowflake(snowflake.Application)),
    flags: Option(Int),
    // todo: message_refrence: message reference object
    // todo: message_snapshots: array of message snapshot objects
    referenced_message: Option(MessagePacketData),
    // todo: interaction_metadata: message interaction metadata object
    // todo: interaction: message interaction object
    thread: Option(channel.Channel),
    // todo: components: array of message components
    // todo: sticker_items: array of sticker item objects
    // todo: stickers: array of sticker objects
    position: Option(Int),
    // todo: role_subscription_data: role subscription data object
    // todo: resolved: resolved data
    // todo: poll: poll object
    // todo: call: message call object
    // todo: shared_client_theme: shared client theme object
  )
}

// Packet sent by Discord when a message is sent
pub type MessagePacket {
  MessagePacket(t: String, s: Int, op: Int, d: MessagePacketData)
}

pub fn from_json_string(
  encoded: String,
) -> Result(MessagePacket, json.DecodeError) {
  json.parse(from: encoded, using: json_decoder())
}

pub fn data_json_decoder() -> decode.Decoder(MessagePacketData) {
  use id <- decode.field("id", snowflake.decoder())
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(snowflake.decoder()),
  )

  use channel_id <- decode.field("channel_id", snowflake.decoder())

  use author <- decode.field("author", user.json_decoder())

  use content <- decode.field("content", decode.string)

  use timestamp <- decode.field("timestamp", decode.string)

  use edited_timestamp <- decode.optional_field(
    "edited_timestamp",
    None,
    decode.optional(decode.string),
  )

  use tts <- decode.field("tts", decode.bool)

  use mention_everyone <- decode.field("mention_everyone", decode.bool)

  use mentions <- decode.field("mentions", decode.list(user.json_decoder()))

  use mention_roles <- decode.field(
    "mention_roles",
    decode.list(snowflake.decoder()),
  )

  // todo: mention_channels
  // todo: attachments

  use embeds <- decode.field("embeds", decode.list(embed.json_decoder()))

  // todo: reactions

  use nonce <- decode.optional_field(
    "nonce",
    None,
    decode.optional(decode.string),
  )

  use pinned <- decode.field("pinned", decode.bool)

  use webhook_id <- decode.optional_field(
    "webhook_id",
    None,
    decode.optional(snowflake.decoder()),
  )

  use type_ <- decode.field("type", decode.int)

  // todo: activity
  // todo: application

  use application_id <- decode.optional_field(
    "application_id",
    None,
    decode.optional(snowflake.decoder()),
  )

  use flags <- decode.optional_field("flags", None, decode.optional(decode.int))

  // todo: message_refrence
  // todo: message_snapshots

  use referenced_message <- decode.optional_field(
    "referenced_message",
    None,
    decode.optional(data_json_decoder()),
  )

  // todo: interaction_metadata
  // todo: interaction

  use thread <- decode.optional_field(
    "thread",
    None,
    decode.optional(channel.json_decoder()),
  )

  // todo: components
  // todo: sticker_items
  // todo: stickers

  use position <- decode.optional_field(
    "position",
    None,
    decode.optional(decode.int),
  )

  // todo: role_subscription_data
  // todo: resolved
  // todo: poll
  // todo: call
  // todo: shared_client_theme

  decode.success(MessagePacketData(
    id:,
    guild_id:,
    channel_id:,
    author:,
    content:,
    timestamp:,
    edited_timestamp:,
    tts:,
    mention_everyone:,
    mentions:,
    mention_roles:,
    // todo: mention_channels
    // todo: attachments
    embeds:,
    // todo: reactions
    nonce:,
    pinned:,
    webhook_id:,
    type_:,
    // todo: activity
    // todo: application
    application_id:,
    flags:,
    // todo: message_refrence
    // todo: message_snapshots
    referenced_message:,
    // todo: interaction_metadata
    // todo: interaction
    thread:,
    // todo: components
    // todo: sticker_items
    // todo: stickers
    position:,
    // todo: role_subscription_data
  // todo: resolved
  // todo: poll
  // todo: call
  // todo: shared_client_theme
  ))
}

pub fn json_decoder() -> decode.Decoder(MessagePacket) {
  use t <- decode.field("t", decode.string)
  use s <- decode.field("s", decode.int)
  use op <- decode.field("op", decode.int)
  use d <- decode.field("d", data_json_decoder())

  decode.success(MessagePacket(t:, s:, op:, d:))
}
