import discord_gleam/http/interactions
import discord_gleam/internal/error
import discord_gleam/types/component
import discord_gleam/types/embed
import discord_gleam/types/message
import discord_gleam/ws/packets/interaction_create
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}

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
  MessageCallbackData(
    tts: Option(Bool),
    content: Option(String),
    embeds: Option(List(embed.Embed)),
    allowed_mentions: Option(List(String)),
    flags: Option(Int),
    // todo: components: list of components
    // todo: attachments: list of attachments
    // todo: poll: poll request object
  )
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
    MessageCallbackData(tts, content, embeds, allowed_mentions, flags) -> {
      {
        let embeds_json = case embeds {
          Some(embeds) -> {
            let embeds_json_list =
              list.map(embeds, fn(embed) { embed.embed_to_json(embed) })

            json.array(embeds_json_list, of: fn(x) { x })
          }

          None -> json.null()
        }

        json.object([
          #("tts", case tts {
            Some(tts) -> json.bool(tts)
            None -> json.null()
          }),

          #("content", case content {
            Some(content) -> json.string(content)
            None -> json.null()
          }),

          #("embeds", embeds_json),

          #("allowed_mentions", case allowed_mentions {
            Some(allowed_mentions) ->
              json.array(
                list.map(allowed_mentions, fn(x) { json.string(x) }),
                of: fn(x) { x },
              )
            None -> json.null()
          }),

          #("flags", case flags {
            Some(flags) -> json.int(flags)
            None -> json.null()
          }),
        ])
      }
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

    _ -> json.null()
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
  message message: message.Message,
  ephemeral ephemeral: Bool,
) -> Result(Nil, error.DiscordError) {
  let response =
    InteractionResponse(
      type_: ChannelMessageWithSource,
      data: MessageCallbackData(
        tts: None,
        content: Some(message.content),
        embeds: Some(message.embeds),
        allowed_mentions: None,
        flags: case ephemeral {
          True -> Some(64)
          False -> None
        },
      ),
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

/// Used to defer a response to a interaction, will show as the bot is thinking to the user.
pub fn defer_response(
  interaction: interaction_create.InteractionCreatePacketData,
  ephemeral ephemeral: Bool,
) -> Result(Nil, error.DiscordError) {
  let response =
    InteractionResponse(
      type_: DeferredChannelMessageWithSource,
      data: MessageCallbackData(
        tts: None,
        content: None,
        embeds: None,
        allowed_mentions: None,
        flags: case ephemeral {
          True -> Some(64)
          False -> None
        },
      ),
    )

  interactions.send_response(interaction, to_string(response))
}

/// Used to edit the original response to a interaction, for example after deferring the response.
pub fn edit_response(
  interaction: interaction_create.InteractionCreatePacketData,
  message message: message.Message,
) -> Result(Nil, error.DiscordError) {
  interactions.edit_original(interaction, message.to_string(message))
}
