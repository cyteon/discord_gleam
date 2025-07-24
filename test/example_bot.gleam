import bravo/uset
import discord_gleam
import discord_gleam/discord/intents
import discord_gleam/event_handler
import discord_gleam/types/bot
import discord_gleam/types/message
import discord_gleam/types/slash_command
import discord_gleam/ws/packets/interaction_create
import gleam/bool
import gleam/erlang/process
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import logging

pub fn main(token: String, client_id: String, guild_id: String) {
  logging.configure()
  logging.set_level(logging.Info)

  let bot = discord_gleam.bot(token, client_id, intents.all())

  let test_cmd =
    slash_command.SlashCommand(
      name: "test",
      description: "Test command",
      options: [
        slash_command.CommandOption(
          name: "string",
          description: "Test option",
          type_: slash_command.StringOption,
          required: False,
        ),
        slash_command.CommandOption(
          name: "int",
          description: "Test option",
          type_: slash_command.IntOption,
          required: False,
        ),
      ],
    )

  let test_cmd2 =
    slash_command.SlashCommand(
      name: "test2",
      description: "Test command",
      options: [
        slash_command.CommandOption(
          name: "bool",
          description: "Test option",
          type_: slash_command.BoolOption,
          required: False,
        ),
        slash_command.CommandOption(
          name: "float",
          description: "Test option",
          type_: slash_command.FloatOption,
          required: False,
        ),
      ],
    )

  let _ = discord_gleam.wipe_global_commands(bot)
  let _ = discord_gleam.register_global_commands(bot, [test_cmd])

  let _ = discord_gleam.wipe_guild_commands(bot, guild_id)
  let _ = discord_gleam.register_guild_commands(bot, guild_id, [test_cmd2])

  discord_gleam.run(bot, [handler])
}

