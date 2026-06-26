import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/user
import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}

pub type InteractionCreateMember {
  InteractionCreateMember(user: user.User)
}

pub type InteractionCommand {
  InteractionCommand(
    type_: Int,
    name: String,
    id: Snowflake,
    options: Option(List(InteractionOption)),
  )
}

pub type InteractionOption {
  InteractionOption(
    name: String,
    type_: Int,
    value: OptionValue,
    options: Option(List(InteractionOption)),
  )
}

pub type InteractionCreateData {
  InteractionCreateData(
    token: String,
    member: Option(InteractionCreateMember),
    user: Option(user.User),
    id: Snowflake,
    guild_id: Option(Snowflake),
    data: InteractionCommand,
    channel_id: Snowflake,
  )
}

pub type InteractionCreatePacket {
  InteractionCreatePacket(t: String, s: Int, op: Int, d: InteractionCreateData)
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
    option.None,
    decode.optional(decode.list(options_decoder())),
  )

  decode.success(InteractionOption(name:, type_:, value:, options:))
}

pub fn string_to_data(
  encoded: String,
) -> Result(InteractionCreatePacket, json.DecodeError) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)
    use d <- decode.field("d", {
      use token <- decode.field("token", decode.string)

      use member <- decode.optional_field(
        "member",
        option.None,
        decode.optional({
          use user <- decode.field("user", user.from_json_decoder())
          decode.success(InteractionCreateMember(user:))
        }),
      )
      use user <- decode.optional_field(
        "user",
        option.None,
        decode.optional(user.from_json_decoder()),
      )

      use id <- decode.field("id", snowflake.decoder())
      use guild_id <- decode.optional_field(
        "guild_id",
        option.None,
        decode.optional(snowflake.decoder()),
      )

      use data <- decode.field("data", {
        use type_ <- decode.field("type", decode.int)
        use name <- decode.field("name", decode.string)
        use id <- decode.field("id", snowflake.decoder())

        use options <- decode.optional_field(
          "options",
          option.None,
          decode.optional(decode.list(options_decoder())),
        )

        decode.success(InteractionCommand(type_:, name:, id:, options:))
      })

      use channel_id <- decode.field("channel_id", snowflake.decoder())
      decode.success(InteractionCreateData(
        token:,
        member:,
        user:,
        id:,
        guild_id:,
        data:,
        channel_id:,
      ))
    })
    decode.success(InteractionCreatePacket(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
}
