import booklet
import discord_gleam
import discord_gleam/discord/intents
import discord_gleam/event_handler
import discord_gleam/types/bot
import discord_gleam/types/guild
import discord_gleam/types/message
import discord_gleam/types/slash_command
import discord_gleam/ws/commands/request_guild_members
import discord_gleam/ws/packets/interaction_create
import gleam/bool
import gleam/dict
import gleam/erlang/process
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/static_supervisor as supervisor
import gleam/otp/supervision
import gleam/string
import logging

pub fn main(token: String, client_id: String, guild_id: String) {
  logging.configure()
  logging.set_level(logging.Debug)

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

  // SIMPLE BOT EXAMPLE
  // let bot =
  //   supervision.worker(fn() {
  //     discord_gleam.simple(bot, [simple_handler])
  //     |> discord_gleam.start()
  //   })

  // NORMAL BOT EXAMPLE
  let bot =
    supervision.worker(fn() {
      discord_gleam.new(
        bot,
        fn(selector) {
          let subject = process.new_subject()

          #(subject, process.select(selector, subject))
        },
        normal_handler,
      )
      |> discord_gleam.start()
    })

  let assert Ok(_) =
    supervisor.new(supervisor.OneForOne)
    |> supervisor.add(bot)
    |> supervisor.start()

  process.sleep_forever()
}

fn simple_handler(bot: bot.Bot, packet: event_handler.Packet) {
  case packet {
    event_handler.ReadyPacket(ready) -> {
      logging.log(
        logging.Info,
        "Logged in as "
          <> ready.d.user.username
          <> "#"
          <> ready.d.user.discriminator,
      )

      list.each(ready.d.guilds, fn(guild) {
        let assert guild.UnavailableGuild(id, ..) = guild
        logging.log(logging.Info, "Unavailable guild: " <> id)

        discord_gleam.request_guild_members(
          bot,
          guild_id: id,
          option: request_guild_members.Query("", option.None),
          presences: option.Some(True),
          nonce: option.Some("test_request"),
        )
      })

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

    event_handler.GuildMemberAddPacket(member_add) -> {
      logging.log(
        logging.Info,
        "Member added: "
          <> member_add.d.guild_member.user.username
          <> " (ID: "
          <> member_add.d.guild_member.user.id
          <> ")",
      )
    }

    event_handler.GuildMemberRemovePacket(member_remove) -> {
      logging.log(
        logging.Info,
        "Member removed: "
          <> member_remove.d.user.username
          <> " (ID: "
          <> member_remove.d.user.id
          <> ")",
      )
    }

    event_handler.GuildMemberUpdatePacket(member_update) -> {
      logging.log(
        logging.Info,
        "Member updated: "
          <> member_update.d.guild_member.user.username
          <> " (ID: "
          <> member_update.d.guild_member.user.id
          <> ")",
      )
    }

    event_handler.GuildMembersChunkPacket(chunk) -> {
      logging.log(
        logging.Info,
        "Guild members chunk received: " <> chunk.d.guild_id,
      )
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

      let msg = dict.get(booklet.get(bot.cache.messages), deleted.d.id)

      case msg {
        Ok(msg) -> {
          logging.log(logging.Info, "Message content: " <> msg.content)
        }
        Error(_) -> {
          logging.log(logging.Info, "Deleted message not found")
        }
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

    event_handler.PresenceUpdatePacket(presence) -> {
      logging.log(logging.Info, "Presence updated for: " <> presence.d.user.id)
    }

    _ -> Nil
  }
}

fn normal_handler(
  bot: bot.Bot,
  state: process.Subject(String),
  msg: discord_gleam.HandlerMessage(String),
) {
  case msg {
    discord_gleam.Packet(packet) -> {
      case packet {
        event_handler.MessagePacket(message) -> {
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

              discord_gleam.continue(state)
            }
            "!send " <> message -> {
              process.send(state, message)

              discord_gleam.continue(state)
            }
            "!stop" -> {
              discord_gleam.stop()
            }
            "!stop_abnormal" -> {
              discord_gleam.stop_abnormal("testing what will happen")
            }
            _ -> discord_gleam.continue(state)
          }
        }
        _ -> discord_gleam.continue(state)
      }
    }

    discord_gleam.User(msg) -> {
      logging.log(logging.Info, "Got user message from subject: " <> msg)
      discord_gleam.continue(state)
    }
  }
}
