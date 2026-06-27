import booklet
import discord_gleam/discord/intents
import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/ws/packets/message
import gleam/dict
import gleam/erlang/process

/// The Bot type holds bot data used by a lot of high-level functions
pub type Bot {
  Bot(
    token: String,
    client_id: Snowflake(snowflake.Application),
    intents: intents.Intents,
    cache: Cache,
    subject: process.Subject(BotMessage),
  )
}

/// Used to send user messages to the websocket process
pub type BotMessage {
  SendPacket(packet: String)
}

/// The cache currently only stores messages, which can be used to for example get deleted messages
pub type Cache {
  Cache(
    messages: booklet.Booklet(
      dict.Dict(Snowflake(snowflake.Message), message.MessagePacketData),
    ),
  )
}

/// Create a new bot instance.
///
/// Example:
/// ```gleam
/// import discord_gleam/bot
///
/// fn main() {
///   let bot = bot.new("TOKEN", "CLIENT_ID")
/// }
/// ```
pub fn new(token: String, client_id: String) -> Bot {
  Bot(
    token: token,
    client_id: snowflake.from_string(client_id),
    intents: intents.none(),
    cache: Cache(messages: booklet.new(dict.new())),
    subject: process.new_subject(),
  )
}

/// A part of building a bot, this sets the intents for the bot. \
/// This can only be used before the bot is started, and is meant to use while building the bot
///
/// Example:
/// ```gleam
/// import discord_gleam/bot
/// import discord_gleam/discord/intents
///
/// fn main() {
///   let bot =
///     bot.new(token, client_id)
///     |> bot.with_intents(intents.all())
/// }
/// ```
pub fn with_intents(bot: Bot, intents: intents.Intents) -> Bot {
  Bot(..bot, intents: intents)
}
