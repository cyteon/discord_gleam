import discord_gleam/types/component
import discord_gleam/types/embed
import discord_gleam/types/message
import gleam/option.{None, Some}

pub fn new_message_test() {
  let msg = message.new("Hello, world!")

  assert msg.content == "Hello, world!"
  assert msg.embeds == []
  assert msg.components == []
}

pub fn add_embed_test() {
  let msg =
    message.new("Hello, world!")
    |> message.add_embed(embed.new("t", "d", 0))

  assert msg.embeds == [embed.new("t", "d", 0)]
}

pub fn add_component_test() {
  let msg =
    message.new("Hello, world!")
    |> message.add_component(component.ActionRow(id: None, components: []))

  assert msg.components == [component.ActionRow(id: None, components: [])]
}
