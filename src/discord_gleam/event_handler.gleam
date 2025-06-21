import bravo/uset
import discord_gleam/types/bot
import discord_gleam/ws/packets/channel_create
import discord_gleam/ws/packets/channel_delete
import discord_gleam/ws/packets/channel_update
import discord_gleam/ws/packets/generic
import discord_gleam/ws/packets/guild_ban_add
import discord_gleam/ws/packets/guild_ban_remove
import discord_gleam/ws/packets/interaction_create
import discord_gleam/ws/packets/message
import discord_gleam/ws/packets/message_delete
import discord_gleam/ws/packets/message_update
import discord_gleam/ws/packets/ready
import discord_gleam/internal/error
import gleam/list
import gleam/option
import gleam/result
import logging

pub type EventHandler =
  fn(bot.Bot, Packet) -> Nil

/// The supported packets
pub type Packet {
  /// `MESSAGE_CREATE` event
  MessagePacket(message.MessagePacket)
  /// `MESSAGE_UPDATE` event
  MessageUpdatePacket(message_update.MessageUpdatePacket)
  /// `READY` event
  ReadyPacket(ready.ReadyPacket)
  /// `MESSAGE_DELETE` event
  MessageDeletePacket(message_delete.MessageDeletePacket)
  /// `INTERACTION_CREATE` event
  InteractionCreatePacket(interaction_create.InteractionCreatePacket)
  /// `CHANNEL_CREATE` event
  ChannelCreatePacket(channel_create.ChannelCreatePacket)
  /// `CHANNEL_DELETE` event
  ChannelDeletePacket(channel_delete.ChannelDeletePacket)
  /// `CHANNEL_UPDATE` event
  ChannelUpdatePacket(channel_update.ChannelUpdatePacket)
  /// `GUILD_BAN_ADD` event
  GuildBanAddPacket(guild_ban_add.GuildBanAddPacket)
  /// `GUILD_BAN_REMOVE` event
  GuildBanRemovePacket(guild_ban_remove.GuildBanRemovePacket)

  /// When we receive a packet that we don't know how to handle
  UnknownPacket(generic.GenericPacket)
}

/// For handling some events the library needs to handle, for functionality
fn internal_handler(
  bot: bot.Bot,
  packet: Packet,
  state_uset: uset.USet(#(String, String)),
) -> Nil {
  case packet {
    MessagePacket(msg) -> {
      case bot.cache.messages {
        option.Some(cache) -> {
          uset.insert(cache, [#(msg.d.id, msg.d)])

          Nil
        }

        option.None -> {
          Nil
        }
      }
      Nil
    }

    MessageUpdatePacket(msg) -> {
      case bot.cache.messages {
        option.Some(cache) -> {
          uset.insert(cache, [#(msg.d.id, msg.d)])

          Nil
        }

        option.None -> {
          Nil
        }
      }
    }

    ReadyPacket(ready) -> {
      uset.insert(state_uset, [#("session_id", ready.d.session_id)])
      uset.insert(state_uset, [
        #("resume_gateway_url", ready.d.resume_gateway_url),
      ])

      Nil
    }

    _ -> Nil
  }
}

/// Handle an event from the Discord API, using a set of event handlers.
pub fn handle_event(
  bot: bot.Bot,
  msg: String,
  handlers: List(EventHandler),
  state_uset: uset.USet(#(String, String)),
) -> Nil {
  let packet = decode_packet(msg)
  internal_handler(bot, packet, state_uset)

  list.each(handlers, fn(handler) { handler(bot, packet) })
}

fn decode_packet(msg: String) -> Packet {
  let generic_packet = generic.string_to_data(msg)

  case generic_packet.t {
    "READY" ->
      case ready.string_to_data(msg) {
        Ok(data) -> ReadyPacket(data)
        Error(err) -> {
          logging.log(
            logging.Error,
            "Failed to decode READY packet: " <> error.json_decode_error_to_string(err)
          )

          UnknownPacket(generic_packet)
        }
      }

    "MESSAGE_CREATE" ->
      case message.string_to_data(msg) {
        Ok(data) -> MessagePacket(data)
        Error(err) -> {
          logging.log(
            logging.Error,
            "Failed to decode MESSAGE_CREATE packet: " <> error.json_decode_error_to_string(err)
          )

          UnknownPacket(generic_packet)
        }
      }
    
    "MESSAGE_UPDATE" ->
      case message_update.string_to_data(msg) {
        Ok(data) -> MessageUpdatePacket(data)
        Error(err) -> {
          logging.log(
            logging.Error,
            "Failed to decode MESSAGE_UPDATE packet: " <> error.json_decode_error_to_string(err)
          )

          UnknownPacket(generic_packet)
        }
      }
    
    "MESSAGE_DELETE" ->
      case message_delete.string_to_data(msg) {
        Ok(data) -> MessageDeletePacket(data)
        Error(err) -> {
          logging.log(
            logging.Error,
            "Failed to decode MESSAGE_DELETE packet: " <> error.json_decode_error_to_string(err)
          )

          UnknownPacket(generic_packet)
        }
      }
    
    "INTERACTION_CREATE" ->
      case interaction_create.string_to_data(msg) {
        Ok(data) -> InteractionCreatePacket(data)
        Error(err) -> {
          logging.log(
            logging.Error,
            "Failed to decode INTERACTION_CREATE packet: " <> error.json_decode_error_to_string(err)
          )

          UnknownPacket(generic_packet)
        }
      }
    
    "CHANNEL_CREATE" ->
      case channel_create.string_to_data(msg) {
        Ok(data) -> ChannelCreatePacket(data)
        Error(err) -> {
          logging.log(
            logging.Error,
            "Failed to decode CHANNEL_CREATE packet: " <> error.json_decode_error_to_string(err)
          )

          UnknownPacket(generic_packet)
        }
      }
    
    "CHANNEL_DELETE" ->
      case channel_delete.string_to_data(msg) {
        Ok(data) -> ChannelDeletePacket(data)
        Error(err) -> {
          logging.log(
            logging.Error,
            "Failed to decode CHANNEL_DELETE packet: " <> error.json_decode_error_to_string(err)
          )

          UnknownPacket(generic_packet)
        }
      }
    
    "CHANNEL_UPDATE" ->
      case channel_update.string_to_data(msg) {
        Ok(data) -> ChannelUpdatePacket(data)
        Error(err) -> {
          logging.log(
            logging.Error,
            "Failed to decode CHANNEL_UPDATE packet: " <> error.json_decode_error_to_string(err)
          )

          UnknownPacket(generic_packet)
        }
      }
    
    "GUILD_BAN_ADD" ->
      case guild_ban_add.string_to_data(msg) {
        Ok(data) -> GuildBanAddPacket(data)
        Error(err) -> {
          logging.log(
            logging.Error,
            "Failed to decode GUILD_BAN_ADD packet: " <> error.json_decode_error_to_string(err)
          )

          UnknownPacket(generic_packet)
        }
      }
    
    "GUILD_BAN_REMOVE" ->
      case guild_ban_remove.string_to_data(msg) {
        Ok(data) -> GuildBanRemovePacket(data)
        Error(err) -> {
          logging.log(
            logging.Error,
            "Failed to decode GUILD_BAN_REMOVE packet: " <> error.json_decode_error_to_string(err)
          )

          UnknownPacket(generic_packet)
        }
      }
    
    _ -> UnknownPacket(generic_packet)
  }
}
