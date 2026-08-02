import discord_gleam/types/component
import discord_gleam/types/embed
import gleam/json
import gleam/list

pub type Message {
  Message(
    content: String,
    embeds: List(embed.Embed),
    components: List(component.Component),
    ephemeral: Bool,
  )
}

/// Create a new message with the given content, no embeds and components are there by default \
/// To add a embed or component use the add_embed and add_component functions
pub fn new(content: String) -> Message {
  Message(content: content, embeds: [], components: [], ephemeral: False)
}

/// Add a embed to a message
pub fn add_embed(msg: Message, embed: embed.Embed) -> Message {
  Message(..msg, embeds: list.append(msg.embeds, [embed]))
}

/// Add a component to a message
pub fn add_component(msg: Message, component: component.Component) -> Message {
  Message(..msg, components: list.append(msg.components, [component]))
}

pub fn set_ephemeral(msg: Message, ephemeral: Bool) -> Message {
  Message(..msg, ephemeral: ephemeral)
}

pub fn to_string(msg: Message) -> String {
  let embeds_json = list.map(msg.embeds, embed.embed_to_json)
  let components_json = list.map(msg.components, component.to_json)

  json.object([
    #("content", json.string(msg.content)),
    #("embeds", json.array(embeds_json, of: fn(x) { x })),
    #("components", json.array(components_json, of: fn(x) { x })),
    #("flags", case msg.ephemeral {
      True -> json.int(64)
      False -> json.null()
    }),
  ])
  |> json.to_string
}
