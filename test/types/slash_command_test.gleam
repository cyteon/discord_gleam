import discord_gleam/types/slash_command
import gleam/json

fn option(
  type_: slash_command.CommandOptionType,
  choices: List(slash_command.CommandOptionChoice),
) -> String {
  slash_command.CommandOption(
    name: "opt",
    description: "desc",
    type_:,
    required: True,
    choices:,
  )
  |> slash_command.options_to_string
  |> json.to_string
}

pub fn option_without_choices_omits_key_test() {
  assert option(slash_command.StringOption, [])
    == "{\"name\":\"opt\",\"description\":\"desc\",\"type\":3,\"required\":true}"
}

pub fn string_choices_test() {
  assert option(slash_command.StringOption, [
      slash_command.StringChoice(name: "Web", value: "web"),
    ])
    == "{\"name\":\"opt\",\"description\":\"desc\",\"type\":3,\"required\":true,\"choices\":[{\"name\":\"Web\",\"value\":\"web\"}]}"
}

pub fn int_choices_test() {
  assert option(slash_command.IntOption, [
      slash_command.IntChoice(name: "One", value: 1),
      slash_command.IntChoice(name: "Two", value: 2),
    ])
    == "{\"name\":\"opt\",\"description\":\"desc\",\"type\":4,\"required\":true,\"choices\":[{\"name\":\"One\",\"value\":1},{\"name\":\"Two\",\"value\":2}]}"
}

pub fn float_choices_test() {
  assert option(slash_command.FloatOption, [
      slash_command.FloatChoice(name: "Half", value: 0.5),
    ])
    == "{\"name\":\"opt\",\"description\":\"desc\",\"type\":10,\"required\":true,\"choices\":[{\"name\":\"Half\",\"value\":0.5}]}"
}
