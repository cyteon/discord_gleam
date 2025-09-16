//// The primary module of discord_gleam. \
//// This module contains high-level functions to interact with the Discord API. \
//// But you can always implement stuff yourself using the low-level functions from the rest of the library. \

import booklet
import discord_gleam/custom_handlers
import discord_gleam/discord/intents
import discord_gleam/event_handler
import discord_gleam/http/endpoints
import discord_gleam/internal/error
import discord_gleam/types/bot
import discord_gleam/types/channel
import discord_gleam/types/message
import discord_gleam/types/message_send_response
import discord_gleam/types/reply
import discord_gleam/types/slash_command
import discord_gleam/ws/event_loop
import discord_gleam/ws/packets/interaction_create
import gleam/dict
import gleam/list
import gleam/option

/// Create a new bot instance.
/// 
/// Example:
/// ```gleam
/// import discord_gleam/discord/intents
/// 
/// fn main() {
///   let bot = discord_gleam.bot("TOKEN", "CLIENT_ID", intents.default()))
/// }
/// ```
pub fn bot(
  token: String,
  client_id: String,
  intents: intents.Intents,
) -> bot.Bot {
  bot.Bot(
    token: token,
    client_id: client_id,
    intents: intents,
    cache: bot.Cache(messages: booklet.new(dict.new())),
  )
}

/// Start the event loop, with a set of event handlers.
///
/// Example:
/// ```gleam
/// import discord_gleam/discord/intents
/// import discord_gleam/event_handler
/// 
/// fn main() {
///  let bot = discord_gleam.bot("TOKEN", "CLIENT_ID", intents.default())
/// 
///  let event_handlers = [handler]
/// 
///  discord_gleam.run(bot, event_handlers)
/// }
/// 
/// fn handler(bot: bot.Bot, packet: event_handler.Packet) {
///  case packet {
///   event_handler.ReadyPacket(ready) -> {
///     logging.log(logging.Info, "Logged in as " <> ready.d.user.username)
///   }
/// 
///   _ -> Nil
///  }
/// }
/// 
pub fn run(
  bot: bot.Bot,
  event_handlers: List(event_handler.EventHandler),
) -> Nil {
  let state = booklet.new(dict.new())

  event_loop.main(bot, event_handlers, "gateway.discord.gg", False, "", state)
}

/// Start the event loop with custom loop and close handlers.
/// This allows users to override the default Discord WebSocket message handling
/// and connection close behavior with their own custom functions.
///
/// Example:
/// ```gleam
/// import discord_gleam
/// import discord_gleam/custom_handlers
/// import discord_gleam/discord/intents
/// import discord_gleam/event_handler
/// import discord_gleam/ws/event_loop
/// import gleam/option
/// import stratus
/// 
/// fn main() {
///   let bot = discord_gleam.bot("TOKEN", "CLIENT_ID", intents.default())
///   
///   let custom_handlers = custom_handlers.CustomHandlers(
///     loop: my_custom_loop,
///     close: my_custom_close
///   )
///   
///   discord_gleam.run_with_custom_handlers(
///     bot, 
///     [event_handler], 
///     option.Some(custom_handlers)
///   )
/// }
/// 
/// fn my_custom_loop(state: event_loop.State, msg: stratus.Message, conn: stratus.Connection) {
///   // Your custom message handling logic here
///   stratus.continue(state)
/// }
/// 
/// fn my_custom_close(state: event_loop.State) {
///   // Your custom close handling logic here
///   Nil
/// }
/// ```
pub fn run_with_custom_handlers(
  bot: bot.Bot,
  event_handlers: List(event_handler.EventHandler),
  custom_handlers: option.Option(custom_handlers.CustomHandlers(event_loop.State)),
) -> Nil {
  let state = booklet.new(dict.new())

  event_loop.main_with_custom_handlers(
    bot,
    event_handlers,
    "gateway.discord.gg",
    False,
    "",
    state,
    custom_handlers,
  )
}

/// Send a message to a channel.
/// 
/// Example:
/// ```gleam
/// import discord_gleam
/// 
/// fn main() {
///  ...
/// 
///  let msg = discord_gleam.send_message(
///   bot,  
///   "CHANNEL_ID",
///   "Hello world!",
///   [] // embeds
///  )
/// }
pub fn send_message(
  bot: bot.Bot,
  channel_id: String,
  message: String,
  embeds: List(message.Embed),
) -> Result(message_send_response.MessageSendResponse, error.DiscordError) {
  let msg = message.Message(content: message, embeds: embeds)

  endpoints.send_message(bot.token, channel_id, msg)
}

/// Create a DM channel with a user. \
/// Returns a channel object, or a DiscordError if it fails.
pub fn create_dm_channel(
  bot: bot.Bot,
  user_id: String,
) -> Result(channel.Channel, error.DiscordError) {
  endpoints.create_dm_channel(bot.token, user_id)
}

