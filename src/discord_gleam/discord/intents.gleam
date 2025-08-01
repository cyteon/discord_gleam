import gleam/int

/// See https://discord.com/developers/docs/events/gateway#gateway-intents \
/// NOTE: While we have implemented all intents, we have not implemented all gateway events.
pub type Intents {
  Intents(
    guilds: Bool,
    guild_members: Bool,
    guild_moderation: Bool,
    guild_expressions: Bool,
    guild_integrations: Bool,
    guild_webhooks: Bool,
    guild_invites: Bool,
    guild_voice_states: Bool,
    guild_presences: Bool,
    guild_messages: Bool,
    guild_message_reactions: Bool,
    guild_message_typing: Bool,
    direct_messages: Bool,
    direct_message_reactions: Bool,
    direct_message_typing: Bool,
    message_content: Bool,
    guild_scheduled_events: Bool,
    auto_moderation_configuration: Bool,
    auto_moderation_execution: Bool,
    guild_message_polls: Bool,
    direct_message_polls: Bool,
  )
}

fn add_intent_bit(bitfield: Int, intent_enabled: Bool, bit_position: Int) -> Int {
  case intent_enabled {
    False -> bitfield
    True -> int.bitwise_or(bitfield, int.bitwise_shift_left(1, bit_position))
  }
}

/// Calculate a bitfield from a set of intents.
pub fn intents_to_bitfield(intents: Intents) -> Int {
  0
  |> add_intent_bit(intents.guilds, 0)
  |> add_intent_bit(intents.guild_members, 1)
  |> add_intent_bit(intents.guild_moderation, 2)
  |> add_intent_bit(intents.guild_expressions, 3)
  |> add_intent_bit(intents.guild_integrations, 4)
  |> add_intent_bit(intents.guild_webhooks, 5)
  |> add_intent_bit(intents.guild_invites, 6)
  |> add_intent_bit(intents.guild_voice_states, 7)
  |> add_intent_bit(intents.guild_presences, 8)
  |> add_intent_bit(intents.guild_messages, 9)
  |> add_intent_bit(intents.guild_message_reactions, 10)
  |> add_intent_bit(intents.guild_message_typing, 11)
  |> add_intent_bit(intents.direct_messages, 12)
  |> add_intent_bit(intents.direct_message_reactions, 13)
  |> add_intent_bit(intents.direct_message_typing, 14)
  |> add_intent_bit(intents.message_content, 15)
  |> add_intent_bit(intents.guild_scheduled_events, 16)
  |> add_intent_bit(intents.auto_moderation_configuration, 20)
  |> add_intent_bit(intents.auto_moderation_execution, 21)
  |> add_intent_bit(intents.guild_message_polls, 24)
  |> add_intent_bit(intents.direct_message_polls, 25)
}

/// Enable a set of default intents, which are usually used by most bots. \
/// Does not include `message_content` intent, as its a privileged intent
pub fn default() -> Intents {
  Intents(
    guilds: True,
    guild_members: False,
    guild_moderation: False,
    guild_expressions: False,
    guild_integrations: False,
    guild_webhooks: False,
    guild_invites: False,
    guild_voice_states: False,
    guild_presences: False,
    guild_messages: True,
    guild_message_reactions: True,
    guild_message_typing: False,
    direct_messages: True,
    direct_message_reactions: True,
    direct_message_typing: False,
    message_content: True,
    guild_scheduled_events: False,
    auto_moderation_configuration: False,
    auto_moderation_execution: False,
    guild_message_polls: False,
    direct_message_polls: False,
  )
}

/// Enable a set of default intents, which are usually used by most bots. \
/// But also includes all intents relevant to messages
pub fn default_with_message_intents() -> Intents {
  Intents(
    guilds: True,
    guild_members: False,
    guild_moderation: False,
    guild_expressions: False,
    guild_integrations: False,
    guild_webhooks: False,
    guild_invites: False,
    guild_voice_states: False,
    guild_presences: False,
    guild_messages: True,
    guild_message_reactions: True,
    guild_message_typing: True,
    direct_messages: True,
    direct_message_reactions: True,
    direct_message_typing: True,
    message_content: True,
    guild_scheduled_events: False,
    auto_moderation_configuration: False,
    auto_moderation_execution: False,
    guild_message_polls: True,
    direct_message_polls: True,
  )
}

/// Enable all the intents, use this if you want to receive all supported events.
pub fn all() -> Intents {
  Intents(
    guilds: True,
    guild_members: True,
    guild_moderation: True,
    guild_expressions: True,
    guild_integrations: True,
    guild_webhooks: True,
    guild_invites: True,
    guild_voice_states: True,
    guild_presences: True,
    guild_messages: True,
    guild_message_reactions: True,
    guild_message_typing: True,
    direct_messages: True,
    direct_message_reactions: True,
    direct_message_typing: True,
    message_content: True,
    guild_scheduled_events: True,
    auto_moderation_configuration: True,
    auto_moderation_execution: True,
    guild_message_polls: True,
    direct_message_polls: True,
  )
}

/// Disable all the intents, use this if you want to receive no events other than `interaction_create or ready. \ 
/// Useful if you have a bot with slash commands only, that dosen't need to listen to events.
pub fn none() -> Intents {
  Intents(
    guilds: False,
    guild_members: False,
    guild_moderation: False,
    guild_expressions: False,
    guild_integrations: False,
    guild_webhooks: False,
    guild_invites: False,
    guild_voice_states: False,
    guild_presences: False,
    guild_messages: False,
    guild_message_reactions: False,
    guild_message_typing: False,
    direct_messages: False,
    direct_message_reactions: False,
    direct_message_typing: False,
    message_content: False,
    guild_scheduled_events: False,
    auto_moderation_configuration: False,
    auto_moderation_execution: False,
    guild_message_polls: False,
    direct_message_polls: False,
  )
}
