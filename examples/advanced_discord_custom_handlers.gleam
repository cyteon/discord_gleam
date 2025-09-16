// Example: Discord bot with custom rate limiting and reconnection logic
import discord_gleam
import discord_gleam/custom_handlers
import discord_gleam/discord/intents
import discord_gleam/event_handler
import discord_gleam/ws/event_loop
import discord_gleam/ws/packets/generic
import discord_gleam/ws/packets/hello
import discord_gleam/ws/packets/identify
import gleam/bit_array
import gleam/dict
import gleam/dynamic
import gleam/erlang/process
import gleam/int
import gleam/json
import gleam/option
import gleam/string
import logging
import repeatedly
import stratus

pub fn main() {
  logging.configure()
  logging.set_level(logging.Info)

  let bot = discord_gleam.bot("TOKEN", "CLIENT ID", intents.default())

  // Create custom handlers with rate limiting and enhanced reconnection
  let custom_handlers = custom_handlers.CustomHandlers(
    loop: rate_limited_loop_handler,
    close: smart_reconnect_close_handler,
  )

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

/// Custom loop handler that implements rate limiting for outgoing messages
fn rate_limited_loop_handler(
  state: event_loop.State,
  msg: stratus.Message,
  conn: stratus.Connection,
) -> stratus.Next(event_loop.State) {
  case msg {
    stratus.Text(text_msg) -> {
      // Log the message size for monitoring
      let msg_size = string.length(text_msg)
      logging.log(
        logging.Debug,
        "Processing Discord message (" <> int.to_string(msg_size) <> " chars)",
      )
      
      // Parse the message as Discord protocol
      case json.decode(text_msg, dynamic.dynamic) {
        Ok(json_data) -> {
          // You could implement custom rate limiting here
          // For example, track message frequency and delay if needed
          
          // Continue with Discord protocol handling
          handle_discord_message(state, text_msg, conn)
        }
        Error(_) -> {
          logging.log(logging.Warning, "Received invalid JSON message")
          stratus.continue(state)
        }
      }
    }
    
    stratus.Binary(data) -> {
      logging.log(
        logging.Debug,
        "Received binary data (" <> int.to_string(bit_array.byte_size(data)) <> " bytes)",
      )
      stratus.continue(state)
    }
    
    stratus.User(user_msg) -> {
      logging.log(logging.Debug, "Processing user message")
      stratus.continue(state)
    }
  }
}

/// Handle Discord protocol messages (simplified version of default behavior)
fn handle_discord_message(
  state: event_loop.State,
  msg: String,
  conn: stratus.Connection,
) -> stratus.Next(event_loop.State) {
  case state.has_received_hello {
    False -> {
      // Handle hello packet
      case hello.string_to_data(msg) {
        Ok(hello_data) -> {
          logging.log(logging.Info, "Received hello packet")
          
          // Send identify (simplified)
          let identify_packet = identify.create_packet("your_token", intents.default())
          let _ = stratus.send_text_message(conn, identify_packet)
          
          // Start heartbeat (simplified - you'd want proper heartbeat timing)
          process.spawn(fn() {
            send_heartbeat_periodically(conn, hello_data.d.heartbeat_interval)
          })
          
          stratus.continue(event_loop.State(has_received_hello: True, s: 0))
        }
        Error(_) -> {
          logging.log(logging.Error, "Failed to parse hello packet")
          stratus.continue(state)
        }
      }
    }
    
    True -> {
      // Handle regular Discord events
      let generic_packet = generic.string_to_data(msg)
      
      case generic_packet.op {
        11 -> {
          // Heartbeat ACK
          logging.log(logging.Debug, "Received heartbeat ACK")
          stratus.continue(state)
        }
        0 -> {
          // Dispatch event - this would trigger your event handlers
          logging.log(logging.Debug, "Received dispatch event: " <> generic_packet.t)
          stratus.continue(event_loop.State(
            has_received_hello: state.has_received_hello,
            s: generic_packet.s,
          ))
        }
        _ -> {
          logging.log(logging.Debug, "Received opcode: " <> int.to_string(generic_packet.op))
          stratus.continue(state)
        }
      }
    }
  }
}

/// Send heartbeat periodically (simplified implementation)
fn send_heartbeat_periodically(conn: stratus.Connection, interval: Int) {
  let heartbeat_packet = json.object([
    #("op", json.int(1)),
    #("d", json.null()),
  ]) |> json.to_string()
  
  repeatedly.call(interval, Nil, fn(_, _) {
    let _ = stratus.send_text_message(conn, heartbeat_packet)
    logging.log(logging.Debug, "Sent heartbeat")
    Nil
  })
}

/// Smart reconnection handler that tracks connection quality
fn smart_reconnect_close_handler(state: event_loop.State) -> Nil {
  logging.log(logging.Warning, "Connection closed - analyzing disconnect...")
  
  case state.has_received_hello {
    True -> {
      case state.s > 0 {
        True -> {
          logging.log(
            logging.Info,
            "Clean disconnect after receiving " <> int.to_string(state.s) <> " events - will reconnect",
          )
          // Here you could implement smart reconnection logic:
          // - Exponential backoff
          // - Connection quality tracking  
          // - Different behavior based on disconnect reason
        }
        False -> {
          logging.log(
            logging.Warning,
            "Disconnected after hello but before events - possible rate limiting",
          )
        }
      }
    }
    False -> {
      logging.log(
        logging.Error,
        "Disconnected before hello - possible authentication issue",
      )
      // Could implement different reconnection strategy for auth failures
    }
  }
  
  // You could save state to persistent storage here for resuming
  // save_connection_state(state)
  
  Nil
}