fn handler(bot: bot.Bot, packet: event_handler.Packet) {
  case packet {
    event_handler.ReadyPacket(ready) -> {
      logging.log(
        logging.Info,
        "Logged in as "
          <> ready.d.user.username
          <> "#"
          <> ready.d.user.discriminator,
      )

      Nil
    }

    event_handler.MessageUpdatePacket(message_update) -> {
      logging.log(
        logging.Info,
        "Message edited, new content: " <> message_update.d.content,
      )
    }

    event_handler.GuildBanAddPacket(ban) -> {
      logging.log(
        logging.Info,
        "User banned: "
          <> ban.d.user.username
          <> " (ID: "
          <> ban.d.user.id
          <> ")",
      )
    }

    event_handler.GuildBanRemovePacket(ban) -> {
      logging.log(
        logging.Info,
        "User unbanned: "
          <> ban.d.user.username
          <> " (ID: "
          <> ban.d.user.id
          <> ")",
      )
    }

    event_handler.GuildRoleCreatePacket(role) -> {
      logging.log(
        logging.Info,
        "Role created: "
          <> role.d.role.name
          <> " (ID: "
          <> role.d.role.id
          <> ")",
      )

      Nil
    }

    event_handler.GuildRoleUpdatePacket(role) -> {
      logging.log(
        logging.Info,
        "Role updated: "
          <> role.d.role.name
          <> " (ID: "
          <> role.d.role.id
          <> ")",
      )

      Nil
    }

    event_handler.GuildRoleDeletePacket(role) -> {
      logging.log(logging.Info, "Role deleted: " <> role.d.role_id)

      Nil
    }

    event_handler.ChannelCreatePacket(channel) -> {
      case channel.d.guild_id {
        // only create if channel in guild
        // aka not on DM channel create
        Some(_) -> {
          logging.log(
            logging.Info,
            "Channel created: "
              <> case channel.d.name {
              Some(name) -> name
              None -> "No name"
            }
              <> " (ID: "
              <> channel.d.id
              <> ")",
          )

          let _ =
            discord_gleam.send_message(
              bot,
              channel.d.id,
              "Channel created: "
                <> case channel.d.name {
                Some(name) -> name
                None -> "No name"
              }
                <> "\nID: "
                <> channel.d.id
                <> "\nParent ID: "
                <> case channel.d.parent_id {
                Some(id) -> id
                None -> "None"
              },
              [],
            )

          Nil
        }

        None -> {
          logging.log(logging.Info, "DM channel created: " <> channel.d.id)

          let _ =
            discord_gleam.send_message(
              bot,
              channel.d.id,
              "DM channel created: " <> channel.d.id,
              [],
            )

          Nil
        }
      }
    }

    event_handler.ChannelDeletePacket(channel) -> {
      logging.log(
        logging.Info,
        "Channel deleted: "
          <> case channel.d.name {
          Some(name) -> name
          None -> "No name"
        }
          <> " (ID: "
          <> channel.d.id
          <> ")",
      )
    }

    event_handler.ChannelUpdatePacket(channel) -> {
      logging.log(
        logging.Info,
        "Channel updated: "
          <> case channel.d.name {
          Some(name) -> name
          None -> "No name"
        }
          <> " (ID: "
          <> channel.d.id
          <> ")",
      )
    }

    event_handler.MessagePacket(message) -> {
      case message.d.author.id != bot.client_id {
        True -> {
          logging.log(logging.Info, "Got message: " <> message.d.content)

          case message.d.content {
            "!ping" -> {
              let _ =
                discord_gleam.send_message(
                  bot,
                  message.d.channel_id,
                  "Pong!",
                  [],
                )

              Nil
            }

            "!edit" -> {
              let msg =
                discord_gleam.send_message(
                  bot,
                  message.d.channel_id,
                  "This message will be edited in 5 seconds!",
                  [],
                )

              case msg {
                Ok(msg) -> {
                  process.sleep(5000)

                  let _ =
                    discord_gleam.edit_message(
                      bot,
                      message.d.channel_id,
                      msg.id,
                      "This message has been edited!",
                      [],
                    )

                  Nil
                }

                Error(err) -> {
                  let _ =
                    discord_gleam.send_message(
                      bot,
                      message.d.channel_id,
                      "Failed to send message!",
                      [],
                    )

                  echo err

                  Nil
                }
              }

              Nil
            }

            "!dm_channel" -> {
              let res =
                discord_gleam.create_dm_channel(bot, message.d.author.id)

              let _ = echo res

              case res {
                Ok(channel) -> {
                  let _ =
                    discord_gleam.send_message(
                      bot,
                      message.d.channel_id,
                      "ID: "
                        <> channel.id
                        <> "\nLast message ID: "
                        <> case channel.last_message_id {
                        Some(id) -> id
                        None -> "None"
                      },
                      [],
                    )

                  Nil
                }

                Error(err) -> {
                  let _ =
                    discord_gleam.send_message(
                      bot,
                      message.d.channel_id,
                      "Failed to create DM channel!",
                      [],
                    )

                  echo err

                  Nil
                }
              }
            }

            "!dm" -> {
              let res =
                discord_gleam.send_direct_message(
                  bot,
                  message.d.author.id,
                  "DM!",
                  [],
                )

              case res {
                Ok(_) -> {
                  let _ =
                    discord_gleam.send_message(
                      bot,
                      message.d.channel_id,
                      "DM sent!",
                      [],
                    )

                  Nil
                }

                Error(err) -> {
                  let _ =
                    discord_gleam.send_message(
                      bot,
                      message.d.channel_id,
                      "Failed to send DM!",
                      [],
                    )

                  echo err

                  Nil
                }
              }
            }

            "!embed" -> {
              let embed1 =
                message.Embed(
                  title: "Embed Title",
                  description: "Embed Description",
                  color: 0x00FF00,
                )

              let _ =
                discord_gleam.send_message(bot, message.d.channel_id, "Embed!", [
                  embed1,
                ])

              Nil
            }

            "!reply" -> {
              let _ =
                discord_gleam.reply(
                  bot,
                  message.d.channel_id,
                  message.d.id,
                  "Reply!",
                  [],
                )

              Nil
            }

            "hello" -> {
              let _ =
                discord_gleam.reply(
                  bot,
                  message.d.channel_id,
                  message.d.id,
                  "hello",
                  [],
                )

              Nil
            }

            _ -> Nil
          }
        }

        False -> Nil
      }

      case message.d.content, message.d.guild_id {
        "!kick " <> args, Some(guild_id) -> {
          let args = string.split(args, " ")
          let #(user, args) = case args {
            [user, ..args] -> #(user, args)
            _ -> #("", [])
          }

          let user = string.replace(user, "<@", "")
          let user = string.replace(user, ">", "")

          let reason = string.join(args, " ")

          let resp = discord_gleam.kick_member(bot, guild_id, user, reason)

          case resp {
            Ok(_) -> {
              let _ =
                discord_gleam.send_message(
                  bot,
                  message.d.channel_id,
                  "Kicked user!",
                  [],
                )

              Nil
            }

            Error(_) -> {
              let _ =
                discord_gleam.send_message(
                  bot,
                  message.d.channel_id,
                  "Failed to kick user!",
                  [],
                )

              Nil
            }
          }
        }

        _, _ -> Nil
      }

      case message.d.content, message.d.guild_id {
        "!ban " <> args, Some(guild_id) -> {
          let args = string.split(args, " ")
          let #(user, args) = case args {
            [user, ..args] -> #(user, args)
            _ -> #("", [])
          }

          let user = string.replace(user, "<@", "")
          let user = string.replace(user, ">", "")

          let reason = string.join(args, " ")

          let resp = discord_gleam.ban_member(bot, guild_id, user, reason)

          case resp {
            Ok(_) -> {
              let _ =
                discord_gleam.send_message(
                  bot,
                  message.d.channel_id,
                  "Banned user!",
                  [],
                )

              Nil
            }

            Error(_) -> {
              let _ =
                discord_gleam.send_message(
                  bot,
                  message.d.channel_id,
                  "Failed to ban user!",
                  [],
                )

              Nil
            }
          }
        }

        _, _ -> Nil
      }
    }

    event_handler.MessageDeletePacket(deleted) -> {
      logging.log(logging.Info, "Deleted message: " <> deleted.d.id)

      case bot.cache.messages {
        option.Some(cache) -> {
          let msg = uset.lookup(cache, deleted.d.id)

          case msg {
            Ok(msg) -> {
              logging.log(
                logging.Info,
                "Message content: " <> { msg.1 }.content,
              )
            }
            Error(_) -> {
              logging.log(logging.Info, "Deleted message not found")
            }
          }

          Nil
        }
        option.None -> Nil
      }
      Nil
    }

    event_handler.MessageDeleteBulkPacket(deleted_bulk) -> {
      logging.log(
        logging.Info,
        "Bulk deleted messages: "
          <> list.fold(deleted_bulk.d.ids, "", fn(acc, id) { acc <> id <> ", " }),
      )
    }

    event_handler.InteractionCreatePacket(interaction) -> {
      logging.log(logging.Info, "Interaction: " <> interaction.d.data.name)

      case interaction.d.data.name {
        "test" -> {
          let _ = case interaction.d.data.options {
            Some(options) -> {
              let value = case list.first(options) {
                Ok(option) ->
                  case option.value {
                    interaction_create.StringValue(value) -> value
                    interaction_create.IntValue(value) -> int.to_string(value)
                    interaction_create.BoolValue(value) -> bool.to_string(value)
                    interaction_create.FloatValue(value) ->
                      float.to_string(value)
                  }

                Error(_) -> "No value"
              }

              let _ =
                discord_gleam.interaction_reply_message(
                  interaction,
                  "test: " <> value,
                  True,
                  // ephemeral
                )
            }

            None -> {
              let _ =
                discord_gleam.interaction_reply_message(
                  interaction,
                  "test: No options",
                  True,
                )
            }
          }

          Nil
        }

        "test2" -> {
          let _ = case interaction.d.data.options {
            Some(options) -> {
              let value = case list.last(options) {
                Ok(option) ->
                  case option.value {
                    interaction_create.StringValue(value) -> value
                    interaction_create.IntValue(value) -> int.to_string(value)
                    interaction_create.BoolValue(value) -> bool.to_string(value)
                    interaction_create.FloatValue(value) ->
                      float.to_string(value)
                  }

                Error(_) -> "No value"
              }

              let _ =
                discord_gleam.interaction_reply_message(
                  interaction,
                  "test2: " <> value,
                  False,
                )
            }

            None -> {
              let _ =
                discord_gleam.interaction_reply_message(
                  interaction,
                  "test2: No options",
                  False,
                )
            }
          }

          Nil
        }

        _ -> Nil
      }
    }

    _ -> Nil
  }
}
