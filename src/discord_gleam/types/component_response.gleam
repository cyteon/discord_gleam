import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/channel
import discord_gleam/types/guild_member
import discord_gleam/types/role
import discord_gleam/types/user
import discord_gleam/ws/packets/message
import gleam/dict
import gleam/dynamic/decode
import gleam/list
import gleam/option.{type Option, None, Some}

pub type ResolvedData {
  ResolvedData(
    users: Option(dict.Dict(Snowflake(snowflake.User), user.User)),
    members: Option(
      dict.Dict(Snowflake(snowflake.User), guild_member.GuildMember),
    ),
    roles: Option(dict.Dict(Snowflake(snowflake.Role), role.Role)),
    channels: Option(dict.Dict(Snowflake(snowflake.Channel), channel.Channel)),
    messages: Option(
      dict.Dict(Snowflake(snowflake.Message), message.MessagePacketData),
    ),
    // todo: attachments
  )
}

pub type Mentionable {
  MentionableUser(Snowflake(snowflake.User))
  MentionableRole(Snowflake(snowflake.Role))
}

pub type ComponentResponse {
  // 3
  StringSelectResponse(id: Int, custom_id: String, values: List(String))

  // 4
  TextInputResponse(id: Int, custom_id: String, value: String)

  // 5
  UserSelectResponse(
    id: Int,
    custom_id: String,
    resolved: ResolvedData,
    values: List(Snowflake(snowflake.User)),
  )

  // 6
  RoleSelectResponse(
    id: Int,
    custom_id: String,
    resolved: ResolvedData,
    values: List(Snowflake(snowflake.Role)),
  )

  // 7
  MentionableSelectResponse(
    id: Int,
    custom_id: String,
    resolved: ResolvedData,
    values: List(Mentionable),
  )

  // 8
  ChannelSelectResponse(
    id: Int,
    custom_id: String,
    resolved: ResolvedData,
    values: List(Snowflake(snowflake.Channel)),
  )

  // 10
  TextDisplayResponse

  // 18
  LabelResponse(component: ComponentResponse)

  // 19
  FileUploadResponse(
    id: Int,
    custom_id: String,
    values: List(Snowflake(snowflake.Attachment)),
  )

  // 21
  RadioGroupResponse(id: Int, custom_id: String, value: Option(String))

  // 22
  CheckboxGroupResponse(id: Int, custom_id: String, values: List(String))

  // 23
  CheckboxResponse(id: Int, custom_id: String, value: Bool)
}

pub fn resolved_data_decoder() -> decode.Decoder(ResolvedData) {
  use users <- decode.optional_field(
    "users",
    None,
    decode.optional(decode.dict(snowflake.decoder(), user.json_decoder())),
  )

  use members <- decode.optional_field(
    "members",
    None,
    decode.optional(decode.dict(
      snowflake.decoder(),
      guild_member.json_decoder(),
    )),
  )

  use roles <- decode.optional_field(
    "roles",
    None,
    decode.optional(decode.dict(snowflake.decoder(), role.json_decoder())),
  )

  use channels <- decode.optional_field(
    "channels",
    None,
    decode.optional(decode.dict(snowflake.decoder(), channel.json_decoder())),
  )

  use messages <- decode.optional_field(
    "messages",
    None,
    decode.optional(decode.dict(
      snowflake.decoder(),
      message.data_json_decoder(),
    )),
  )

  decode.success(ResolvedData(users, members, roles, channels, messages))
}

pub fn json_decoder() -> decode.Decoder(ComponentResponse) {
  use type_ <- decode.field("type", decode.int)

  case type_ {
    3 -> {
      use id <- decode.field("id", decode.int)
      use custom_id <- decode.field("custom_id", decode.string)
      use values <- decode.field("values", decode.list(decode.string))

      decode.success(StringSelectResponse(id, custom_id, values))
    }

    4 -> {
      use id <- decode.field("id", decode.int)
      use custom_id <- decode.field("custom_id", decode.string)
      use value <- decode.field("value", decode.string)

      decode.success(TextInputResponse(id, custom_id, value))
    }

    5 -> {
      use id <- decode.field("id", decode.int)
      use custom_id <- decode.field("custom_id", decode.string)
      use resolved <- decode.field("resolved", resolved_data_decoder())
      use values <- decode.field("values", decode.list(snowflake.decoder()))

      decode.success(UserSelectResponse(id, custom_id, resolved, values))
    }

    6 -> {
      use id <- decode.field("id", decode.int)
      use custom_id <- decode.field("custom_id", decode.string)
      use resolved <- decode.field("resolved", resolved_data_decoder())
      use values <- decode.field("values", decode.list(snowflake.decoder()))

      decode.success(RoleSelectResponse(id, custom_id, resolved, values))
    }

    7 -> {
      use id <- decode.field("id", decode.int)
      use custom_id <- decode.field("custom_id", decode.string)
      use resolved <- decode.field("resolved", resolved_data_decoder())
      use raw_values <- decode.field("values", decode.list(snowflake.decoder()))

      let values =
        list.map(raw_values, fn(value) {
          case resolved.roles {
            Some(roles) -> {
              case dict.has_key(roles, value) {
                True -> MentionableRole(snowflake.coerce(value))
                False -> MentionableUser(snowflake.coerce(value))
              }
            }

            None -> MentionableUser(snowflake.coerce(value))
          }
        })

      decode.success(MentionableSelectResponse(id, custom_id, resolved, values))
    }

    8 -> {
      use id <- decode.field("id", decode.int)
      use custom_id <- decode.field("custom_id", decode.string)
      use resolved <- decode.field("resolved", resolved_data_decoder())
      use values <- decode.field("values", decode.list(snowflake.decoder()))

      decode.success(ChannelSelectResponse(id, custom_id, resolved, values))
    }

    10 -> {
      decode.success(TextDisplayResponse)
    }

    18 -> {
      use component <- decode.field("component", json_decoder())

      decode.success(LabelResponse(component))
    }

    19 -> {
      use id <- decode.field("id", decode.int)
      use custom_id <- decode.field("custom_id", decode.string)
      use values <- decode.field("values", decode.list(snowflake.decoder()))

      decode.success(FileUploadResponse(id, custom_id, values))
    }

    21 -> {
      use id <- decode.field("id", decode.int)
      use custom_id <- decode.field("custom_id", decode.string)
      use value <- decode.optional_field(
        "value",
        None,
        decode.optional(decode.string),
      )

      decode.success(RadioGroupResponse(id, custom_id, value))
    }

    22 -> {
      use id <- decode.field("id", decode.int)
      use custom_id <- decode.field("custom_id", decode.string)
      use values <- decode.field("values", decode.list(decode.string))

      decode.success(CheckboxGroupResponse(id, custom_id, values))
    }

    23 -> {
      use id <- decode.field("id", decode.int)
      use custom_id <- decode.field("custom_id", decode.string)
      use value <- decode.field("value", decode.bool)

      decode.success(CheckboxResponse(id, custom_id, value))
    }

    _ -> {
      // the placeholder should never be shown to the user so i just chose one thats empty
      decode.failure(TextDisplayResponse, "ComponentResponse")
    }
  }
}
