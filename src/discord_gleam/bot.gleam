import booklet
import discord_gleam/discord/intents
import discord_gleam/discord/snowflake
import discord_gleam/types/bot
import gleam/dict
import gleam/erlang/process

pub type Bot =
  bot.Bot

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
pub fn new(token: String, client_id: String) -> bot.Bot {
  bot.Bot(
    token: token,
    client_id: snowflake.from_string(client_id),
    intents: intents.none(),
    cache: bot.Cache(messages: booklet.new(dict.new())),
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
pub fn with_intents(bot: bot.Bot, intents: intents.Intents) -> bot.Bot {
  bot.Bot(..bot, intents: intents)
}
