import discord_gleam/discord/snowflake
import discord_gleam/types/embed
import discord_gleam/types/message
import discord_gleam/types/reply

pub fn new_reply_test() {
  let message =
    message.new("reply!")
    |> message.add_embed(embed.new("t", "d", 0))

  let reply =
    reply.Reply(message_id: snowflake.from_string("a"), reply: message)

  assert reply.message_id == snowflake.from_string("a")
  assert reply.reply.content == "reply!"
  assert reply.reply.embeds == [embed.new("t", "d", 0)]
}

pub fn to_json_test() {
  let message =
    message.new("reply!")
    |> message.add_embed(embed.new("t", "d", 0))

  let reply =
    reply.Reply(message_id: snowflake.from_string("a"), reply: message)

  let json = reply.to_string(reply)

  assert json
    == "{\"content\":\"reply!\",\"embeds\":[{\"title\":\"t\",\"description\":\"d\",\"color\":0}],\"components\":[],\"message_reference\":{\"message_id\":\"a\"}}"
}
