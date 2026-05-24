import envoy
import example_bot
import gleam/result
import gleam/string
import simplifile

fn load_dotenv() -> Nil {
  case simplifile.read(".env") {
    Ok(contents) ->
      contents
      |> string.split("\n")
      |> list_each(fn(line) {
        let line = string.trim(line)
        case line {
          "" -> Nil
          "#" <> _ -> Nil
          _ ->
            case string.split_once(line, "=") {
              Ok(#(key, value)) -> {
                let value = string.trim(value)
                let value = case string.starts_with(value, "\"") {
                  True ->
                    value
                    |> string.drop_start(1)
                    |> string.drop_end(1)
                  False -> value
                }
                envoy.set(string.trim(key), value)
              }
              Error(_) -> Nil
            }
        }
      })
    Error(_) -> Nil
  }
}

fn list_each(list: List(a), f: fn(a) -> Nil) -> Nil {
  case list {
    [] -> Nil
    [head, ..tail] -> {
      f(head)
      list_each(tail, f)
    }
  }
}

pub fn main() {
  load_dotenv()

  case
    {
      use token <- result.try(
        envoy.get("TEST_BOT_TOKEN")
        |> result.map_error(fn(_) { "TEST_BOT_TOKEN not set" }),
      )
      use client_id <- result.try(
        envoy.get("TEST_BOT_CLIENT_ID")
        |> result.map_error(fn(_) { "TEST_BOT_CLIENT_ID not set" }),
      )
      use guild_id <- result.try(
        envoy.get("TEST_BOT_GUILD_ID")
        |> result.map_error(fn(_) { "TEST_BOT_GUILD_ID not set" }),
      )

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
