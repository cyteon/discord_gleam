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
  ShortText
  ParagraphText
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
  Checkbox(id: Option(Int), custom_id: String, default: Option(Bool))
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

pub fn default_select_value_to_json(value: DefaultSelectValue) -> json.Json {
  case value {
    DefaultUser(id) ->
      json.object([
        #("type", json.string("user")),
        #("id", json.string(snowflake.to_string(id))),
      ])

    DefaultRole(id) ->
      json.object([
        #("type", json.string("role")),
        #("id", json.string(snowflake.to_string(id))),
      ])

    DefaultChannel(id) ->
      json.object([
        #("type", json.string("channel")),
        #("id", json.string(snowflake.to_string(id))),
      ])
  }
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

    StringSelect(
      id,
      custom_id,
      options,
      placeholder,
      min_values,
      max_values,
      required,
      disabled,
    ) -> {
      json.object([
        #("type", json.int(3)),

        #("id", case id {
          Some(id) -> json.int(id)
          None -> json.null()
        }),

        #("custom_id", json.string(custom_id)),

        #(
          "options",
          json.array(
            list.map(options, fn(option) {
              json.object([
                #("label", json.string(option.label)),
                #("value", json.string(option.value)),
                #("description", case option.description {
                  Some(description) -> json.string(description)
                  None -> json.null()
                }),
                #("emoji", case option.emoji {
                  Some(emoji) -> partial_emoji_to_json(emoji)
                  None -> json.null()
                }),
                #("default", case option.default {
                  Some(default) -> json.bool(default)
                  None -> json.null()
                }),
              ])
            }),
            of: fn(x) { x },
          ),
        ),

        #("placeholder", case placeholder {
          Some(placeholder) -> json.string(placeholder)
          None -> json.null()
        }),

        #("min_values", case min_values {
          Some(min_values) -> json.int(min_values)
          None -> json.null()
        }),

        #("max_values", case max_values {
          Some(max_values) -> json.int(max_values)
          None -> json.null()
        }),

        #("required", case required {
          Some(required) -> json.bool(required)
          None -> json.null()
        }),

        #("disabled", case disabled {
          Some(disabled) -> json.bool(disabled)
          None -> json.null()
        }),
      ])
    }

    TextInput(
      id,
      custom_id,
      style,
      min_length,
      max_length,
      required,
      value,
      placeholder,
    ) -> {
      json.object([
        #("type", json.int(4)),

        #("id", case id {
          Some(id) -> json.int(id)
          None -> json.null()
        }),

        #("custom_id", json.string(custom_id)),

        #(
          "style",
          json.int(case style {
            ShortText -> 1
            ParagraphText -> 2
          }),
        ),

        #("min_length", case min_length {
          Some(min_length) -> json.int(min_length)
          None -> json.null()
        }),

        #("max_length", case max_length {
          Some(max_length) -> json.int(max_length)
          None -> json.null()
        }),

        #("required", case required {
          Some(required) -> json.bool(required)
          None -> json.null()
        }),

        #("value", case value {
          Some(value) -> json.string(value)
          None -> json.null()
        }),

        #("placeholder", case placeholder {
          Some(placeholder) -> json.string(placeholder)
          None -> json.null()
        }),
      ])
    }

    UserSelect(
      id,
      custom_id,
      placeholder,
      default_values,
      min_values,
      max_values,
      required,
      disabled,
    ) -> {
      json.object([
        #("type", json.int(5)),

        #("id", case id {
          Some(id) -> json.int(id)
          None -> json.null()
        }),

        #("custom_id", json.string(custom_id)),

        #("placeholder", case placeholder {
          Some(placeholder) -> json.string(placeholder)
          None -> json.null()
        }),

        #("default_values", case default_values {
          Some(default_values) ->
            json.array(
              list.map(default_values, default_select_value_to_json),
              of: fn(x) { x },
            )

          None -> json.null()
        }),

        #("min_values", case min_values {
          Some(min_values) -> json.int(min_values)
          None -> json.null()
        }),

        #("max_values", case max_values {
          Some(max_values) -> json.int(max_values)
          None -> json.null()
        }),

        #("required", case required {
          Some(required) -> json.bool(required)
          None -> json.null()
        }),

        #("disabled", case disabled {
          Some(disabled) -> json.bool(disabled)
          None -> json.null()
        }),
      ])
    }

    RoleSelect(
      id,
      custom_id,
      placeholder,
      default_values,
      min_values,
      max_values,
      required,
      disabled,
    ) -> {
      json.object([
        #("type", json.int(6)),

        #("id", case id {
          Some(id) -> json.int(id)
          None -> json.null()
        }),

        #("custom_id", json.string(custom_id)),

        #("placeholder", case placeholder {
          Some(placeholder) -> json.string(placeholder)
          None -> json.null()
        }),

        #("default_values", case default_values {
          Some(default_values) ->
            json.array(
              list.map(default_values, default_select_value_to_json),
              of: fn(x) { x },
            )

          None -> json.null()
        }),

        #("min_values", case min_values {
          Some(min_values) -> json.int(min_values)
          None -> json.null()
        }),

        #("max_values", case max_values {
          Some(max_values) -> json.int(max_values)
          None -> json.null()
        }),

        #("required", case required {
          Some(required) -> json.bool(required)
          None -> json.null()
        }),

        #("disabled", case disabled {
          Some(disabled) -> json.bool(disabled)
          None -> json.null()
        }),
      ])
    }

    MentionableSelect(
      id,
      custom_id,
      placeholder,
      default_values,
      min_values,
      max_values,
      required,
      disabled,
    ) -> {
      json.object([
        #("type", json.int(7)),

        #("id", case id {
          Some(id) -> json.int(id)
          None -> json.null()
        }),

        #("custom_id", json.string(custom_id)),

        #("placeholder", case placeholder {
          Some(placeholder) -> json.string(placeholder)
          None -> json.null()
        }),

        #("default_values", case default_values {
          Some(default_values) ->
            json.array(
              list.map(default_values, default_select_value_to_json),
              of: fn(x) { x },
            )

          None -> json.null()
        }),

        #("min_values", case min_values {
          Some(min_values) -> json.int(min_values)
          None -> json.null()
        }),

        #("max_values", case max_values {
          Some(max_values) -> json.int(max_values)
          None -> json.null()
        }),

        #("required", case required {
          Some(required) -> json.bool(required)
          None -> json.null()
        }),

        #("disabled", case disabled {
          Some(disabled) -> json.bool(disabled)
          None -> json.null()
        }),
      ])
    }

    ChannelSelect(
      id,
      custom_id,
      channel_types,
      placeholder,
      default_values,
      min_values,
      max_values,
      required,
      disabled,
    ) -> {
      json.object([
        #("type", json.int(8)),

        #("id", case id {
          Some(id) -> json.int(id)
          None -> json.null()
        }),

        #("custom_id", json.string(custom_id)),

        #("channel_types", case channel_types {
          Some(channel_types) ->
            json.array(list.map(channel_types, channel_type_to_int), of: fn(x) {
              json.int(x)
            })

          None -> json.null()
        }),

        #("placeholder", case placeholder {
          Some(placeholder) -> json.string(placeholder)
          None -> json.null()
        }),

        #("default_values", case default_values {
          Some(default_values) ->
            json.array(
              list.map(default_values, default_select_value_to_json),
              of: fn(x) { x },
            )

          None -> json.null()
        }),

        #("min_values", case min_values {
          Some(min_values) -> json.int(min_values)
          None -> json.null()
        }),

        #("max_values", case max_values {
          Some(max_values) -> json.int(max_values)
          None -> json.null()
        }),

        #("required", case required {
          Some(required) -> json.bool(required)
          None -> json.null()
        }),

        #("disabled", case disabled {
          Some(disabled) -> json.bool(disabled)
          None -> json.null()
        }),
      ])
    }

    Section(id, components, accessory) -> {
      json.object([
        #("type", json.int(9)),

        #("id", case id {
          Some(id) -> json.int(id)
          None -> json.null()
        }),

        #(
          "components",
          json.array(list.map(components, to_json), of: fn(x) { x }),
        ),

        #("accessory", to_json(accessory)),
      ])
    }

    TextDisplay(id, content) -> {
      json.object([
        #("type", json.int(10)),

        #("id", case id {
          Some(id) -> json.int(id)
          None -> json.null()
        }),

        #("content", json.string(content)),
      ])
    }

    // todo Thumbnail, MediaGallery, File
    Seperator(id, divider, spacing) -> {
      json.object([
        #("type", json.int(14)),

        #("id", case id {
          Some(id) -> json.int(id)
          None -> json.null()
        }),

        #("divider", case divider {
          Some(divider) -> json.bool(divider)
          None -> json.null()
        }),

        #("spacing", case spacing {
          Some(spacing) -> json.int(spacing)
          None -> json.null()
        }),
      ])
    }

    Container(id, components, accent_color, spoiler) -> {
      json.object([
        #("type", json.int(17)),

        #("id", case id {
          Some(id) -> json.int(id)
          None -> json.null()
        }),

        #(
          "components",
          json.array(list.map(components, to_json), of: fn(x) { x }),
        ),

        #("accent_color", case accent_color {
          Some(accent_color) -> json.int(accent_color)
          None -> json.null()
        }),

        #("spoiler", case spoiler {
          Some(spoiler) -> json.bool(spoiler)
          None -> json.null()
        }),
      ])
    }

    Label(id, label, description, component) -> {
      json.object([
        #("type", json.int(18)),

        #("id", case id {
          Some(id) -> json.int(id)
          None -> json.null()
        }),

        #("label", json.string(label)),

        #("description", case description {
          Some(description) -> json.string(description)
          None -> json.null()
        }),

        #("component", to_json(component)),
      ])
    }

    FileUpload(id, custom_id, min_values, max_values, required) -> {
      json.object([
        #("type", json.int(19)),

        #("id", case id {
          Some(id) -> json.int(id)
          None -> json.null()
        }),

        #("custom_id", json.string(custom_id)),

        #("min_values", case min_values {
          Some(min_values) -> json.int(min_values)
          None -> json.null()
        }),

        #("max_values", case max_values {
          Some(max_values) -> json.int(max_values)
          None -> json.null()
        }),

        #("required", case required {
          Some(required) -> json.bool(required)
          None -> json.null()
        }),
      ])
    }

    RadioGroup(id, custom_id, options, required) -> {
      json.object([
        #("type", json.int(21)),

        #("id", case id {
          Some(id) -> json.int(id)
          None -> json.null()
        }),

        #("custom_id", json.string(custom_id)),

        #(
          "options",
          json.array(
            list.map(options, fn(option) {
              json.object([
                #("value", json.string(option.value)),

                #("label", json.string(option.label)),

                #("description", case option.description {
                  Some(description) -> json.string(description)
                  None -> json.null()
                }),

                #("default", case option.default {
                  Some(default) -> json.bool(default)
                  None -> json.null()
                }),
              ])
            }),
            of: fn(x) { x },
          ),
        ),

        #("required", case required {
          Some(required) -> json.bool(required)
          None -> json.null()
        }),
      ])
    }

    CheckboxGroup(id, custom_id, options, min_values, max_values, required) -> {
      json.object([
        #("type", json.int(22)),

        #("id", case id {
          Some(id) -> json.int(id)
          None -> json.null()
        }),

        #("custom_id", json.string(custom_id)),

        #(
          "options",
          json.array(
            list.map(options, fn(options) {
              json.object([
                #("value", json.string(options.value)),

                #("label", json.string(options.label)),

                #("description", case options.description {
                  Some(description) -> json.string(description)
                  None -> json.null()
                }),

                #("default", case options.default {
                  Some(default) -> json.bool(default)
                  None -> json.null()
                }),
              ])
            }),
            of: fn(x) { x },
          ),
        ),

        #("min_values", case min_values {
          Some(min_values) -> json.int(min_values)
          None -> json.null()
        }),

        #("max_values", case max_values {
          Some(max_values) -> json.int(max_values)
          None -> json.null()
        }),

        #("required", case required {
          Some(required) -> json.bool(required)
          None -> json.null()
        }),
      ])
    }

    Checkbox(id, custom_id, default) -> {
      json.object([
        #("type", json.int(23)),

        #("id", case id {
          Some(id) -> json.int(id)
          None -> json.null()
        }),

        #("custom_id", json.string(custom_id)),

        #("default", case default {
          Some(default) -> json.bool(default)
          None -> json.null()
        }),
      ])
    }
  }
}
