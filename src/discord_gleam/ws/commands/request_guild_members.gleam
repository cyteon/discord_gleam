import discord_gleam/bot
import discord_gleam/discord/snowflake.{type Snowflake}
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}

pub type RequestGuildMembersOption {
  Query(String, limit: Option(Int))
  UserIds(List(Snowflake(snowflake.User)))
}

pub type RequestGuildMembersData {
  RequestGuildMembersData(
    guild_id: Snowflake(snowflake.Guild),
    option: RequestGuildMembersOption,
    presences: Option(Bool),
    nonce: Option(String),
  )
}

pub fn request_guild_members(
  bot: bot.Bot,
  guild_id guild_id: Snowflake(snowflake.Guild),
  option option: RequestGuildMembersOption,
  presences presences: Option(Bool),
  nonce nonce: Option(String),
) -> Nil {
  let data = RequestGuildMembersData(guild_id:, option:, presences:, nonce:)

  let packet =
    json.object([#("op", json.int(8)), #("d", data_to_json(data))])
    |> json.to_string()

  bot.send_packet(bot, packet)
}

fn data_to_json(data: RequestGuildMembersData) -> json.Json {
  let fields = [
    #("guild_id", json.string(snowflake.to_string(data.guild_id))),
  ]

  let fields = case data.presences {
    Some(presences) ->
      list.append(fields, [#("presences", json.bool(presences))])
    None -> fields
  }

  let fields = case data.nonce {
    Some(nonce) -> list.append(fields, [#("nonce", json.string(nonce))])
    None -> fields
  }

  case data.option {
    Query(query, limit) ->
      list.append(fields, [
        #("query", json.string(query)),
        #("limit", json.int(option.unwrap(limit, 0))),
      ])
    UserIds(user_ids) ->
      list.append(fields, [
        #(
          "user_ids",
          json.array(user_ids, of: fn(id) {
            json.string(snowflake.to_string(id))
          }),
        ),
      ])
  }
  |> json.object()
}
