import discord_gleam
import discord_gleam/discord/intents
import discord_gleam/event_handler
import discord_gleam/types/slash_command
import discord_gleam/ws/packets/interaction_create
import gleam/erlang/process
import gleam/otp/static_supervisor as supervisor
import gleam/otp/supervision
import gleam/list
import gleam/option
import logging

pub fn main() {
  logging.configure()
  logging.set_level(logging.Info)

  let bot = discord_gleam.bot("TOKEN", "CLIENT_ID", intents.default())

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

  discord_gleam.register_global_commands(bot, [test_cmd])

  discord_gleam.register_guild_commands(bot, "GUILD_ID", [test_cmd2])

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

fn simple_handler(bot, packet: event_handler.Packet) {
  case packet {
    event_handler.ReadyPacket(ready) -> {
      logging.log(logging.Info, "Logged in as " <> ready.d.user.username)

      Nil
    }

    event_handler.InteractionCreate(interaction) -> {
      logging.log(logging.Info, "Interaction: " <> interaction.d.data.name)

      case interaction.d.data.name {
        "ping" -> {
          case interaction.d.data.options {
            option.Some(options) -> {
              case list.first(options) {
                Ok(option) -> {
                  let value = case option.value {
                    interaction_create.StringValue(value) -> value
                    _ -> "unexpected value type"
                  }

                  discord_gleam.interaction_reply_message(
                    interaction,
                    "pong: " <> value,
                    False,
                  )
                }

                Error(_) ->
                  discord_gleam.interaction_reply_message(
                    interaction,
                    "pong",
                    False,
                  )
              }
            }

            option.None ->
              discord_gleam.interaction_reply_message(
                interaction,
                "pong",
                False,
              )
          }

          Nil
        }

        "pong" -> {
          discord_gleam.interaction_reply_message(interaction, "ping", False)

          Nil
        }
        _ -> Nil
      }
    }
    _ -> Nil
  }
}
