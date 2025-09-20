import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/guild_member
import discord_gleam/types/presence
import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None}

pub type GuildMembersChunkContent {
  GuildMembersChunkContent(
    guild_id: Snowflake,
    members: List(guild_member.GuildMember),
    chunk_index: Int,
    chunk_count: Int,
    not_found: Option(List(Snowflake)),
    presences: Option(List(presence.Presence)),
    nonce: Option(String),
  )
}

pub type GuildMembersChunkData {
  Final(GuildMembersChunkContent)
  Next(GuildMembersChunkContent)
}

pub type GuildMembersChunkPacket {
  GuildMembersChunkPacket(t: String, s: Int, op: Int, d: GuildMembersChunkData)
}

pub fn string_to_data(
  encoded: String,
) -> Result(GuildMembersChunkPacket, json.DecodeError) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)
    use d <- decode.field("d", {
      use guild_id <- decode.field("guild_id", snowflake.decoder())
      use members <- decode.field(
        "members",
        decode.list(of: guild_member.from_json_decoder()),
      )
      use chunk_index <- decode.field("chunk_index", decode.int)
      use chunk_count <- decode.field("chunk_count", decode.int)
      use not_found <- decode.optional_field(
        "not_found",
        None,
        decode.optional(decode.list(of: snowflake.decoder())),
      )
      use presences <- decode.optional_field(
        "presences",
        None,
        decode.optional(decode.list(of: presence.from_json_decoder())),
      )
      use nonce <- decode.optional_field(
        "nonce",
        None,
        decode.optional(decode.string),
      )

      let content =
        GuildMembersChunkContent(
          guild_id:,
          members:,
          chunk_index:,
          chunk_count:,
          not_found:,
          presences:,
          nonce:,
        )

      decode.success(case chunk_index + 1 == chunk_count {
        True -> Final(content)
        False -> Next(content)
      })
    })

    decode.success(GuildMembersChunkPacket(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
}
