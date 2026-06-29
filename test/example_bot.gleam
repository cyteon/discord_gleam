import booklet
import discord_gleam
import discord_gleam/bot
import discord_gleam/discord/intents
import discord_gleam/discord/snowflake
import discord_gleam/event_handler
import discord_gleam/types/embed
import discord_gleam/types/guild
import discord_gleam/types/interaction
import discord_gleam/types/message
import discord_gleam/types/slash_command
import discord_gleam/ws/commands/request_guild_members
import discord_gleam/ws/commands/update_presence
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

  let bot =
    bot.new(token, client_id)
    |> bot.with_intents(intents.default_with_message_intent())

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

  let _ =
    discord_gleam.wipe_guild_commands(bot, snowflake.from_string(guild_id))
  let _ =
    discord_gleam.register_guild_commands(bot, snowflake.from_string(guild_id), [
      test_cmd2,
    ])

  // putting this here so i dont have to comment out like 20 lines to test one or the other
  let use_simple = True

  let _ = case use_simple {
    True -> {
      let bot =
        supervision.worker(fn() {
          discord_gleam.simple(bot, [simple_handler])
          |> discord_gleam.start()
        })

      let assert Ok(_) =
        supervisor.new(supervisor.OneForOne)
        |> supervisor.add(bot)
        |> supervisor.start()
    }

    False -> {
      let name = process.new_name("user_message_subject")
      let bot =
        supervision.worker(fn() {
          discord_gleam.new(
            bot,
            fn(selector) {
              let subject = process.new_subject()

              process.send_after(
                process.named_subject(name),
                1000,
                "named subject message",
              )

              #(subject, process.select(selector, subject))
            },
            fn(bot, state, msg) { normal_handler(bot, state, name, msg) },
          )
          |> discord_gleam.with_name(name)
          |> discord_gleam.start()
        })

      let assert Ok(_) =
        supervisor.new(supervisor.OneForOne)
        |> supervisor.add(bot)
        |> supervisor.start()
    }
  }

  process.sleep_forever()
}

