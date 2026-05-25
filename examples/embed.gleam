import discord_gleam
import discord_gleam/discord/intents
import discord_gleam/event_handler
import discord_gleam/types/message
import gleam/erlang/process
import gleam/list
import gleam/otp/static_supervisor as supervisor
import gleam/otp/supervision
import gleam/string
import logging

pub fn main() {
  logging.configure()
  logging.set_level(logging.Info)

  let bot = discord_gleam.bot("token", "client id", intents.default())

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
      case message.d.content {
        "!embed" -> {
          let embed1 =
            message.embed("Embed Title", "Embed Description", 0x00FF00)

          discord_gleam.send_message(bot, message.d.channel_id, "Embed!", [
            embed1,
          ])

          Nil
        }
        _ -> Nil
      }
    }
    _ -> Nil
  }
}
