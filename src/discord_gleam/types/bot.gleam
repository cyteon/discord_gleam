import booklet
import discord_gleam/discord/intents
import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/ws/packets/message.{type MessagePacketData}
import gleam/dict
import gleam/erlang/process
import gleam/option.{type Option}

/// The Bot type holds bot data used by a lot of high-level functions
pub type Bot {
  Bot(
    token: String,
    client_id: Snowflake,
    intents: intents.Intents,
    cache: Cache,
    websocket_name: Option(process.Name(BotMessage)),
  )
}

/// Used to send user messages to the websocket process
pub type BotMessage {
  SendPacket(packet: String)
}

/// The cache currently only stores messages, which can be used to for example get deleted messages
pub type Cache {
  Cache(messages: booklet.Booklet(dict.Dict(Snowflake, MessagePacketData)))
}
