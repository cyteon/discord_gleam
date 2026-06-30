import discord_gleam/discord/snowflake.{type Snowflake}
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}

pub type ButtonStyle {
  ButtonPrimary
  ButtonSecondary
  ButtonSuccess
  ButtonDanger
  ButtonLink
  ButtonPremium
}

pub type PartialEmoji {
  PartialEmoji(
    id: Option(Snowflake(snowflake.Emoji)),
    name: Option(String),
    animated: Option(Bool),
  )
}

pub type StringSelectOption {
  StringSelectOption(
    label: String,
    value: String,
    description: Option(String),
    emoji: Option(PartialEmoji),
    default: Option(Bool),
  )
}

pub type TextInputStyle {
  Short
  Paragraph
}

pub type DefaultSelectValue {
  // type: "user", i gotta remember to add that when making json
  DefaultUser(Snowflake(snowflake.User))
  DefaultRole(Snowflake(snowflake.Role))
  DefaultChannel(Snowflake(snowflake.Channel))
}

pub type ChannelType {
  // 0
  GuildText

  // 2
  GuildVoice

  // 4
  GuildCategory

  // 5
  GuildAnnouncement

  // 10
  AnnouncementThread

  // 11
  PublicThread

  // 12
  PrivateThread

  // 13
  GuildStageVoice

  // 14
  GuildDirectory

  // 15
  GuildForum

  // 16
  GuildMedia
}

pub fn channel_type_to_int(type_: ChannelType) -> Int {
  case type_ {
    GuildText -> 0
    GuildVoice -> 2
    GuildCategory -> 4
    GuildAnnouncement -> 5
    AnnouncementThread -> 10
    PublicThread -> 11
    PrivateThread -> 12
    GuildStageVoice -> 13
    GuildDirectory -> 14
    GuildForum -> 15
    GuildMedia -> 16
  }
}

pub type RadioGroupOption {
  RadioGroupOption(
    value: String,
    label: String,
    description: Option(String),
    default: Option(Bool),
  )
}

pub type CheckBoxGroupOption {
  CheckBoxGroupOption(
    value: String,
    label: String,
    description: Option(String),
    default: Option(Bool),
  )
}

pub type Component {
  // 1
  ActionRow(id: Option(Int), components: List(Component))

  // 2
  Button(
    id: Option(Int),
    style: ButtonStyle,
    label: Option(String),
    emoji: Option(PartialEmoji),
    custom_id: Option(String),
    sku_id: Option(Snowflake(snowflake.Sku)),
    url: Option(String),
    disabled: Option(Bool),
  )

  // 3
  StringSelect(
    id: Option(Int),
    custom_id: String,
    options: List(StringSelectOption),
    placeholder: Option(String),
    min_values: Option(Int),
    max_values: Option(Int),
    required: Option(Bool),
    disabled: Option(Bool),
  )

  // 4
  TextInput(
    id: Option(Int),
    custom_id: String,
    style: TextInputStyle,
    min_length: Option(Int),
    max_length: Option(Int),
    required: Option(Bool),
    value: Option(String),
    placeholder: Option(String),
  )

  // 5
  UserSelect(
    id: Option(Int),
    custom_id: String,
    placeholder: Option(String),
    default_values: Option(List(DefaultSelectValue)),
    min_values: Option(Int),
    max_values: Option(Int),
    required: Option(Bool),
    disabled: Option(Bool),
  )

  // 6
  RoleSelect(
    id: Option(Int),
    custom_id: String,
    placeholder: Option(String),
    default_values: Option(List(DefaultSelectValue)),
    min_values: Option(Int),
    max_values: Option(Int),
    required: Option(Bool),
    disabled: Option(Bool),
  )

  // 7
  MentionableSelect(
    id: Option(Int),
    custom_id: String,
    placeholder: Option(String),
    default_values: Option(List(DefaultSelectValue)),
    min_values: Option(Int),
    max_values: Option(Int),
    required: Option(Bool),
    disabled: Option(Bool),
  )

  // 8
  ChannelSelect(
    id: Option(Int),
    custom_id: String,
    channel_types: Option(List(ChannelType)),
    placeholder: Option(String),
    default_values: Option(List(DefaultSelectValue)),
    min_values: Option(Int),
    max_values: Option(Int),
    required: Option(Bool),
    disabled: Option(Bool),
  )

  // 9
  Section(id: Option(Int), components: List(Component), accessory: Component)

  // 10
  TextDisplay(id: Option(Int), content: String)

  // 11
  // todo: Thumbnail
  // 12
  // todo: MediaGallery
  // 13
  // todo: File
  // 14
  Seperator(id: Option(Int), divider: Option(Bool), spacing: Option(Int))

  // 17
  Container(
    id: Option(Int),
    components: List(Component),
    accent_color: Option(Int),
    spoiler: Option(Bool),
  )

  // 18
  Label(
    id: Option(Int),
    label: String,
    description: Option(String),
    component: Component,
  )

  // 19
  FileUpload(
    id: Option(Int),
    custom_id: String,
    min_values: Option(Int),
    max_values: Option(Int),
    required: Option(Bool),
  )

  // 21
  RadioGroup(
    id: Option(Int),
    custom_id: String,
    options: List(RadioGroupOption),
    required: Option(Bool),
  )

  // 22
  CheckboxGroup(
    id: Option(Int),
    custom_id: String,
    options: List(CheckBoxGroupOption),
    min_values: Option(Int),
    max_values: Option(Int),
    required: Option(Bool),
  )

  // 23
  Checkbox(
    value: String,
    label: String,
    description: Option(String),
    default: Option(Bool),
  )
}

