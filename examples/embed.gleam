import discord_gleam
import discord_gleam/bot
import discord_gleam/discord/intents
import discord_gleam/event_handler
import discord_gleam/types/embed
import discord_gleam/types/message
import gleam/erlang/process
import gleam/option.{None}
import gleam/otp/static_supervisor as supervisor
import gleam/otp/supervision
import logging

pub fn main() {
  logging.configure()
  logging.set_level(logging.Info)

  let bot =
    bot.new("TOKEN ID", "CLIENT ID")
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

      case message.content {
        "!embed" -> {
          let embed =
            embed.new(
              title: "Embed Title",
              description: "Embed Description",
              color: 0x00FF00,
            )
            |> embed.set_url("https://example.com")
            |> embed.set_footer(text: "Footer Text", icon_url: None)
            |> embed.add_field(
              name: "Field 1",
              value: "Field Value 1",
              inline: True,
            )

          let _ =
            discord_gleam.send_message(
              bot,
              message.channel_id,
              message.new("Embed!")
                |> message.add_embed(embed),
            )

          Nil
        }
        _ -> Nil
      }
    }
    _ -> Nil
  }
}
