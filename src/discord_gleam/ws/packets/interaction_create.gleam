import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/channel
import discord_gleam/types/component_response
import discord_gleam/types/guild_member
import discord_gleam/types/role
import discord_gleam/types/user
import discord_gleam/ws/packets/message
import gleam/dict
import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None}

pub type InteractionData {
  InteractionCommand(
    type_: Int,
    name: String,
    id: Snowflake(snowflake.Interaction),
    options: Option(List(InteractionOption)),
  )

  ModalSubmitData(
    custom_id: String,
    components: List(component_response.ComponentResponse),
    resolved: Option(component_response.ResolvedData),
  )

  Empty
}

pub type InteractionOption {
  InteractionOption(
    name: String,
    type_: Int,
    value: OptionValue,
    options: Option(List(InteractionOption)),
  )
}

pub type InteractionType {
  Ping
  ApplicationCommand
  MessageComponent
  ApplicationCommandAutocomplete
  ModalSubmit
}

pub type InteractionCreatePacketData {
  InteractionCreatePacketData(
    id: Snowflake(snowflake.Interaction),
    application_id: Snowflake(snowflake.Application),
    type_: InteractionType,
    data: InteractionData,
    guild_id: Option(Snowflake(snowflake.Guild)),
    channel: Option(channel.Channel),
    channel_id: Snowflake(snowflake.Channel),
    member: Option(guild_member.GuildMember),
    user: Option(user.User),
    token: String,
    message: Option(message.MessagePacketData),
    app_permissions: String,
    locale: Option(String),
  )
}

pub type InteractionCreatePacket {
  InteractionCreatePacket(
    t: String,
    s: Int,
    op: Int,
    d: InteractionCreatePacketData,
  )
}

pub type OptionValue {
  StringValue(String)
  IntValue(Int)
  BoolValue(Bool)
  FloatValue(Float)
}

fn options_decoder() -> decode.Decoder(InteractionOption) {
  use name <- decode.field("name", decode.string)
  use type_ <- decode.field("type", decode.int)
  use value <- decode.field(
    "value",
    decode.one_of(decode.string |> decode.map(StringValue), or: [
      decode.int |> decode.map(IntValue),
      decode.bool |> decode.map(BoolValue),
      decode.float |> decode.map(FloatValue),
    ]),
  )

  use options <- decode.optional_field(
    "options",
    None,
    decode.optional(decode.list(options_decoder())),
  )

  decode.success(InteractionOption(name:, type_:, value:, options:))
}

pub fn from_json_string(
  encoded: String,
) -> Result(InteractionCreatePacket, json.DecodeError) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)
    use d <- decode.field("d", {
      use id <- decode.field("id", snowflake.decoder())

      use application_id <- decode.field("application_id", snowflake.decoder())

      use type_int <- decode.field("type", decode.int)

      let type_ = case type_int {
        1 -> Ping
        2 -> ApplicationCommand
        3 -> MessageComponent
        4 -> ApplicationCommandAutocomplete
        5 -> ModalSubmit
        _ -> Ping
      }

      use data <- decode.field("data", {
        case type_ {
          ApplicationCommand -> {
            use type_ <- decode.field("type", decode.int)
            use name <- decode.field("name", decode.string)
            use id <- decode.field("id", snowflake.decoder())

            use options <- decode.optional_field(
              "options",
              None,
              decode.optional(decode.list(options_decoder())),
            )

            decode.success(InteractionCommand(type_:, name:, id:, options:))
          }

          _ -> {
            decode.success(Empty)
          }
        }
      })

      use guild_id <- decode.optional_field(
        "guild_id",
        None,
        decode.optional(snowflake.decoder()),
      )

      use channel <- decode.optional_field(
        "channel",
        None,
        decode.optional(channel.json_decoder()),
      )

      use channel_id <- decode.field("channel_id", snowflake.decoder())

      use member <- decode.optional_field(
        "member",
        None,
        decode.optional(guild_member.json_decoder()),
      )

      use user <- decode.optional_field(
        "user",
        None,
        decode.optional(user.json_decoder()),
      )

      use token <- decode.field("token", decode.string)

      use message <- decode.optional_field(
        "message",
        None,
        decode.optional(message.data_json_decoder()),
      )

      use app_permissions <- decode.field("app_permissions", decode.string)

      use locale <- decode.optional_field(
        "locale",
        None,
        decode.optional(decode.string),
      )

      decode.success(InteractionCreatePacketData(
        id:,
        application_id:,
        type_:,
        data:,
        guild_id:,
        channel:,
        channel_id:,
        member:,
        user:,
        token:,
        message:,
        app_permissions:,
        locale:,
      ))
    })

    decode.success(InteractionCreatePacket(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
}
