import example_bot
import gleam/result
import glenvy/dotenv
import glenvy/env

pub fn main() {
  let _ = dotenv.load()

  case
    {
      use token <- result.try(env.get_string("TEST_BOT_TOKEN"))
      use client_id <- result.try(env.get_string("TEST_BOT_CLIENT_ID"))
      use guild_id <- result.try(env.get_string("TEST_BOT_GUILD_ID"))

      Ok(example_bot.main(token, client_id, guild_id))
    }
  {
    Ok(_) -> Nil
    Error(msg) -> {
      echo msg
      Nil
    }
  }
}
