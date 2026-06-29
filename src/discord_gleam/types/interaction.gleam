import discord_gleam/http/interactions
import discord_gleam/internal/error
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
  InteractionCallbackData(
    tts: Option(Bool),
    content: Option(String),
    embeds: Option(List(embed.Embed)),
    allowed_mentions: Option(String),
    flags: Option(Int),
    // todo: components: list of components
    // todo: attachments: list of attachments
    // todo: poll: poll request object
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
  let data = case response.type_ {
    ChannelMessageWithSource -> {
      let embeds_json = case response.data.embeds {
        Some(embeds) -> {
          let embeds_json_list =
            list.map(embeds, fn(embed) { embed.embed_to_json(embed) })

          json.array(embeds_json_list, of: fn(x) { x })
        }

        None -> json.null()
      }

      json.object([
        #("tts", case response.data.tts {
          Some(tts) -> json.bool(tts)
          None -> json.null()
        }),

        #("content", case response.data.content {
          Some(content) -> json.string(content)
          None -> json.null()
        }),

        #("embeds", embeds_json),

        #("allowed_mentions", case response.data.allowed_mentions {
          Some(allowed_mentions) -> json.string(allowed_mentions)
          None -> json.null()
        }),

        #("flags", case response.data.flags {
          Some(flags) -> json.int(flags)
          None -> json.null()
        }),
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

pub fn send_message(
  interaction: interaction_create.InteractionCreatePacketData,
  message message: message.Message,
  ephemeral ephemeral: Bool,
) -> Result(Nil, error.DiscordError) {
  let response =
    InteractionResponse(
      type_: ChannelMessageWithSource,
      data: InteractionCallbackData(
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

pub fn defer_response(
  interaction: interaction_create.InteractionCreatePacketData,
  ephemeral ephemeral: Bool,
) -> Result(Nil, error.DiscordError) {
  let response =
    InteractionResponse(
      type_: DeferredChannelMessageWithSource,
      data: InteractionCallbackData(
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

pub fn edit_response(
  interaction: interaction_create.InteractionCreatePacketData,
  message message: message.Message,
) -> Result(Nil, error.DiscordError) {
  interactions.edit_original(interaction, message.to_string(message))
}