fn simple_handler(bot: bot.Bot, packet: event_handler.Packet) {
  case packet {
    event_handler.ReadyPacket(ready) -> {
      logging.log(
        logging.Info,
        "Logged in as "
          <> ready.user.username
          <> "#"
          <> ready.user.discriminator,
      )

      list.each(ready.guilds, fn(guild) {
        let assert guild.UnavailableGuild(id, ..) = guild
        logging.log(
          logging.Info,
          "Unavailable guild: " <> snowflake.to_string(id),
        )

        discord_gleam.request_guild_members(
          bot: bot,
          guild_id: id,
          option: request_guild_members.Query("", None),
          presences: Some(True),
          nonce: Some("test_request"),
        )
      })

      discord_gleam.update_presence(
        bot,
        update_presence.Presence(
          activities: [update_presence.playing("Gleam!")],
          afk: False,
          since: None,
          status: update_presence.Online,
        ),
      )

      Nil
    }

    event_handler.MessageUpdatePacket(message_update) -> {
      logging.log(
        logging.Info,
        "Message edited, new content: " <> message_update.content,
      )
    }

    event_handler.GuildBanAddPacket(ban) -> {
      logging.log(
        logging.Info,
        "User banned: "
          <> ban.user.username
          <> " (ID: "
          <> snowflake.to_string(ban.user.id)
          <> ")",
      )
    }

    event_handler.GuildBanRemovePacket(ban) -> {
      logging.log(
        logging.Info,
        "User unbanned: "
          <> ban.user.username
          <> " (ID: "
          <> snowflake.to_string(ban.user.id)
          <> ")",
      )
    }

    event_handler.GuildRoleCreatePacket(role) -> {
      logging.log(
        logging.Info,
        "Role created: "
          <> role.role.name
          <> " (ID: "
          <> snowflake.to_string(role.role.id)
          <> ")",
      )

      Nil
    }

    event_handler.GuildRoleUpdatePacket(role) -> {
      logging.log(
        logging.Info,
        "Role updated: "
          <> role.role.name
          <> " (ID: "
          <> snowflake.to_string(role.role.id)
          <> ")",
      )

      Nil
    }

    event_handler.GuildCreatePacket(guild) -> {
      case guild {
        guild.Guild(id, name, ..) -> {
          logging.log(
            logging.Info,
            "Guild created: "
              <> name
              <> " (ID: "
              <> snowflake.to_string(id)
              <> ")",
          )
        }

        guild.UnavailableGuild(id, ..) -> {
          logging.log(
            logging.Info,
            "Unavailable guild: " <> snowflake.to_string(id),
          )
        }
      }

      Nil
    }

    event_handler.GuildRoleDeletePacket(role) -> {
      logging.log(
        logging.Info,
        "Role deleted: " <> snowflake.to_string(role.role_id),
      )

      Nil
    }

    event_handler.GuildMemberAddPacket(member_add) -> {
      logging.log(
        logging.Info,
        "Member added: "
          <> member_add.guild_member.user.username
          <> " (ID: "
          <> snowflake.to_string(member_add.guild_member.user.id)
          <> ")",
      )
    }

    event_handler.GuildMemberRemovePacket(member_remove) -> {
      logging.log(
        logging.Info,
        "Member removed: "
          <> member_remove.user.username
          <> " (ID: "
          <> snowflake.to_string(member_remove.user.id)
          <> ")",
      )
    }

    event_handler.GuildMemberUpdatePacket(member_update) -> {
      logging.log(
        logging.Info,
        "Member updated: "
          <> member_update.guild_member.user.username
          <> " (ID: "
          <> snowflake.to_string(member_update.guild_member.user.id)
          <> ")",
      )
    }

    event_handler.GuildMembersChunkPacket(chunk) -> {
      logging.log(
        logging.Info,
        "Guild members chunk received: " <> snowflake.to_string(chunk.guild_id),
      )
    }

    event_handler.ChannelCreatePacket(channel) -> {
      case channel.guild_id {
        // only create if channel in guild
        // aka not on DM channel create
        Some(_) -> {
          logging.log(
            logging.Info,
            "Channel created: "
              <> case channel.name {
              Some(name) -> name
              None -> "No name"
            }
              <> " (ID: "
              <> snowflake.to_string(channel.id)
              <> ")",
          )

          let _ =
            discord_gleam.send_message(
              bot,
              channel.id,
              "Channel created: "
                <> case channel.name {
                Some(name) -> name
                None -> "No name"
              }
                <> "\nID: "
                <> snowflake.to_string(channel.id)
                <> "\nParent ID: "
                <> case channel.parent_id {
                Some(id) -> snowflake.to_string(id)
                None -> "None"
              },
              [],
            )

          Nil
        }

        None -> {
          logging.log(
            logging.Info,
            "DM channel created: " <> snowflake.to_string(channel.id),
          )

          let _ =
            discord_gleam.send_message(
              bot,
              channel.id,
              "DM channel created: " <> snowflake.to_string(channel.id),
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
          <> case channel.name {
          Some(name) -> name
          None -> "No name"
        }
          <> " (ID: "
          <> snowflake.to_string(channel.id)
          <> ")",
      )
    }

    event_handler.ChannelUpdatePacket(channel) -> {
      logging.log(
        logging.Info,
        "Channel updated: "
          <> case channel.name {
          Some(name) -> name
          None -> "No name"
        }
          <> " (ID: "
          <> snowflake.to_string(channel.id)
          <> ")",
      )
    }

    event_handler.MessagePacket(message) -> {
      case
        snowflake.to_string(message.author.id)
        != snowflake.to_string(bot.client_id)
      {
        True -> {
          logging.log(logging.Info, "Got message: " <> message.content)

          case message.content {
            "!ping" -> {
              let _ =
                discord_gleam.send_message(bot, message.channel_id, "Pong!", [])

              Nil
            }

            "!edit" -> {
              let msg =
                discord_gleam.send_message(
                  bot,
                  message.channel_id,
                  "This message will be edited in 5 seconds!",
                  [],
                )

              case msg {
                Ok(msg) -> {
                  process.sleep(5000)

                  let _ =
                    discord_gleam.edit_message(
                      bot,
                      message.channel_id,
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
                      message.channel_id,
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
              let res = discord_gleam.create_dm_channel(bot, message.author.id)

              let _ = echo res

              case res {
                Ok(channel) -> {
                  let _ =
                    discord_gleam.send_message(
                      bot,
                      message.channel_id,
                      "ID: "
                        <> snowflake.to_string(channel.id)
                        <> "\nLast message ID: "
                        <> case channel.last_message_id {
                        Some(id) -> snowflake.to_string(id)
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
                      message.channel_id,
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
                  message.author.id,
                  "DM!",
                  [],
                )

              case res {
                Ok(_) -> {
                  let _ =
                    discord_gleam.send_message(
                      bot,
                      message.channel_id,
                      "DM sent!",
                      [],
                    )

                  Nil
                }

                Error(err) -> {
                  let _ =
                    discord_gleam.send_message(
                      bot,
                      message.channel_id,
                      "Failed to send DM!",
                      [],
                    )

                  echo err

                  Nil
                }
              }
            }

            "!embed" -> {
              let embed =
                embed.new("Embed Title", "Embed Description", 0x00FF00)

              let _ =
                discord_gleam.send_message(bot, message.channel_id, "Embed!", [
                  embed,
                ])

              Nil
            }

            "!reply" -> {
              let _ =
                discord_gleam.reply(
                  bot,
                  message.channel_id,
                  message.id,
                  "Reply!",
                  [],
                )

              Nil
            }

            "hello" -> {
              let _ =
                discord_gleam.reply(
                  bot,
                  message.channel_id,
                  message.id,
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

      case message.content, message.guild_id {
        "!kick " <> args, Some(guild_id) -> {
          let args = string.split(args, " ")
          let #(user, args) = case args {
            [user, ..args] -> #(user, args)
            _ -> #("", [])
          }

          let user =
            string.replace(user, "<@", "")
            |> string.replace(">", "")
            |> snowflake.from_string

          let reason = string.join(args, " ")

          let resp = discord_gleam.kick_member(bot, guild_id, user, reason)

          case resp {
            Ok(_) -> {
              let _ =
                discord_gleam.send_message(
                  bot,
                  message.channel_id,
                  "Kicked user!",
                  [],
                )

              Nil
            }

            Error(_) -> {
              let _ =
                discord_gleam.send_message(
                  bot,
                  message.channel_id,
                  "Failed to kick user!",
                  [],
                )

              Nil
            }
          }
        }

        _, _ -> Nil
      }

      case message.content, message.guild_id {
        "!ban " <> args, Some(guild_id) -> {
          let args = string.split(args, " ")
          let #(user, args) = case args {
            [user, ..args] -> #(user, args)
            _ -> #("", [])
          }

          let user =
            string.replace(user, "<@", "")
            |> string.replace(">", "")
            |> snowflake.from_string

          let reason = string.join(args, " ")

          let resp = discord_gleam.ban_member(bot, guild_id, user, reason)

          case resp {
            Ok(_) -> {
              let _ =
                discord_gleam.send_message(
                  bot,
                  message.channel_id,
                  "Banned user!",
                  [],
                )

              Nil
            }

            Error(_) -> {
              let _ =
                discord_gleam.send_message(
                  bot,
                  message.channel_id,
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
      logging.log(
        logging.Info,
        "Deleted message: " <> snowflake.to_string(deleted.id),
      )

      let msg = dict.get(booklet.get(bot.cache.messages), deleted.id)

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
          <> list.fold(deleted_bulk.ids, "", fn(acc, id) {
          acc <> snowflake.to_string(id) <> ", "
        }),
      )
    }

    event_handler.InteractionCreatePacket(interaction) -> {
      logging.log(logging.Info, "Interaction: " <> interaction.data.name)

      case interaction.data.name {
        "test" -> {
          let _ = case interaction.data.options {
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
                interaction.send_message(
                  interaction,
                  message.Message(content: "test: " <> value, embeds: []),
                  ephemeral: True,
                )
            }

            None -> {
              let _ =
                interaction.send_message(
                  interaction,
                  message.Message(content: "test: no options", embeds: []),
                  ephemeral: True,
                )
            }
          }

          Nil
        }

        "test2" -> {
          let _ = case interaction.data.options {
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
                interaction.send_message(
                  interaction,
                  message.Message(content: "test2: " <> value, embeds: []),
                  ephemeral: False,
                )
            }

            None -> {
              let _ =
                interaction.send_message(
                  interaction,
                  message.Message(content: "test2: no options", embeds: []),
                  ephemeral: False,
                )
            }
          }

          Nil
        }

        _ -> Nil
      }
    }

    event_handler.PresenceUpdatePacket(presence) -> {
      logging.log(
        logging.Info,
        "Presence updated for: " <> snowflake.to_string(presence.user.id),
      )
    }

    _ -> Nil
  }
}

fn normal_handler(
  bot: bot.Bot,
  state: process.Subject(String),
  name: process.Name(String),
  msg: discord_gleam.HandlerMessage(String),
) {
  case msg {
    discord_gleam.Packet(packet) -> {
      case packet {
        event_handler.ReadyPacket(ready) -> {
          logging.log(
            logging.Info,
            "Logged in as "
              <> ready.user.username
              <> "#"
              <> ready.user.discriminator,
          )

          list.each(ready.guilds, fn(guild) {
            let assert guild.UnavailableGuild(id, ..) = guild

            logging.log(
              logging.Info,
              "Unavailable guild: " <> snowflake.to_string(id),
            )

            discord_gleam.request_guild_members(
              bot: bot,
              guild_id: id,
              option: request_guild_members.Query("", None),
              presences: Some(True),
              nonce: Some("test_request"),
            )
          })

          discord_gleam.continue(state)
        }

        event_handler.MessagePacket(message) -> {
          logging.log(logging.Info, "Got message: " <> message.content)

          case message.content {
            "!ping" -> {
              let _ =
                discord_gleam.send_message(bot, message.channel_id, "Pong!", [])

              discord_gleam.continue(state)
            }

            "!send " <> message -> {
              process.send(state, message)

              discord_gleam.continue(state)
            }

            "!send_to_name " <> message -> {
              process.send(process.named_subject(name), message)

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
