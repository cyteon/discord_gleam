import discord_gleam
import discord_gleam/custom_handlers
import discord_gleam/discord/intents
import discord_gleam/event_handler
import discord_gleam/ws/event_loop
import gleam/int
import gleam/option
import logging
import stratus

pub fn main() {
  logging.configure()
  logging.set_level(logging.Info)

  let bot = discord_gleam.bot("TOKEN", "CLIENT ID", intents.default())

  // Create custom handlers
  let custom_handlers = custom_handlers.CustomHandlers(
    loop: custom_loop_handler,
    close: custom_close_handler,
  )

  // Run with custom handlers
  discord_gleam.run_with_custom_handlers(
    bot,
    [event_handler],
    option.Some(custom_handlers),
  )
}

fn event_handler(bot, packet: event_handler.Packet) {
  case packet {
    event_handler.ReadyPacket(ready) -> {
      logging.log(logging.Info, "Logged in as " <> ready.d.user.username)
      Nil
    }
    _ -> Nil
  }
}

/// Custom loop handler that logs all messages and forwards to default behavior
fn custom_loop_handler(
  state: event_loop.State,
  msg: stratus.Message,
  conn: stratus.Connection,
) -> stratus.Next(event_loop.State) {
  case msg {
    stratus.Text(text_msg) -> {
      logging.log(
        logging.Info,
        "Custom handler received text message: " <> text_msg,
      )
      // You could add custom logic here before continuing
      stratus.continue(state)
    }
    stratus.Binary(_) -> {
      logging.log(logging.Info, "Custom handler received binary message")
      stratus.continue(state)
    }
    stratus.User(user_msg) -> {
      logging.log(logging.Info, "Custom handler received user message")
      stratus.continue(state)
    }
  }
}

/// Custom close handler that logs when the connection closes
fn custom_close_handler(state: event_loop.State) -> Nil {
  logging.log(
    logging.Warning,
    "Custom close handler: Connection closed with state: has_received_hello="
      <> case state.has_received_hello {
        True -> "true"
        False -> "false"
      }
      <> ", sequence="
      <> int.to_string(state.s),
  )
  
  // You could add custom reconnection logic here
  Nil
}