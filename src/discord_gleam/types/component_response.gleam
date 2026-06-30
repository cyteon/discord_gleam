import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/channel
import discord_gleam/types/guild_member
import discord_gleam/types/role
import discord_gleam/types/user
import discord_gleam/ws/packets/message
import gleam/dict
import gleam/option.{type Option, None}

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
  StringSelect(id: Int, custom_id: String, values: List(String))

  // 4
  TextInput(id: Int, custom_id: String, value: String)

  // 5
  UserSelect(
    id: Int,
    custom_id: String,
    resolved: ResolvedData,
    values: List(Snowflake(snowflake.User)),
  )

  // 6
  RoleSelect(
    id: Int,
    custom_id: String,
    resolved: ResolvedData,
    values: List(Snowflake(snowflake.Role)),
  )

  // 7
  MentionableSelect(
    id: Int,
    custom_id: String,
    resolved: ResolvedData,
    values: List(Mentionable),
  )

  // 8
  ChannelSelect(
    id: Int,
    custom_id: String,
    resolved: ResolvedData,
    values: List(Snowflake(snowflake.Channel)),
  )

  // 10
  TextDisplay

  // 18
  Label(component: ComponentResponse)

  // 19
  FileUpload(
    id: Int,
    custom_id: String,
    values: List(Snowflake(snowflake.Attachment)),
  )

  // 21
  RadioGroup(id: Int, custom_id: String, value: Option(String))

  // 22
  CheckboxGroup(id: Int, custom_id: String, values: List(String))

  // 23
  Checkbox(id: Int, custom_id: String, value: Bool)
}
