import booklet
import gleam/dict
import gleam/erlang/process
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/string
import logging

import discord_gleam/bot
import discord_gleam/discord/snowflake
import discord_gleam/internal/error
import discord_gleam/types/channel
import discord_gleam/types/guild
import discord_gleam/types/presence
import discord_gleam/ws/gateway_state
import discord_gleam/ws/packets/channel_create
import discord_gleam/ws/packets/channel_delete
import discord_gleam/ws/packets/channel_update
import discord_gleam/ws/packets/generic
import discord_gleam/ws/packets/guild_ban_add
import discord_gleam/ws/packets/guild_ban_remove
import discord_gleam/ws/packets/guild_create
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

/// The message type for the event handler with custom user messages
pub type HandlerMessage(user_message) {
  DiscordPacket(Packet)
  User(user_message)
}

/// The message type received from event loop
pub type InternalMessage(user_message) {
  InternalPacket(String)
  InternalUser(user_message)
}

/// Instruction on how event loop actor should proceed after handling an event
pub type Next(new_state, user_message) {
  Continue(new_state, Option(process.Selector(user_message)))
  Stop
  StopAbnormal(reason: String)
}

/// The mode of the event handler
///
/// Simple mode is used for simple bots that don't need to handle custom user
/// state and messages. `default_next` and `nil_state` fields are required for
/// proper type inference. Recommended to use `Nil` state and continue with no
/// selector.
///
/// Normal mode is used for bots that need to handle custom user state
/// and messages.
pub type Mode(user_state, user_message) {
  Simple(
    bot: bot.Bot,
    handlers: List(fn(bot.Bot, Packet) -> Nil),
    default_next: Next(user_state, user_message),
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

/// Check if the mode is normal mode
pub fn name_from_mode(
  mode: Mode(user_state, user_message),
) -> Result(process.Name(user_message), Nil) {
  case mode {
    Normal(name:, ..) -> Ok(name)
    Simple(..) -> Error(Nil)
  }
}

/// Get the bot from all possible modes
pub fn bot_from_mode(mode: Mode(user_state, user_message)) -> bot.Bot {
  case mode {
    Simple(bot, ..) -> bot
    Normal(bot, ..) -> bot
  }
}

pub fn set_bot(
  mode: Mode(user_state, user_message),
  bot: bot.Bot,
) -> Mode(user_state, user_message) {
  case mode {
    Simple(..) -> Simple(..mode, bot:)
    Normal(..) -> Normal(..mode, bot:)
  }
}

/// The supported discord packets
pub type Packet {
  /// `READY` event
  ReadyPacket(ready.ReadyData)

  /// `INTERACTION_CREATE` event
  InteractionCreatePacket(interaction_create.InteractionCreatePacketData)

  /// `MESSAGE_DELETE` event
  MessageDeletePacket(message_delete.MessageDeletePacketData)
  /// `MESSAGE_CREATE` event
  MessagePacket(message.MessagePacketData)
  /// `MESSAGE_UPDATE` event
  MessageUpdatePacket(message.MessagePacketData)
  /// `MESSAGE_DELETE_BULK` event
  MessageDeleteBulkPacket(message_delete_bulk.MessageDeleteBulkPacketData)

  /// `CHANNEL_CREATE` event
  ChannelCreatePacket(channel.Channel)
  /// `CHANNEL_DELETE` event
  ChannelDeletePacket(channel.Channel)
  /// `CHANNEL_UPDATE` event
  ChannelUpdatePacket(channel.Channel)

  /// `GUILD_BAN_ADD` event
  GuildBanAddPacket(guild_ban_add.GuildBanAddPacketData)
  /// `GUILD_BAN_REMOVE` event
  GuildBanRemovePacket(guild_ban_remove.GuildBanRemovePacketData)

  /// `GUILD_CREATE` event
  GuildCreatePacket(guild.Guild)

  /// `GUILD_ROLE_CREATE` event
  GuildRoleCreatePacket(guild_role_create.GuildRoleCreatePacketData)
  /// `GUILD_ROLE_UPDATE` event
  GuildRoleUpdatePacket(guild_role_update.GuildRoleUpdatePacketData)
  /// `GUILD_ROLE_DELETE` event
  GuildRoleDeletePacket(guild_role_delete.GuildRoleDeletePacketData)

  /// `GUILD_MEMBER_ADD` event
  GuildMemberAddPacket(guild_member_add.GuildMemberAddPacketData)
  /// `GUILD_MEMBER_UPDATE` event
  GuildMemberUpdatePacket(guild_member_update.GuildMemberUpdatePacketData)
  /// GUILD_MEMBER_REMOVE event
  GuildMemberRemovePacket(guild_member_remove.GuildMemberRemovePacketData)
  /// `GUILD_MEMBERS_CHUNK` event
  GuildMembersChunkPacket(guild_members_chunk.GuildMembersChunkPacketData)

  /// `PRESENCE_UPDATE` event
  PresenceUpdatePacket(presence.Presence)

  /// When we receive a packet that we don't know how to handle
  UnknownPacket(generic.GenericPacket)
}

fn cache_message(bot: bot.Bot, msg: message.MessagePacketData) -> Nil {
  booklet.update(bot.cache.messages, fn(cache) {
    let cache = dict.insert(cache, msg.id, msg)

    case dict.size(cache) > bot.message_cache_limit {
      True -> {
        case
          dict.keys(cache)
          |> list.reduce(fn(a, b) {
            case snowflake.compare(a, b) {
              order.Lt -> a
              _ -> b
            }
          })
        {
          Ok(oldest) -> dict.delete(cache, oldest)
          Error(_) -> cache
        }
      }

      False -> cache
    }
  })

  Nil
}

/// For handling some events the library needs to handle, for functionality
fn internal_handler(
  bot: bot.Bot,
  packet: Packet,
  state_ets: booklet.Booklet(gateway_state.GatewayState),
) -> Nil {
  case packet {
    MessagePacket(msg) -> {
      cache_message(bot, msg)
    }

    MessageUpdatePacket(msg) -> {
      cache_message(bot, msg)
    }

    ReadyPacket(ready) -> {
      booklet.update(state_ets, fn(state) {
        gateway_state.GatewayState(
          ..state,
          session_id: ready.session_id,
          resume_gateway_url: string.replace(
            ready.resume_gateway_url,
            "wss://",
            "",
          ),
        )
      })

      Nil
    }

    _ -> Nil
  }
}

/// Handle an event from the Discord API, using a current handler mode, state
/// and internal message.
pub fn handle_event(
  bot: bot.Bot,
  user_state: user_state,
  msg: InternalMessage(user_message),
  mode: Mode(user_state, user_message),
  state_ets: booklet.Booklet(gateway_state.GatewayState),
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

        Normal(bot, _name, _on_init, handler) -> {
          handler(bot, user_state, DiscordPacket(packet))
        }
      }
    }

    InternalUser(msg) -> {
      case mode {
        Normal(bot, _name, _on_init, handler) -> {
          handler(bot, user_state, User(msg))
        }

        _ -> {
          logging.log(
            logging.Error,
            "Received user message in simple mode, ignoring",
          )

          Continue(user_state, None)
        }
      }
    }
  }
}

