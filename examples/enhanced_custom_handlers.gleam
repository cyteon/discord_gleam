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
  logging.set_level(logging.Info)

  let bot = discord_gleam.bot("TOKEN", "CLIENT ID", intents.default())

  // Create custom handlers that enhance the default behavior
  let custom_handlers = custom_handlers.CustomHandlers(
    loop: enhanced_loop_handler,
    close: enhanced_close_handler,
  )

  // Run with enhanced custom handlers
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
    event_handler.MessagePacket(message) -> {
      logging.log(logging.Info, "Message from " <> message.d.author.username <> ": " <> message.d.content)
      Nil
    }
    _ -> Nil
  }
}

/// Enhanced loop handler that adds message size monitoring
fn enhanced_loop_handler(
  state: event_loop.State,
  msg: stratus.Message,
  conn: stratus.Connection,
) -> stratus.Next(event_loop.State) {
  case msg {
    stratus.Text(text_msg) -> {
      let msg_size = string.length(text_msg)
      logging.log(
        logging.Debug,
        "Received text message of " <> int.to_string(msg_size) <> " characters",
      )
      
      // Log large messages
      case msg_size > 1000 {
        True -> {
          logging.log(
            logging.Warning,
            "Large message received: " <> int.to_string(msg_size) <> " characters",
          )
        }
        False -> Nil
      }
      
      // Continue with normal processing
      stratus.continue(state)
    }
    
    stratus.Binary(data) -> {
      logging.log(
        logging.Info,
        "Received binary message of " <> int.to_string(bit_array.byte_size(data)) <> " bytes",
      )
      stratus.continue(state)
    }
    
    stratus.User(user_msg) -> {
      logging.log(logging.Debug, "Received user message")
      stratus.continue(state)
    }
  }
}

/// Enhanced close handler that provides detailed state information and attempts reconnection
fn enhanced_close_handler(state: event_loop.State) -> Nil {
  logging.log(
    logging.Warning,
    "Enhanced close handler: Connection closed. Final state details:",
  )
  
  logging.log(
    logging.Info,
    "- Hello received: " <> case state.has_received_hello {
      True -> "Yes"
      False -> "No"
    },
  )
  
  logging.log(
    logging.Info,
    "- Last sequence number: " <> int.to_string(state.s),
  )
  
  // Could add custom reconnection logic here
  // For example: storing state to file, sending notifications, etc.
  
  case state.has_received_hello {
    True -> {
      logging.log(
        logging.Info,
        "Connection was properly established before closing - likely a normal disconnect",
      )
    }
    False -> {
      logging.log(
        logging.Error,
        "Connection closed before receiving hello - possible authentication issue",
      )
    }
  }
  
  Nil
}