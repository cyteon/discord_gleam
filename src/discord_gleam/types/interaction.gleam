import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/http/interactions
import discord_gleam/internal/error
import discord_gleam/types/component
import discord_gleam/types/message
import discord_gleam/ws/packets/interaction_create
import gleam/json
import gleam/list

pub type InteractionCallbackType {
  Pong
  ChannelMessageWithSource
  DeferredChannelMessageWithSource
  DeferredUpdateMessage
  UpdateMessage
  ApplicationCommandAutocompleteResult
  Modal
}

pub type InteractionCallbackData {
  MessageCallbackData(message.MessageBuilder)
  // todo: autocomplete
  ModalCallbackData(
    custom_id: String,
    title: String,
    components: List(component.Component),
  )
}

pub type InteractionResponse {
  InteractionResponse(
    type_: InteractionCallbackType,
    data: InteractionCallbackData,
  )
}

pub fn callback_type_to_int(type_: InteractionCallbackType) -> Int {
  case type_ {
    Pong -> 1
    ChannelMessageWithSource -> 4
    DeferredChannelMessageWithSource -> 5
    DeferredUpdateMessage -> 6
    UpdateMessage -> 7
    ApplicationCommandAutocompleteResult -> 8
    Modal -> 9
  }
}

pub fn to_string(response: InteractionResponse) -> String {
  let data = case response.data {
    MessageCallbackData(message) -> {
      message.to_json(message)
    }

    ModalCallbackData(custom_id, title, components) -> {
      let components_json =
        json.array(
          list.map(components, fn(component) { component.to_json(component) }),
          of: fn(x) { x },
        )

      json.object([
        #("custom_id", json.string(custom_id)),
        #("title", json.string(title)),
        #("components", components_json),
      ])
    }
  }

  json.object([
    #("type", json.int(callback_type_to_int(response.type_))),
    #("data", data),
  ])
  |> json.to_string()
}

/// Send a message as a response to a slash command interaction. \
/// If ephemral is true, the response will only be shown to the executor.
pub fn send_message(
  interaction: interaction_create.InteractionCreatePacketData,
  message message: message.MessageBuilder,
  ephemeral ephemeral: Bool,
) -> Result(Nil, error.DiscordError) {
  let message = case ephemeral {
    True -> message.ephemeral(message)
    False -> message
  }

  let response =
    InteractionResponse(
      type_: ChannelMessageWithSource,
      data: MessageCallbackData(message),
    )

  interactions.send_response(interaction, to_string(response))
}

/// Send a custom response to a slash command interaction. \
/// You need to construct a response using InteractionResponse yourself.
pub fn custom_response(
  interaction: interaction_create.InteractionCreatePacketData,
  response: InteractionResponse,
) -> Result(Nil, error.DiscordError) {
  interactions.send_response(interaction, to_string(response))
}

/// Used to defer a response to an interaction, will show as the bot is thinking to the user.
pub fn defer_response(
  interaction: interaction_create.InteractionCreatePacketData,
  ephemeral ephemeral: Bool,
) -> Result(Nil, error.DiscordError) {
  let message = case ephemeral {
    True -> message.empty() |> message.ephemeral
    False -> message.empty()
  }

  let response =
    InteractionResponse(
      type_: DeferredChannelMessageWithSource,
      data: MessageCallbackData(message),
    )

  interactions.send_response(interaction, to_string(response))
}

/// Used to edit the original response to an interaction, for example after deferring the response.
pub fn edit_response(
  interaction: interaction_create.InteractionCreatePacketData,
  message message: message.MessageBuilder,
) -> Result(message.Message, error.DiscordError) {
  interactions.edit_original(interaction, message.to_string(message))
}

/// Used to delete the original response to an interaction.
pub fn delete_response(
  interaction: interaction_create.InteractionCreatePacketData,
) -> Result(Nil, error.DiscordError) {
  interactions.delete_original(interaction)
}

/// Used to send a separate followup message to an interaction.
pub fn send_followup(
  interaction: interaction_create.InteractionCreatePacketData,
  message message: message.MessageBuilder,
) -> Result(message.Message, error.DiscordError) {
  interactions.send_followup(interaction, message)
}

/// Used to edit a followup to an interaction.
pub fn edit_followup(
  interaction: interaction_create.InteractionCreatePacketData,
  message_id: Snowflake(snowflake.Message),
  message message: message.MessageBuilder,
) -> Result(message.Message, error.DiscordError) {
  interactions.edit_followup(interaction, message_id, message)
}

/// Used to delete a followup to an interaction.
pub fn delete_followup(
  interaction: interaction_create.InteractionCreatePacketData,
  message_id: Snowflake(snowflake.Message),
) -> Result(Nil, error.DiscordError) {
  interactions.delete_followup(interaction, message_id)
}
