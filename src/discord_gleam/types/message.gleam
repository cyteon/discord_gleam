import discord_gleam/types/component
import discord_gleam/types/embed
import gleam/json
import gleam/list

pub type MessageBuilder {
  MessageBuilder(
    content: String,
    embeds: List(embed.Embed),
    components: List(component.Component),
  )
}

/// Create a new message with the given content, no embeds and components are there by default \
/// To add a embed or component use the add_embed and add_component functions
pub fn new(content: String) -> MessageBuilder {
  MessageBuilder(content: content, embeds: [], components: [])
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

pub fn to_string(msg: MessageBuilder) -> String {
  let embeds_json = list.map(msg.embeds, embed.to_json)
  let components_json = list.map(msg.components, component.to_json)

  json.object([
    #("content", json.string(msg.content)),
    #("embeds", json.array(embeds_json, of: fn(x) { x })),
    #("components", json.array(components_json, of: fn(x) { x })),
  ])
  |> json.to_string
}
