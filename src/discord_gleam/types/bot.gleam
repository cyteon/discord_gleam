import bravo/uset
import discord_gleam/discord/intents
import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/ws/packets/message.{type MessagePacketData}
import gleam/option

/// The Bot type holds bot data used by a lot of high-level functions
pub type Bot {
  Bot(
    token: String,
    client_id: Snowflake,
    intents: intents.Intents,
    cache: Cache,
  )
}

/// The cache currently only stores messages, which can be used to for example get deleted messages
pub type Cache {
  Cache(messages: option.Option(uset.USet(Snowflake, MessagePacketData)))
}
