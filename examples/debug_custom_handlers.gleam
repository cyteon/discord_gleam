// Example: Debug bot that logs all WebSocket traffic  
import discord_gleam
import discord_gleam/custom_handlers
import discord_gleam/discord/intents
import discord_gleam/event_handler
import discord_gleam/ws/event_loop
import gleam/bit_array
import gleam/int
import gleam/option
import gleam/string
import logging
import stratus

pub fn main() {
  logging.configure()
  logging.set_level(logging.Debug)

  let bot = discord_gleam.bot("TOKEN", "CLIENT ID", intents.default())

  // Create debug handlers that log everything to files
  let debug_handlers = custom_handlers.CustomHandlers(
    loop: debug_loop_handler,
    close: debug_close_handler,
  )

  discord_gleam.run_with_custom_handlers(
    bot,
    [event_handler],
    option.Some(debug_handlers),
  )
}

fn event_handler(_bot, packet: event_handler.Packet) {
  case packet {
    event_handler.ReadyPacket(ready) -> {
      logging.log(logging.Info, "Logged in as " <> ready.d.user.username)
      Nil
    }
    _ -> Nil
  }
}

/// Debug loop handler that logs all traffic to files
fn debug_loop_handler(
  state: event_loop.State,
  msg: stratus.Message,
  _conn: stratus.Connection,
) -> stratus.Next(event_loop.State) {
  case msg {
    stratus.Text(text_msg) -> {
      // Log text messages to console instead of file
      logging.log(
        logging.Debug,
        "📨 TEXT (" <> int.to_string(string.length(text_msg)) <> " chars): " <> string.slice(text_msg, 0, 100) <> "...",
      )
      
      logging.log(
        logging.Debug,
        "📨 Text message (" <> int.to_string(string.length(text_msg)) <> " chars)",
      )
      
      // Continue processing (this example just continues without Discord protocol)
      stratus.continue(state)
    }
    
    stratus.Binary(data) -> {
      // Log binary messages to console
      let size = bit_array.byte_size(data)
      
      logging.log(
        logging.Debug,
        "📦 BINARY: " <> int.to_string(size) <> " bytes",
      )
      
      stratus.continue(state)
    }
    
    stratus.User(user_msg) -> {
      // Log user messages to console
      logging.log(
        logging.Debug, 
        "👤 USER: " <> string.inspect(user_msg),
      )
      
      stratus.continue(state)
    }
  }
}

/// Debug close handler that logs connection details
fn debug_close_handler(state: event_loop.State) -> Nil {
  let state_info = "hello_received=" 
    <> case state.has_received_hello {
      True -> "true"
      False -> "false"
    }
    <> ", sequence=" <> int.to_string(state.s)
  
  logging.log(
    logging.Warning,
    "🔌 CONNECTION_CLOSED: " <> state_info,
  )
  
  logging.log(
    logging.Info,
    "Debug session ended. Connection details logged above.",
  )
  
  Nil
}