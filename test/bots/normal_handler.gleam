import discord_gleam
import discord_gleam/bot
import discord_gleam/discord/intents
import discord_gleam/discord/snowflake
import discord_gleam/event_handler
import discord_gleam/types/guild
import discord_gleam/types/message
import discord_gleam/ws/commands/request_guild_members
import dot_env
import envoy
import gleam/erlang/process
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/static_supervisor as supervisor
import gleam/otp/supervision
import logging

pub fn main() {
  dot_env.load_default()

  let assert Ok(token) = envoy.get("TEST_BOT_TOKEN")
  let assert Ok(client_id) = envoy.get("TEST_BOT_CLIENT_ID")

  logging.configure()
  logging.set_level(logging.Debug)

  let bot =
    bot.new(token, client_id)
    |> bot.with_intents(intents.default_with_message_intent())

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

  process.sleep_forever()
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
                discord_gleam.send_message(
                  bot,
                  message.channel_id,
                  message.new("Pong!"),
                )

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
