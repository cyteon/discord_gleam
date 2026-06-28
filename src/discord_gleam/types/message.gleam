import discord_gleam/types/embed
import gleam/json
import gleam/list

pub type Message {
  Message(content: String, embeds: List(embed.Embed))
}

pub fn to_string(msg: Message) -> String {
  let embeds_json = list.map(msg.embeds, embed.embed_to_json)
  json.object([
    #("content", json.string(msg.content)),
    #("embeds", json.array(embeds_json, of: fn(x) { x })),
  ])
  |> json.to_string
}
