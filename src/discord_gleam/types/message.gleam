import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/internal/error
import discord_gleam/types/channel
import discord_gleam/types/component
import discord_gleam/types/embed
import discord_gleam/types/user
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result

/// Type used for building outbound messages to send.
pub opaque type MessageBuilder {
  MessageBuilder(
    reply_to: Option(Snowflake(snowflake.Message)),
    content: Option(String),
    embeds: List(embed.Embed),
    components: List(component.Component),
    flags: Int,
  )
}

const ephemeral_flag = 64

/// Create a new message with the given content, no embeds and components are there by default \
/// To add a embed or component use the add_embed and add_component functions
pub fn new(content: String) -> MessageBuilder {
  MessageBuilder(
    reply_to: None,
    content: Some(content),
    embeds: [],
    components: [],
    flags: 0,
  )
}

/// Creates a new message object with no content
pub fn empty() -> MessageBuilder {
  MessageBuilder(
    reply_to: None,
    content: None,
    embeds: [],
    components: [],
    flags: 0,
  )
}

/// Set a message to be a reply to a message
pub fn reply_to(
  msg: MessageBuilder,
  message_id: Snowflake(snowflake.Message),
) -> MessageBuilder {
  MessageBuilder(..msg, reply_to: Some(message_id))
}

/// Add a embed to a message
pub fn add_embed(msg: MessageBuilder, embed: embed.Embed) -> MessageBuilder {
  MessageBuilder(..msg, embeds: list.append(msg.embeds, [embed]))
}

/// Add a component to a message
pub fn add_component(
  msg: MessageBuilder,
  component: component.Component,
) -> MessageBuilder {
  MessageBuilder(..msg, components: list.append(msg.components, [component]))
}

/// Make a message ephemeral, only works for interactions
pub fn ephemeral(msg: MessageBuilder) -> MessageBuilder {
  MessageBuilder(..msg, flags: int.bitwise_or(msg.flags, ephemeral_flag))
}

pub fn to_string(msg: MessageBuilder) -> String {
  to_json(msg)
  |> json.to_string
}

pub fn to_json(msg: MessageBuilder) -> json.Json {
  let embeds_json = list.map(msg.embeds, embed.to_json)
  let components_json = list.map(msg.components, component.to_json)

  let fields = [
    #("embeds", json.array(embeds_json, of: fn(x) { x })),
    #("components", json.array(components_json, of: fn(x) { x })),
  ]

  let fields = case msg.content {
    None -> fields
    Some(content) -> [#("content", json.string(content)), ..fields]
  }

  let fields = case msg.flags {
    0 -> fields
    flags -> [#("flags", json.int(flags)), ..fields]
  }

  let fields = case msg.reply_to {
    None -> fields
    Some(message_id) -> [
      #(
        "message_reference",
        json.object([
          #("message_id", json.string(snowflake.to_string(message_id))),
        ]),
      ),
      ..fields
    ]
  }

  json.object(fields)
}

/// A message object received from discord
pub type Message {
  Message(
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
    referenced_message: Option(Message),
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

pub fn from_json_string(
  encoded: String,
) -> Result(Message, error.DiscordError) {
  json.parse(from: encoded, using: json_decoder())
  |> result.map_error(error.JsonDecodeError)
}

pub fn json_decoder() -> decode.Decoder(Message) {
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
    decode.optional(json_decoder()),
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

  decode.success(Message(
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
