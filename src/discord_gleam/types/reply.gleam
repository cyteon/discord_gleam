import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/message.{
  type Embed, embed_to_json as message_embed_to_json,
}
import gleam/json
import gleam/list

/// Our reply type, which is used to send replies to messages
pub type Reply {
  Reply(
    content: String,
    message_id: Snowflake(snowflake.Message),
    embeds: List(Embed),
  )
}

/// Convert a reply to a JSON string
pub fn to_string(msg: Reply) -> String {
  let embeds_json = list.map(msg.embeds, message_embed_to_json)
  json.object([
    #("content", json.string(msg.content)),
    #("embeds", json.array(embeds_json, of: fn(x) { x })),
    #(
      "message_reference",
      json.object([
        #("message_id", json.string(snowflake.to_string(msg.message_id))),
      ]),
    ),
  ])
  |> json.to_string
}
