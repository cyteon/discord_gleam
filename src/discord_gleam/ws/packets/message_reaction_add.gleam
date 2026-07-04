import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/emoji
import discord_gleam/types/guild_member
import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None}

pub type MessageReactionAddPacketData {
  MessageReactionAddPacketData(
    user_id: Snowflake(snowflake.User),
    channel_id: Snowflake(snowflake.Channel),
    message_id: Snowflake(snowflake.Message),
    guild_id: Option(Snowflake(snowflake.Guild)),
    member: Option(guild_member.GuildMember),
    emoji: emoji.Emoji,
    message_author_id: Option(Snowflake(snowflake.User)),
    burst: Bool,
    burst_colors: Option(List(String)),
    type_: Option(Int),
  )
}

pub type MessageReactionAddPacket {
  MessageReactionAddPacket(
    t: String,
    s: Int,
    op: Int,
    d: MessageReactionAddPacketData,
  )
}

pub fn from_json_string(
  encoded: String,
) -> Result(MessageReactionAddPacket, json.DecodeError) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)

    use d <- decode.field("d", {
      use user_id <- decode.field("user_id", snowflake.decoder())
      use channel_id <- decode.field("channel_id", snowflake.decoder())
      use message_id <- decode.field("message_id", snowflake.decoder())

      use guild_id <- decode.optional_field(
        "guild_id",
        None,
        decode.optional(snowflake.decoder()),
      )

      use member <- decode.optional_field(
        "member",
        None,
        decode.optional(guild_member.json_decoder()),
      )

      use emoji <- decode.field("emoji", emoji.json_decoder())

      use message_author_id <- decode.optional_field(
        "message_author_id",
        None,
        decode.optional(snowflake.decoder()),
      )

      use burst <- decode.field("burst", decode.bool)

      use burst_colors <- decode.optional_field(
        "burst_colors",
        None,
        decode.optional(decode.list(decode.string)),
      )

      decode.success(MessageReactionAddPacketData(
        user_id:,
        channel_id:,
        message_id:,
        guild_id:,
        member:,
        emoji:,
        message_author_id:,
        burst:,
        burst_colors:,
        type_: None,
      ))
    })

    decode.success(MessageReactionAddPacket(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
}
