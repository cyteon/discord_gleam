/// Our currently implemented intents, see https://discord.com/developers/docs/events/gateway#gateway-intents \
/// NOTE: We are still to implement all intents, this is a work in progress.
pub type Intents {
  Intents(
    guild_messages: Bool,
    message_content: Bool,
    direct_messages: Bool,
    guilds: Bool,
  )
}

/// Calculate a bitfield from a set of intents.
pub fn intents_to_bitfield(intents: Intents) -> Int {
  let bitfield = 0

  let bitfield = case intents.guild_messages {
    True -> bitfield + 512
    // 1 << 9
    False -> bitfield
  }

  let bitfield = case intents.direct_messages {
    True -> bitfield + 4096
    // 1 << 12
    False -> bitfield
  }

  let bitfield = case intents.message_content {
    True -> bitfield + 32_768
    // 1 << 15
    False -> bitfield
  }

  let bitfield = case intents.guilds {
    True -> bitfield + 1
    // 1 << 0
    False -> bitfield
  }

  bitfield
}

/// Enable a set of default intents, which are usually used by most bots.
pub fn default() -> Intents {
  Intents(
    guild_messages: True,
    message_content: True,
    direct_messages: True,
    guilds: True,
  )
}

/// Enable all the intents, use this if you want to receive all supported events.
pub fn all() -> Intents {
  Intents(
    guild_messages: True,
    message_content: True,
    direct_messages: True,
    guilds: True,
  )
}

/// Disable all the intents, use this if you want to receive no events.
pub fn none() -> Intents {
  Intents(
    guild_messages: False,
    message_content: False,
    direct_messages: False,
    guilds: False,
  )
}
