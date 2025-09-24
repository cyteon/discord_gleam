import booklet
import discord_gleam/internal/error
import discord_gleam/types/bot
import gleam/erlang/process
import gleam/option

import discord_gleam/ws/packets/channel_create
import discord_gleam/ws/packets/channel_delete
import discord_gleam/ws/packets/channel_update
import discord_gleam/ws/packets/generic
import discord_gleam/ws/packets/guild_ban_add
import discord_gleam/ws/packets/guild_ban_remove
import discord_gleam/ws/packets/guild_member_add
import discord_gleam/ws/packets/guild_member_remove
import discord_gleam/ws/packets/guild_member_update
import discord_gleam/ws/packets/guild_members_chunk
import discord_gleam/ws/packets/guild_role_create
import discord_gleam/ws/packets/guild_role_delete
import discord_gleam/ws/packets/guild_role_update
import discord_gleam/ws/packets/interaction_create
import discord_gleam/ws/packets/message
import discord_gleam/ws/packets/message_delete
import discord_gleam/ws/packets/message_delete_bulk
import discord_gleam/ws/packets/message_update
import discord_gleam/ws/packets/presence_update
import discord_gleam/ws/packets/ready
import gleam/dict
import gleam/list
import logging

pub type HandlerMessage(user_message) {
  DiscordPacket(Packet)
  User(user_message)
}

pub type InternalMessage(user_message) {
  InternalPacket(String)
  InternalUser(user_message)
}

pub type Next(new_state, user_message) {
  Continue(new_state, option.Option(process.Selector(user_message)))
  Stop
  StopAbnormal(reason: String)
}

pub type Mode(user_state, user_message) {
  Simple(
    bot: bot.Bot,
    handlers: List(fn(bot.Bot, Packet) -> Nil),
    next: Next(user_state, user_message),
    nil_state: user_state,
  )
  Normal(
    bot: bot.Bot,
    on_init: fn(process.Selector(user_message)) ->
      #(user_state, process.Selector(user_message)),
    handler: fn(bot.Bot, user_state, HandlerMessage(user_message)) ->
      Next(user_state, user_message),
  )
}

pub fn bot_from_mode(mode: Mode(user_state, user_message)) -> bot.Bot {
  case mode {
    Simple(bot, ..) -> bot
    Normal(bot, ..) -> bot
  }
}

/// The supported packets
pub type Packet {
  /// `READY` event
  ReadyPacket(ready.ReadyPacket)

  /// `INTERACTION_CREATE` event
  InteractionCreatePacket(interaction_create.InteractionCreatePacket)

  /// `MESSAGE_DELETE` event
  MessageDeletePacket(message_delete.MessageDeletePacket)
  /// `MESSAGE_CREATE` event
  MessagePacket(message.MessagePacket)
  /// `MESSAGE_UPDATE` event
  MessageUpdatePacket(message_update.MessageUpdatePacket)
  /// `MESSAGE_DELETE_BULK` event
  MessageDeleteBulkPacket(message_delete_bulk.MessageDeleteBulkPacket)

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

  /// `GUILD_ROLE_CREATE` event
  GuildRoleCreatePacket(guild_role_create.GuildRoleCreatePacket)
  /// `GUILD_ROLE_UPDATE` event
  GuildRoleUpdatePacket(guild_role_update.GuildRoleUpdatePacket)
  /// `GUILD_ROLE_DELETE` event
  GuildRoleDeletePacket(guild_role_delete.GuildRoleDeletePacket)

  /// `GUILD_MEMBER_ADD` event
  GuildMemberAddPacket(guild_member_add.GuildMemberAdd)
  /// `GUILD_MEMBER_UPDATE` event
  GuildMemberUpdatePacket(guild_member_update.GuildMemberUpdate)
  /// GUILD_MEMBER_REMOVE event
  GuildMemberRemovePacket(guild_member_remove.GuildMemberRemove)
  /// `GUILD_MEMBERS_CHUNK` event
  GuildMembersChunkPacket(guild_members_chunk.GuildMembersChunkPacket)

  /// `PRESENCE_UPDATE` event
  PresenceUpdatePacket(presence_update.PresenceUpdatePacket)

  /// When we receive a packet that we don't know how to handle
  UnknownPacket(generic.GenericPacket)
}

/// For handling some events the library needs to handle, for functionality
fn internal_handler(
  bot: bot.Bot,
  packet: Packet,
  state_ets: booklet.Booklet(dict.Dict(String, String)),
) -> Nil {
  case packet {
    MessagePacket(msg) -> {
      booklet.update(bot.cache.messages, fn(cache) {
        dict.insert(cache, msg.d.id, msg.d)
      })

      Nil
    }

    MessageUpdatePacket(msg) -> {
      booklet.update(bot.cache.messages, fn(cache) {
        dict.insert(cache, msg.d.id, msg.d)
      })

      Nil
    }

    ReadyPacket(ready) -> {
      booklet.update(state_ets, fn(cache) {
        let cache = dict.insert(cache, "session_id", ready.d.session_id)

        dict.insert(cache, "resume_gateway_url", ready.d.resume_gateway_url)
      })

      Nil
    }

    _ -> Nil
  }
}