fn decode_packet(msg: String) -> Packet {
  let generic_packet = generic.from_json_string(msg)

  case generic_packet.t {
    Some(t) -> {
      case t {
        "READY" ->
          case ready.from_json_string(msg) {
            Ok(packet) -> ReadyPacket(packet.d)

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
          case message.from_json_string(msg) {
            Ok(packet) -> MessagePacket(packet.d)
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
          case message_update.from_json_string(msg) {
            Ok(packet) -> MessageUpdatePacket(packet.d)
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
          case message_delete.from_json_string(msg) {
            Ok(packet) -> MessageDeletePacket(packet.d)
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
          case message_delete_bulk.from_json_string(msg) {
            Ok(packet) -> MessageDeleteBulkPacket(packet.d)
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
          case interaction_create.from_json_string(msg) {
            Ok(packet) -> InteractionCreatePacket(packet.d)
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
          case channel_create.from_json_string(msg) {
            Ok(packet) -> ChannelCreatePacket(packet.d)
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
          case channel_delete.from_json_string(msg) {
            Ok(packet) -> ChannelDeletePacket(packet.d)
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
          case channel_update.from_json_string(msg) {
            Ok(packet) -> ChannelUpdatePacket(packet.d)
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
          case guild_ban_add.from_json_string(msg) {
            Ok(packet) -> GuildBanAddPacket(packet.d)
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
          case guild_ban_remove.from_json_string(msg) {
            Ok(packet) -> GuildBanRemovePacket(packet.d)
            Error(err) -> {
              logging.log(
                logging.Error,
                "Failed to decode GUILD_BAN_REMOVE packet: "
                  <> error.json_decode_error_to_string(err),
              )

              UnknownPacket(generic_packet)
            }
          }

        "GUILD_CREATE" ->
          case guild_create.from_json_string(msg) {
            Ok(packet) -> GuildCreatePacket(packet.d)

            Error(err) -> {
              logging.log(
                logging.Error,
                "Failed to decode GUILD_CREATE packet: "
                  <> error.json_decode_error_to_string(err),
              )

              UnknownPacket(generic_packet)
            }
          }

        "GUILD_ROLE_CREATE" ->
          case guild_role_create.from_json_string(msg) {
            Ok(packet) -> GuildRoleCreatePacket(packet.d)
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
          case guild_role_update.from_json_string(msg) {
            Ok(packet) -> GuildRoleUpdatePacket(packet.d)
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
          case guild_role_delete.from_json_string(msg) {
            Ok(packet) -> GuildRoleDeletePacket(packet.d)
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
          case guild_member_add.from_json_string(msg) {
            Ok(packet) -> GuildMemberAddPacket(packet.d)
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
          case guild_member_update.from_json_string(msg) {
            Ok(packet) -> GuildMemberUpdatePacket(packet.d)
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
          case guild_member_remove.from_json_string(msg) {
            Ok(packet) -> GuildMemberRemovePacket(packet.d)
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
          case guild_members_chunk.from_json_string(msg) {
            Ok(packet) -> GuildMembersChunkPacket(packet.d)
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
          case presence_update.from_json_string(msg) {
            Ok(packet) -> PresenceUpdatePacket(packet.d)
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

    _ -> UnknownPacket(generic_packet)
  }
}
