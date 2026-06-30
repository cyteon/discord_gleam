import discord_gleam/types/component
import discord_gleam/types/embed
import gleam/json
import gleam/list

pub type Message {
  Message(
    content: String,
    embeds: List(embed.Embed),
    components: List(component.Component),
  )
}

/// Create a new message with the given content, no embeds and components are there by default \
/// To add a embed or component use the add_embed and add_component functions
pub fn new(content: String) -> Message {
  Message(content: content, embeds: [], components: [])
}

/// Add a embed to a message
pub fn add_embed(msg: Message, embed: embed.Embed) -> Message {
  Message(..msg, embeds: list.append(msg.embeds, [embed]))
}

/// Add a component to a message
pub fn add_component(msg: Message, component: component.Component) -> Message {
  Message(..msg, components: list.append(msg.components, [component]))
}

pub fn to_string(msg: Message) -> String {
  let embeds_json = list.map(msg.embeds, embed.embed_to_json)

  json.object([
    #("content", json.string(msg.content)),
    #("embeds", json.array(embeds_json, of: fn(x) { x })),
    #(
      "components",
      json.array(list.map(msg.components, component.to_json), of: fn(x) { x }),
    ),
  ])
  |> json.to_string
}