/// Handle an event from the Discord API, using a set of event handlers.
pub fn handle_event(
  bot: bot.Bot,
  user_state: user_state,
  msg: InternalMessage(user_message),
  mode: Mode(user_state, user_message),
  state_ets: booklet.Booklet(dict.Dict(String, String)),
) -> Next(user_state, user_message) {
  case msg {
    InternalPacket(packet) -> {
      let packet = decode_packet(packet)
      internal_handler(bot, packet, state_ets)

      case mode {
        Simple(bot, handlers, next, _nil_state) -> {
          list.each(handlers, fn(handler) { handler(bot, packet) })
          next
        }
        Normal(bot, _on_init, handler) -> {
          handler(bot, user_state, DiscordPacket(packet))
        }
      }
    }
    InternalUser(msg) -> {
      let assert Normal(bot, _on_init, handler) = mode
      handler(bot, user_state, User(msg))
    }
  }
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
            "Failed to decode READY packet: "
              <> error.json_decode_error_to_string(err),
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
            "Failed to decode MESSAGE_CREATE packet: "
              <> error.json_decode_error_to_string(err),
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
            "Failed to decode MESSAGE_UPDATE packet: "
              <> error.json_decode_error_to_string(err),
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
            "Failed to decode MESSAGE_DELETE packet: "
              <> error.json_decode_error_to_string(err),
          )

          UnknownPacket(generic_packet)
        }
      }

    "MESSAGE_DELETE_BULK" ->
      case message_delete_bulk.string_to_data(msg) {
        Ok(data) -> MessageDeleteBulkPacket(data)
        Error(err) -> {
          logging.log(
            logging.Error,
            "Failed to decode MESSAGE_DELETE_BULK packet: "
              <> error.json_decode_error_to_string(err),
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
            "Failed to decode INTERACTION_CREATE packet: "
              <> error.json_decode_error_to_string(err),
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
            "Failed to decode CHANNEL_CREATE packet: "
              <> error.json_decode_error_to_string(err),
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
            "Failed to decode CHANNEL_DELETE packet: "
              <> error.json_decode_error_to_string(err),
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
            "Failed to decode CHANNEL_UPDATE packet: "
              <> error.json_decode_error_to_string(err),
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
            "Failed to decode GUILD_BAN_ADD packet: "
              <> error.json_decode_error_to_string(err),
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
            "Failed to decode GUILD_BAN_REMOVE packet: "
              <> error.json_decode_error_to_string(err),
          )

          UnknownPacket(generic_packet)
        }
      }

    "GUILD_ROLE_CREATE" ->
      case guild_role_create.string_to_data(msg) {
        Ok(data) -> GuildRoleCreatePacket(data)
        Error(err) -> {
          logging.log(
            logging.Error,
            "Failed to decode GUILD_ROLE_CREATE packet: "
              <> error.json_decode_error_to_string(err),
          )

          UnknownPacket(generic_packet)
        }
      }

    "GUILD_ROLE_UPDATE" ->
      case guild_role_update.string_to_data(msg) {
        Ok(data) -> GuildRoleUpdatePacket(data)
        Error(err) -> {
          logging.log(
            logging.Error,
            "Failed to decode GUILD_ROLE_UPDATE packet: "
              <> error.json_decode_error_to_string(err),
          )

          UnknownPacket(generic_packet)
        }
      }

    "GUILD_ROLE_DELETE" ->
      case guild_role_delete.string_to_data(msg) {
        Ok(data) -> GuildRoleDeletePacket(data)
        Error(err) -> {
          logging.log(
            logging.Error,
            "Failed to decode GUILD_ROLE_DELETE packet: "
              <> error.json_decode_error_to_string(err),
          )

          UnknownPacket(generic_packet)
        }
      }

    "GUILD_MEMBER_ADD" ->
      case guild_member_add.string_to_data(msg) {
        Ok(data) -> GuildMemberAddPacket(data)
        Error(err) -> {
          logging.log(
            logging.Error,
            "Failed to decode GUILD_MEMBER_ADD packet: "
              <> error.json_decode_error_to_string(err),
          )

          UnknownPacket(generic_packet)
        }
      }

    "GUILD_MEMBER_UPDATE" ->
      case guild_member_update.string_to_data(msg) {
        Ok(data) -> GuildMemberUpdatePacket(data)
        Error(err) -> {
          logging.log(
            logging.Error,
            "Failed to decode GUILD_MEMBER_UPDATE packet: "
              <> error.json_decode_error_to_string(err),
          )

          UnknownPacket(generic_packet)
        }
      }

    "GUILD_MEMBER_REMOVE" ->
      case guild_member_remove.string_to_data(msg) {
        Ok(data) -> GuildMemberRemovePacket(data)
        Error(err) -> {
          logging.log(
            logging.Error,
            "Failed to decode GUILD_MEMBER_REMOVE packet: "
              <> error.json_decode_error_to_string(err),
          )

          UnknownPacket(generic_packet)
        }
      }

    "GUILD_MEMBERS_CHUNK" ->
      case guild_members_chunk.string_to_data(msg) {
        Ok(data) -> GuildMembersChunkPacket(data)
        Error(err) -> {
          logging.log(
            logging.Error,
            "Failed to decode GUILD_MEMBERS_CHUNK packet: "
              <> error.json_decode_error_to_string(err),
          )
          UnknownPacket(generic_packet)
        }
      }

    "PRESENCE_UPDATE" ->
      case presence_update.string_to_data(msg) {
        Ok(data) -> PresenceUpdatePacket(data)
        Error(err) -> {
          logging.log(
            logging.Error,
            "Failed to decode PRESENCE_UPDATE packet: "
              <> error.json_decode_error_to_string(err),
          )

          UnknownPacket(generic_packet)
        }
      }

    _ -> UnknownPacket(generic_packet)
  }
}
