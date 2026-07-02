import discord_gleam
import discord_gleam/bot
import discord_gleam/discord/snowflake
import discord_gleam/event_handler
import discord_gleam/types/interaction
import discord_gleam/types/message
import discord_gleam/types/slash_command
import discord_gleam/ws/packets/interaction_create
import gleam/erlang/process
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/static_supervisor as supervisor
import gleam/otp/supervision
import logging

pub fn main() {
  logging.configure()
  logging.set_level(logging.Info)

  let bot = bot.new("TOKEN", "CLIENT ID")

  let test_cmd =
    slash_command.SlashCommand(
      name: "ping",
      description: "returns pong",
      options: [
        slash_command.CommandOption(
          name: "test",
          description: "string yummy",
          type_: slash_command.StringOption,
          required: False,
        ),
      ],
    )

  let test_cmd2 =
    slash_command.SlashCommand(
      name: "pong",
      description: "returns ping",
      options: [],
    )

  let _ = discord_gleam.register_global_commands(bot, [test_cmd])
  let _ =
    discord_gleam.register_guild_commands(
      bot,
      snowflake.from_string("GUILD ID"),
      [test_cmd2],
    )

  let bot =
    supervision.worker(fn() {
      discord_gleam.simple(bot, [simple_handler])
      |> discord_gleam.start()
    })

  let assert Ok(_) =
    supervisor.new(supervisor.OneForOne)
    |> supervisor.add(bot)
    |> supervisor.start()

  process.sleep_forever()
}

fn simple_handler(_, packet: event_handler.Packet) {
  case packet {
    event_handler.ReadyPacket(ready) -> {
      logging.log(logging.Info, "Logged in as " <> ready.user.username)

      Nil
    }

    event_handler.InteractionCreatePacket(interaction) -> {
      case interaction.data {
        interaction_create.ApplicationCommand(_id, name, _type_, options) -> {
          case name {
            "ping" -> {
              case options {
                Some(options) -> {
                  case list.first(options) {
                    Ok(option) -> {
                      let value = case option.value {
                        interaction_create.StringValue(value) -> value
                        _ -> "unexpected value type"
                      }

                      let _ =
                        interaction.send_message(
                          interaction,
                          message.new("pong: " <> value),
                          ephemeral: False,
                        )

                      Nil
                    }

                    Error(_) -> {
                      let _ =
                        interaction.send_message(
                          interaction,
                          message.new("pong"),
                          ephemeral: False,
                        )

                      Nil
                    }
                  }
                }

                None -> {
                  let _ =
                    interaction.send_message(
                      interaction,
                      message.new("pong"),
                      ephemeral: False,
                    )

                  Nil
                }
              }

              Nil
            }

            "pong" -> {
              let _ =
                interaction.send_message(
                  interaction,
                  message.new("ping"),
                  ephemeral: False,
                )

              Nil
            }
            _ -> Nil
          }
        }

        _ -> Nil
      }
    }
    _ -> Nil
  }
}
