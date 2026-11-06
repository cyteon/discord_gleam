import discord_gleam
import discord_gleam/bot
import discord_gleam/discord/intents
import discord_gleam/discord/snowflake
import discord_gleam/event_handler
import discord_gleam/types/component
import discord_gleam/types/component_response
import discord_gleam/types/interaction
import discord_gleam/types/message
import discord_gleam/types/slash_command
import discord_gleam/ws/commands/update_presence
import discord_gleam/ws/packets/interaction_create
import dot_env
import envoy
import gleam/bool
import gleam/erlang/process
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/static_supervisor as supervisor
import gleam/otp/supervision
import logging

pub fn main() {
  dot_env.load_default()

  let assert Ok(token) = envoy.get("TEST_BOT_TOKEN")
  let assert Ok(client_id) = envoy.get("TEST_BOT_CLIENT_ID")
  let assert Ok(guild_id) = envoy.get("TEST_BOT_GUILD_ID")

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
          choices: [],
        ),
        slash_command.CommandOption(
          name: "int",
          description: "Test option",
          type_: slash_command.IntOption,
          required: False,
          choices: [],
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
          choices: [],
        ),
        slash_command.CommandOption(
          name: "float",
          description: "Test option",
          type_: slash_command.FloatOption,
          required: False,
          choices: [],
        ),
      ],
    )

  let modal_cmd =
    slash_command.SlashCommand(
      name: "modal",
      description: "Test modal command",
      options: [],
    )

  let followups =
    slash_command.SlashCommand(
      name: "followups",
      description: "Test followup command",
      options: [],
    )

  let _ = discord_gleam.wipe_global_commands(bot)
  let _ =
    discord_gleam.register_global_commands(bot, [test_cmd, modal_cmd, followups])

  let _ =
    discord_gleam.wipe_guild_commands(bot, snowflake.from_string(guild_id))
  let _ =
    discord_gleam.register_guild_commands(bot, snowflake.from_string(guild_id), [
      test_cmd2,
    ])

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

    event_handler.InteractionCreatePacket(interaction) -> {
      case interaction.data {
        interaction_create.ApplicationCommand(_id, name, _type_, options) -> {
          case name {
            "test" -> {
              let _ = case options {
                Some(options) -> {
                  let value = case list.first(options) {
                    Ok(option) ->
                      case option.value {
                        interaction_create.StringValue(value) -> value
                        interaction_create.IntValue(value) ->
                          int.to_string(value)
                        interaction_create.BoolValue(value) ->
                          bool.to_string(value)
                        interaction_create.FloatValue(value) ->
                          float.to_string(value)
                      }

                    Error(_) -> "No value"
                  }

                  let _ =
                    interaction.send_message(
                      interaction,
                      message.new("test: " <> value),
                      ephemeral: True,
                    )
                }

                None -> {
                  let _ =
                    interaction.send_message(
                      interaction,
                      message.new("test: no options"),
                      ephemeral: True,
                    )
                }
              }

              Nil
            }

            "test2" -> {
              let _ = case options {
                Some(options) -> {
                  let value = case list.last(options) {
                    Ok(option) ->
                      case option.value {
                        interaction_create.StringValue(value) -> value
                        interaction_create.IntValue(value) ->
                          int.to_string(value)
                        interaction_create.BoolValue(value) ->
                          bool.to_string(value)
                        interaction_create.FloatValue(value) ->
                          float.to_string(value)
                      }

                    Error(_) -> "No value"
                  }

                  let _ =
                    interaction.send_message(
                      interaction,
                      message.new("test2: " <> value),
                      ephemeral: False,
                    )
                }

                None -> {
                  let _ =
                    interaction.defer_response(interaction, ephemeral: True)

                  process.sleep(2000)

                  let _ =
                    interaction.edit_response(
                      interaction,
                      message.new("test2: no options"),
                    )
                }
              }

              Nil
            }

            "modal" -> {
              let modal =
                interaction.ModalCallbackData(
                  custom_id: "test_modal",
                  title: "Modal :O",
                  components: [
                    component.Label(
                      id: None,
                      label: "Do you like potatoes?",
                      description: None,
                      component: component.TextInput(
                        id: None,
                        custom_id: "potato_input",
                        style: component.ShortText,
                        min_length: None,
                        max_length: None,
                        required: Some(True),
                        value: None,
                        placeholder: None,
                      ),
                    ),
                  ],
                )

              let _ =
                interaction.custom_response(
                  interaction,
                  interaction.InteractionResponse(
                    type_: interaction.Modal,
                    data: modal,
                  ),
                )

              Nil
            }

            "followups" -> {
              let _ =
                interaction.send_message(
                  interaction,
                  message.new("First response"),
                  ephemeral: False,
                )

              process.sleep(1000)

              let _ =
                interaction.edit_response(
                  interaction,
                  message.new("Edited response"),
                )

              process.sleep(1000)

              let followup1 =
                interaction.send_followup(
                  interaction,
                  message.new("Followup message"),
                )

              process.sleep(1000)

              let followup2 =
                interaction.send_followup(
                  interaction,
                  message.new("Followup message 2"),
                )

              process.sleep(1000)

              let _ = interaction.delete_response(interaction)

              process.sleep(1000)

              case followup1 {
                Ok(followup1) -> {
                  let _ =
                    interaction.edit_followup(
                      interaction,
                      followup1.id,
                      message.new("Edited followup message"),
                    )

                  Nil
                }

                Error(_) -> Nil
              }

              process.sleep(1000)

              case followup1 {
                Ok(followup1) -> {
                  let _ = interaction.delete_followup(interaction, followup1.id)

                  Nil
                }

                Error(_) -> Nil
              }

              case followup2 {
                Ok(followup2) -> {
                  let _ = interaction.delete_followup(interaction, followup2.id)

                  Nil
                }

                Error(_) -> Nil
              }

              Nil
            }

            _ -> Nil
          }
        }

        interaction_create.MessageComponent(
          custom_id,
          _component_type,
          _values,
          _resolved,
        ) -> {
          logging.log(logging.Info, "Button clicked: " <> custom_id)

          let _ =
            interaction.send_message(
              interaction,
              message.new("Button clicked: " <> custom_id),
              ephemeral: True,
            )

          Nil
        }

        interaction_create.ModalSubmit(custom_id, components, _resolved) -> {
          logging.log(logging.Info, "Modal submitted: " <> custom_id)

          let value = case list.first(components) {
            Ok(component_response.LabelResponse(component_response.TextInputResponse(
              value: value,
              ..,
            ))) -> {
              value
            }

            _ -> "No value"
          }

          let _ =
            interaction.send_message(
              interaction,
              message.new(
                "Modal submitted: " <> custom_id <> ", value: " <> value,
              ),
              ephemeral: True,
            )

          Nil
        }

        _ -> Nil
      }
    }

    _ -> Nil
  }
}