/// Send a direct message to a user. \
/// Same use as `send_message`, but use user_id instead of channel_id. \
/// `discord_gleam.send_direct_message(bot, "USER_ID", "Hello world!", [])`
/// 
/// Note: This will return a DiscordError if the DM channel cant be made
pub fn send_direct_message(
  bot: bot.Bot,
  user_id: String,
  message: String,
  embeds: List(message.Embed),
) -> Result(Nil, error.DiscordError) {
  let msg = message.Message(content: message, embeds: embeds)

  endpoints.send_direct_message(bot.token, user_id, msg)
}

/// Reply to a message in a channel.
/// 
/// Example:
/// 
/// ```gleam
/// import discord_gleam
/// 
/// fn main() {
///  ...
/// 
///  discord_gleam.reply(bot, "CHANNEL_ID", "MESSAGE_ID", "Hello world!", [])
/// }
/// ```
pub fn reply(
  bot: bot.Bot,
  channel_id: String,
  message_id: String,
  message: String,
  embeds: List(message.Embed),
) -> Result(Nil, error.DiscordError) {
  let msg =
    reply.Reply(content: message, message_id: message_id, embeds: embeds)

  endpoints.reply(bot.token, channel_id, msg)
}

/// Kicks an member from an server. \
/// The reason will be what is shown in the audit log.
/// 
/// Example:
/// 
/// ```gleam
/// import discord_gleam
/// 
/// fn main() {
///  ...
/// 
///  discord_gleam.kick_member(bot, "GUILD_ID", "USER_ID", "REASON")
/// }
/// 
/// For an full example, see the `examples/kick.gleam` file.
pub fn kick_member(
  bot: bot.Bot,
  guild_id: String,
  user_id: String,
  reason: String,
) -> Result(Nil, error.DiscordError) {
  endpoints.kick_member(bot.token, guild_id, user_id, reason)
}

pub fn ban_member(
  bot: bot.Bot,
  guild_id: String,
  user_id: String,
  reason: String,
) -> Result(Nil, error.DiscordError) {
  endpoints.ban_member(bot.token, guild_id, user_id, reason)
}

/// Deletes an message from a channel. \
/// The reason will be what is shown in the audit log.
/// 
/// Example:
/// ```gleam
/// import discord_gleam
/// 
/// fn main() {
///  ...
/// 
///  discord_gleam.delete_message(
///   bot,  
///  "CHANNEL_ID",
///  "MESSAGE_ID",
///  "REASON",
///  )
/// }
/// 
/// For an full example, see the `examples/delete_message.gleam` file.
pub fn delete_message(
  bot: bot.Bot,
  channel_id: String,
  message_id: String,
  reason: String,
) -> Result(Nil, error.DiscordError) {
  endpoints.delete_message(bot.token, channel_id, message_id, reason)
}

/// Edits an existing message in a channel. \
/// The message must have been sent by the bot itself.
pub fn edit_message(
  bot: bot.Bot,
  channel_id: String,
  message_id: String,
  content: String,
  embeds: List(message.Embed),
) -> Result(Nil, error.DiscordError) {
  let msg = message.Message(content: content, embeds: embeds)

  endpoints.edit_message(bot.token, channel_id, message_id, msg)
}

/// Wipes all the global slash commands for the bot. \
/// Restarting your client might be required to see the changes. \
pub fn wipe_global_commands(bot: bot.Bot) -> Result(Nil, error.DiscordError) {
  endpoints.wipe_global_commands(bot.token, bot.client_id)
}

/// Wipes all the guild slash commands for the bot. \
/// Restarting your client might be required to see the changes. \
pub fn wipe_guild_commands(
  bot: bot.Bot,
  guild_id: String,
) -> Result(Nil, error.DiscordError) {
  endpoints.wipe_guild_commands(bot.token, bot.client_id, guild_id)
}

/// Registers a global slash command. \
/// Restarting your client might be required to see the changes. \
pub fn register_global_commands(
  bot: bot.Bot,
  commands: List(slash_command.SlashCommand),
) -> Result(Nil, #(slash_command.SlashCommand, error.DiscordError)) {
  list.try_each(commands, fn(command) {
    case endpoints.register_global_command(bot.token, bot.client_id, command) {
      Ok(_) -> Ok(Nil)
      Error(err) -> Error(#(command, err))
    }
  })
}

/// Registers a guild-specific slash command. \
/// Restarting your client might be required to see the changes. \
pub fn register_guild_commands(
  bot: bot.Bot,
  guild_id: String,
  commands: List(slash_command.SlashCommand),
) -> Result(Nil, #(slash_command.SlashCommand, error.DiscordError)) {
  list.try_each(commands, fn(command) {
    case
      endpoints.register_guild_command(
        bot.token,
        bot.client_id,
        guild_id,
        command,
      )
    {
      Ok(_) -> Ok(Nil)
      Error(err) -> Error(#(command, err))
    }
  })
}

/// Make a basic text reply to an interaction.
pub fn interaction_reply_message(
  interaction: interaction_create.InteractionCreatePacket,
  message: String,
  ephemeral: Bool,
) -> Result(Nil, error.DiscordError) {
  endpoints.interaction_send_text(interaction, message, ephemeral)
}
