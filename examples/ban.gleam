import discord_gleam
import discord_gleam/bot
import discord_gleam/discord/intents
import discord_gleam/discord/snowflake
import discord_gleam/event_handler
import discord_gleam/types/message
import gleam/erlang/process
import gleam/list
import gleam/option.{Some}
import gleam/otp/static_supervisor as supervisor
import gleam/otp/supervision
import gleam/string
import logging

pub fn main() {
  logging.configure()
  logging.set_level(logging.Info)

  let bot =
    bot.new("TOKEN", "CLIENT ID")
    |> bot.with_intents(intents.default_with_message_intent())

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
      logging.log(logging.Info, "Logged in as " <> ready.user.username)

      Nil
    }

    event_handler.MessagePacket(message) -> {
      logging.log(logging.Info, "Message: " <> message.content)

      case string.starts_with(message.content, "!ban "), message.guild_id {
        True, Some(guild_id) -> {
          let args = string.split(message.content, " ")

          let args = list.drop(args, 1)

          let user = case list.first(args) {
            Ok(x) -> x
            Error(_) -> ""
          }

          let args = list.drop(args, 1)

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
                  message.new("Banned user!"),
                )

              Nil
            }

            Error(_) -> {
              let _ =
                discord_gleam.send_message(
                  bot,
                  message.channel_id,
                  message.new("Failed to ban user!"),
                )

              Nil
            }
          }

          Nil
        }

        _, _ -> Nil
      }
    }

    _ -> Nil
  }
}
