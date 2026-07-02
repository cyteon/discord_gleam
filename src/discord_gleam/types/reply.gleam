import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/component
import discord_gleam/types/embed.{embed_to_json as message_embed_to_json}
import discord_gleam/types/message
import gleam/json
import gleam/list

/// Our reply type, which is used to send replies to messages.
pub type Reply {
  Reply(message_id: Snowflake(snowflake.Message), reply: message.Message)
}

/// Convert a reply to a JSON string. \
/// Todo: deduplicate some of it cause content, embeds and components part is same as message.to_string.
pub fn to_string(msg: Reply) -> String {
  let embeds_json = list.map(msg.reply.embeds, message_embed_to_json)
  let components_json = list.map(msg.reply.components, component.to_json)

  json.object([
    #("content", json.string(msg.reply.content)),
    #("embeds", json.array(embeds_json, of: fn(x) { x })),
    #("components", json.array(components_json, of: fn(x) { x })),
    #(
      "message_reference",
      json.object([
        #("message_id", json.string(snowflake.to_string(msg.message_id))),
      ]),
    ),
  ])
  |> json.to_string
}
