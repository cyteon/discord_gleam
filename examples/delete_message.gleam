import discord_gleam
import discord_gleam/bot
import discord_gleam/discord/intents
import discord_gleam/event_handler
import gleam/erlang/process
import gleam/list
import gleam/otp/static_supervisor as supervisor
import gleam/otp/supervision
import gleam/string
import logging

pub fn main() {
  logging.configure()
  logging.set_level(logging.Debug)

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
      logging.log(logging.Info, "Logged in as " <> ready.d.user.username)

      Nil
    }
    event_handler.MessagePacket(message) -> {
      logging.log(logging.Info, "Message: " <> message.d.content)

      case string.starts_with(message.d.content, "!delete") {
        True -> {
          let args = string.split(message.d.content, " ")
          let args = list.drop(args, 1)

          let reason = string.join(args, " ")

          let _ =
            discord_gleam.delete_message(
              bot,
              message.d.channel_id,
              message.d.id,
              reason,
            )

          Nil
        }
        False -> Nil
      }
    }
    _ -> Nil
  }
}