pub fn component_type_to_int(component: Component) -> Int {
  case component {
    ActionRow(..) -> 1
    Button(..) -> 2
    StringSelect(..) -> 3
    TextInput(..) -> 4
    UserSelect(..) -> 5
    RoleSelect(..) -> 6
    MentionableSelect(..) -> 7
    ChannelSelect(..) -> 8
    Section(..) -> 9
    TextDisplay(..) -> 10
    Seperator(..) -> 14
    Container(..) -> 17
    Label(..) -> 18
    FileUpload(..) -> 19
    RadioGroup(..) -> 21
    CheckboxGroup(..) -> 22
    Checkbox(..) -> 23
  }
}

pub fn partial_emoji_to_json(emoji: PartialEmoji) -> json.Json {
  json.object([
    #("id", case emoji.id {
      Some(id) -> json.string(snowflake.to_string(id))
      None -> json.null()
    }),

    #("name", case emoji.name {
      Some(name) -> json.string(name)
      None -> json.null()
    }),

    #("animated", case emoji.animated {
      Some(animated) -> json.bool(animated)
      None -> json.null()
    }),
  ])
}

pub fn to_json(component: Component) -> json.Json {
  case component {
    ActionRow(id, components) -> {
      json.object([
        #("type", json.int(1)),
        #("id", case id {
          Some(id) -> json.int(id)
          None -> json.null()
        }),
        #(
          "components",
          json.array(list.map(components, to_json), of: fn(x) { x }),
        ),
      ])
    }

    Button(id, style, label, emoji, custom_id, sku_id, url, disabled) -> {
      json.object([
        #("type", json.int(2)),

        #("id", case id {
          Some(id) -> json.int(id)
          None -> json.null()
        }),

        #(
          "style",
          json.int(case style {
            ButtonPrimary -> 1
            ButtonSecondary -> 2
            ButtonSuccess -> 3
            ButtonDanger -> 4
            ButtonLink -> 5
            ButtonPremium -> 6
          }),
        ),

        #("label", case label {
          Some(label) -> json.string(label)
          None -> json.null()
        }),

        #("emoji", case emoji {
          Some(emoji) -> partial_emoji_to_json(emoji)
          None -> json.null()
        }),

        #("custom_id", case custom_id {
          Some(custom_id) -> json.string(custom_id)
          None -> json.null()
        }),

        #("sku_id", case sku_id {
          Some(sku_id) -> json.string(snowflake.to_string(sku_id))
          None -> json.null()
        }),

        #("url", case url {
          Some(url) -> json.string(url)
          None -> json.null()
        }),

        #("disabled", case disabled {
          Some(disabled) -> json.bool(disabled)
          None -> json.null()
        }),
      ])
    }

    _ -> json.null()
  }
}
