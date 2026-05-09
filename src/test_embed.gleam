import discord_gleam/types/message
import gleam/json
import gleam/io
import gleam/option.{None}

pub fn main() {
  let embed =
    message.embed("Test", "Hello!", 0xFF0000)
    |> message.set_image("https://example.com/image.png")
    |> message.set_thumbnail("https://example.com/thumb.png")
    |> message.set_footer("My Bot", None)
    |> message.add_field("Field", "Value", True)

  let json_output = message.embed_to_json(embed)
  let json_string = json.to_string(json_output)
  io.println(json_string)
}
