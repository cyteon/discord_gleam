import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/component
import discord_gleam/types/embed
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}

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
