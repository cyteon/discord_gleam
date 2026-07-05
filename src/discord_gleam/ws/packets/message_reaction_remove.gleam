import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/emoji
import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None}

pub type MessageReactionRemovePacketData {
  MessageReactionRemovePacketData(
    user_id: Snowflake(snowflake.User),
    channel_id: Snowflake(snowflake.Channel),
    message_id: Snowflake(snowflake.Message),
    guild_id: Option(Snowflake(snowflake.Guild)),
    emoji: emoji.Emoji,
    burst: Bool,
    type_: Option(Int),
  )
}

pub type MessageReactionRemovePacket {
  MessageReactionRemovePacket(
    t: String,
    s: Int,
    op: Int,
    d: MessageReactionRemovePacketData,
  )
}

pub fn from_json_string(
  encoded: String,
) -> Result(MessageReactionRemovePacket, json.DecodeError) {
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

      use emoji <- decode.field("emoji", emoji.json_decoder())

      use burst <- decode.field("burst", decode.bool)

      use type_ <- decode.optional_field(
        "type",
        None,
        decode.optional(decode.int),
      )

      decode.success(MessageReactionRemovePacketData(
        user_id:,
        channel_id:,
        message_id:,
        guild_id:,
        emoji:,
        burst:,
        type_:,
      ))
    })

    decode.success(MessageReactionRemovePacket(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
}
