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

/// Calculate a bitfield from a set of intents.
pub fn intents_to_bitfield(intents: Intents) -> Int {
  let bitfield = 0

  let bitfield = case intents.guilds {
    // 1 << 0
    True -> bitfield + 1
    False -> bitfield
  }

  let bitfield = case intents.guild_members {
    // 1 << 1
    True -> bitfield + 2
    False -> bitfield
  }

  let bitfield = case intents.guild_moderation {
    // 1 << 2
    True -> bitfield + 4
    False -> bitfield
  }

  let bitfield = case intents.guild_expressions {
    // 1 << 3
    True -> bitfield + 8
    False -> bitfield
  }

  let bitfield = case intents.guild_integrations {
    // 1 << 4
    True -> bitfield + 16
    False -> bitfield
  }

  let bitfield = case intents.guild_webhooks {
    // 1 << 5
    True -> bitfield + 32
    False -> bitfield
  }

  let bitfield = case intents.guild_invites {
    // 1 << 6
    True -> bitfield + 64
    False -> bitfield
  }

  let bitfield = case intents.guild_voice_states {
    // 1 << 7
    True -> bitfield + 128
    False -> bitfield
  }

  let bitfield = case intents.guild_presences {
    // 1 << 8
    True -> bitfield + 256
    False -> bitfield
  }

  let bitfield = case intents.guild_messages {
    // 1 << 9
    True -> bitfield + 512
    False -> bitfield
  }

  let bitfield = case intents.guild_message_reactions {
    // 1 << 10
    True -> bitfield + 1024
    False -> bitfield
  }

  let bitfield = case intents.guild_message_typing {
    // 1 << 11
    True -> bitfield + 2048
    False -> bitfield
  }

  let bitfield = case intents.direct_messages {
    // 1 << 12
    True -> bitfield + 4096
    False -> bitfield
  }

  let bitfield = case intents.direct_message_reactions {
    // 1 << 13
    True -> bitfield + 8192
    False -> bitfield
  }

  let bitfield = case intents.direct_message_typing {
    // 1 << 14
    True -> bitfield + 16_384
    False -> bitfield
  }

  let bitfield = case intents.message_content {
    // 1 << 15
    True -> bitfield + 32_768
    False -> bitfield
  }

  let bitfield = case intents.guild_scheduled_events {
    // 1 << 16
    True -> bitfield + 65_536
    False -> bitfield
  }

  let bitfield = case intents.auto_moderation_configuration {
    // 1 << 20
    True -> bitfield + 1_048_576
    False -> bitfield
  }

  let bitfield = case intents.auto_moderation_execution {
    // 1 << 21
    True -> bitfield + 2_097_152
    False -> bitfield
  }

  let bitfield = case intents.guild_message_polls {
    // 1 << 24
    True -> bitfield + 16_777_216
    False -> bitfield
  }

  let bitfield = case intents.direct_message_polls {
    // 1 << 25
    True -> bitfield + 33_554_432
    False -> bitfield
  }

  bitfield
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
