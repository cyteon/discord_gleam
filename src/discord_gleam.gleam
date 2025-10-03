//// The primary module of discord_gleam. \
//// This module contains high-level functions to interact with the Discord API. \
//// But you can always implement stuff yourself using the low-level functions from the rest of the library. \

import booklet
import discord_gleam/discord/intents
import discord_gleam/discord/snowflake
import discord_gleam/event_handler
import discord_gleam/http/endpoints
import discord_gleam/internal/error
import discord_gleam/types/bot
import discord_gleam/types/channel
import discord_gleam/types/message
import discord_gleam/types/message_send_response
import discord_gleam/types/reply
import discord_gleam/types/slash_command
import discord_gleam/ws/commands/request_guild_members
import discord_gleam/ws/event_loop
import discord_gleam/ws/packets/interaction_create
import gleam/dict
import gleam/erlang/process
import gleam/list
import gleam/option
import gleam/otp/actor

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
    subject: process.new_subject(),
  )
}

/// Instruction on how event loop actor should proceed after handling an event
/// 
/// - `Continue` - Continue processing with the updated state and optional
/// selector for custom user messages
/// - `Stop` - Stop the event loop
/// - `StopAbnormal` - Stop the event loop with an abnormal reason
pub opaque type Next(user_state, user_message) {
  Continue(user_state, option.Option(process.Selector(user_message)))
  Stop
  StopAbnormal(reason: String)
}

/// Continue processing with the updated state. Use `with_selector` to add a 
/// selector for custom user messages.
pub fn continue(state: user_state) -> Next(user_state, user_message) {
  Continue(state, option.None)
}

/// Add a selector for custom user messages.
pub fn with_selector(
  state: Next(user_state, user_message),
  selector: process.Selector(user_message),
) -> Next(user_state, user_message) {
  case state {
    Continue(user_state, _) -> Continue(user_state, option.Some(selector))
    _ -> state
  }
}

/// Stop the event loop
pub fn stop() -> Next(user_state, user_message) {
  Stop
}

/// Stop the event loop with an abnormal reason
pub fn stop_abnormal(reason: String) -> Next(user_state, user_message) {
  StopAbnormal(reason)
}

/// The mode of the event handler
/// 
/// Simple mode is used for simple bots that don't need to handle custom user 
/// state and messages. Can have multiple handlers.
/// 
/// Normal mode is used for bots that need to handle custom user state and
/// messages. Can have only one handler.
pub opaque type Mode(user_state, user_message) {
  Simple(
    bot: bot.Bot,
    handlers: List(fn(bot.Bot, event_handler.Packet) -> Nil),
    next: Next(user_state, user_message),
    nil_state: user_state,
  )
  Normal(
    bot: bot.Bot,
    name: process.Name(user_message),
    on_init: fn(process.Selector(user_message)) ->
      #(user_state, process.Selector(user_message)),
    handler: fn(bot.Bot, user_state, HandlerMessage(user_message)) ->
      Next(user_state, user_message),
  )
}

/// The message type for the event handler with custom user messages
pub type HandlerMessage(user_message) {
  /// A discord packet
  Packet(event_handler.Packet)
  /// A custom user message
  User(user_message)
}

/// Create a simple mode with multiple handlers
pub fn simple(
  bot: bot.Bot,
  handlers: List(fn(bot.Bot, event_handler.Packet) -> Nil),
) -> Mode(Nil, Nil) {
  Simple(bot, handlers, Continue(Nil, option.None), Nil)
}

/// Create a normal mode with a single handler
/// 
/// `on_init` function is called once discord websocket connection is
/// initialized. It must return a tuple with initial state and selector for 
/// custom messages. If there is no custom messages, user can pass the same 
/// selector from the argument
pub fn new(
  bot: bot.Bot,
  on_init: fn(process.Selector(user_message)) ->
    #(user_state, process.Selector(user_message)),
  handler: fn(bot.Bot, user_state, HandlerMessage(user_message)) ->
    Next(user_state, user_message),
) -> Mode(user_state, user_message) {
  Normal(
    bot,
    process.new_name("normal_mode_user_message_subject"),
    on_init,
    handler,
  )
}

/// Set process name for the event loop. Allows to use named subjects for custom
/// user messages in normal mode.
pub fn with_name(
  mode: Mode(user_state, user_message),
  name: process.Name(user_message),
) -> Mode(user_state, user_message) {
  case mode {
    Normal(..) -> Normal(..mode, name:)
    Simple(..) -> mode
  }
}

/// Start the event loop with a current mode.
///
/// Example:
/// ```gleam
/// import discord_gleam/discord/intents
/// import discord_gleam/event_handler
/// import gleam/erlang/process
/// 
/// fn main() {
///  let bot = discord_gleam.bot("TOKEN", "CLIENT_ID", intents.default())
/// 
///  let assert Ok(_) = 
///    discord_gleam.simple(bot, [handler])
///    |> discord_gleam.start()
/// 
///  process.sleep_forever()
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
/// ```
/// 
pub fn start(
  mode: Mode(user_state, user_message),
) -> Result(
  actor.Started(process.Subject(event_loop.EventLoopMessage)),
  actor.StartError,
) {
  let state = booklet.new(dict.new())

  event_loop.start_event_loop(
    to_internal_mode(mode),
    "gateway.discord.gg",
    False,
    "",
    state,
  )
}

fn to_internal_mode(
  mode: Mode(user_state, user_message),
) -> event_handler.Mode(user_state, user_message) {
  case mode {
    Simple(bot, handlers, next, nil_state) ->
      event_handler.Simple(bot, handlers, to_internal_next(next), nil_state)
    Normal(bot, name, on_init, handler) -> {
      let handler = fn(bot, user_state, msg) {
        handler(bot, user_state, internal_to_handler_message(msg))
        |> to_internal_next()
      }

      event_handler.Normal(bot, name, on_init, handler)
    }
  }
}

fn internal_to_handler_message(
  msg: event_handler.HandlerMessage(user_message),
) -> HandlerMessage(user_message) {
  case msg {
    event_handler.DiscordPacket(packet) -> Packet(packet)
    event_handler.User(msg) -> User(msg)
  }
}

fn to_internal_next(
  next: Next(user_state, user_message),
) -> event_handler.Next(user_state, user_message) {
  case next {
    Continue(user_state, opt) -> event_handler.Continue(user_state, opt)
    Stop -> event_handler.Stop
    StopAbnormal(reason) -> event_handler.StopAbnormal(reason)
  }
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

/// Used to request all members of a guild. The server will send 
/// GUILD_MEMBERS_CHUNK events in response with up to 1000 members per chunk 
/// until all members that match the request have been sent.
/// 
/// Nonce can only be up to 32 bytes. If you send an invalid nonce it will be
/// ignored and the reply member_chunk(s) will not have a nonce set.
pub fn request_guild_members(
  bot: bot.Bot,
  guild_id guild_id: snowflake.Snowflake,
  option option: request_guild_members.RequestGuildMembersOption,
  presences presences: option.Option(Bool),
  nonce nonce: option.Option(String),
) -> Nil {
  request_guild_members.request_guild_members(
    bot,
    guild_id,
    option,
    presences,
    nonce,
  )
}
