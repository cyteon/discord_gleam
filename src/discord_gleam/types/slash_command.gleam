import gleam/json
import gleam/list

/// An simplified command option type \
/// See https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-structure
pub type CommandOption {
  CommandOption(
    name: String,
    description: String,
    type_: CommandOptionType,
    required: Bool,
    choices: List(#(String, String)),
  )
}

pub type CommandOptionType {
  SubCommandOption
  SubCommandGroupOption
  StringOption
  IntOption
  BoolOption
  UserOption
  ChannelOption
  RoleOption
  MentionableOption
  FloatOption
  AttachmentOption
}

pub type SlashCommand {
  SlashCommand(name: String, description: String, options: List(CommandOption))
}

pub fn type_to_int(type_: CommandOptionType) -> Int {
  case type_ {
    SubCommandOption -> 1
    SubCommandGroupOption -> 2
    StringOption -> 3
    IntOption -> 4
    BoolOption -> 5
    UserOption -> 6
    ChannelOption -> 7
    RoleOption -> 8
    MentionableOption -> 9
    FloatOption -> 10
    AttachmentOption -> 11
  }
}

pub fn command_to_json(raw: SlashCommand) -> json.Json {
  let options = list.map(raw.options, options_to_string)

  json.object([
    #("name", json.string(raw.name)),
    #("type", json.int(1)),
    #("description", json.string(raw.description)),
    #("options", json.array(options, of: fn(x) { x })),
  ])
}

pub fn command_to_string(raw: SlashCommand) -> String {
  command_to_json(raw) |> json.to_string
}

/// Serializes a full command list as a JSON array, for the bulk overwrite
/// endpoint (a single PUT registering/replacing every command at once).
pub fn commands_to_string(commands: List(SlashCommand)) -> String {
  json.array(commands, of: command_to_json) |> json.to_string
}

pub fn options_to_string(option: CommandOption) -> json.Json {
  let base = [
    #("name", json.string(option.name)),
    #("description", json.string(option.description)),
    #("type", json.int(type_to_int(option.type_))),
    #("required", json.bool(option.required)),
  ]

  case option.choices {
    [] -> json.object(base)
    choices ->
      json.object(
        list.append(base, [
          #(
            "choices",
            json.array(choices, of: fn(choice) {
              json.object([
                #("name", json.string(choice.0)),
                #("value", json.string(choice.1)),
              ])
            }),
          ),
        ]),
      )
  }
}
