import discord_gleam/discord/snowflake
import discord_gleam/types/component
import discord_gleam/types/embed
import discord_gleam/types/message
import gleam/dynamic/decode
import gleam/json
import gleam/option.{None}

pub fn new_message_test() {
  let msg = message.new("Hello, world!")
  let json = message.to_json(msg)

  assert json
    == json.object([
      #("content", json.string("Hello, world!")),
      #("embeds", json.array([], of: fn(x) { x })),
      #("components", json.array([], of: fn(x) { x })),
    ])
}

pub fn add_embed_test() {
  let msg =
    message.new("Hello, world!")
    |> message.add_embed(embed.new("t", "d", 0))

  let assert Ok(embeds) =
    json.parse(
      message.to_string(msg),
      decode.at(["embeds"], decode.list(embed.json_decoder())),
    )
  assert embeds == [embed.new("t", "d", 0)]
}

pub fn add_component_test() {
  let msg =
    message.new("Hello, world!")
    |> message.add_component(component.ActionRow(id: None, components: []))

  let assert Ok(types) =
    json.parse(
      message.to_string(msg),
      decode.at(["components"], decode.list(decode.at(["type"], decode.int))),
    )

  assert types == [1]
}

pub fn ephemeral_test() {
  let msg =
    message.new("Hello, world!")
    |> message.ephemeral

  let assert Ok(flags) =
    json.parse(message.to_string(msg), decode.at(["flags"], decode.int))
  assert flags == 64
}

pub fn reply_test() {
  let msg =
    message.new("Hello, world!")
    |> message.reply_to(snowflake.from_string("1"))

  let assert Ok(message_id) =
    json.parse(
      message.to_string(msg),
      decode.at(["message_reference", "message_id"], decode.string),
    )
  assert message_id == "1"
}
