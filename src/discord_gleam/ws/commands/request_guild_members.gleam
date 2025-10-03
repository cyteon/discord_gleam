import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/bot
import gleam/erlang/process
import gleam/json
import gleam/list
import gleam/option.{type Option}

pub type RequestGuildMembersOption {
  Query(String, limit: Option(Int))
  UserIds(List(Snowflake))
}

pub type RequestGuildMembersData {
  RequestGuildMembersData(
    guild_id: Snowflake,
    option: RequestGuildMembersOption,
    presences: Option(Bool),
    nonce: Option(String),
  )
}

pub fn request_guild_members(
  bot: bot.Bot,
  guild_id guild_id: Snowflake,
  option option: RequestGuildMembersOption,
  presences presences: Option(Bool),
  nonce nonce: Option(String),
) -> Nil {
  let data = RequestGuildMembersData(guild_id:, option:, presences:, nonce:)

  let packet =
    json.object([#("op", json.int(8)), #("d", data_to_json(data))])
    |> json.to_string()

  process.send(bot.subject, bot.SendPacket(packet))
}

fn data_to_json(data: RequestGuildMembersData) -> json.Json {
  let fields = [
    #("guild_id", json.string(data.guild_id)),
  ]

  let fields = case data.presences {
    option.Some(presences) ->
      list.append(fields, [#("presences", json.bool(presences))])
    option.None -> fields
  }

  let fields = case data.nonce {
    option.Some(nonce) -> list.append(fields, [#("nonce", json.string(nonce))])
    option.None -> fields
  }

  case data.option {
    Query(query, limit) ->
      list.append(fields, [
        #("query", json.string(query)),
        #("limit", json.int(option.unwrap(limit, 0))),
      ])
    UserIds(user_ids) ->
      list.append(fields, [#("user_ids", json.array(user_ids, of: json.string))])
  }
  |> json.object()
}
