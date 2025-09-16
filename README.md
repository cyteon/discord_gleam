# discord_gleam

[![Package Version](https://img.shields.io/hexpm/v/discord_gleam)](https://hex.pm/packages/discord_gleam)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/discord_gleam/)

```sh
gleam add discord_gleam
```

```gleam
import discord_gleam
import discord_gleam/event_handler
import discord_gleam/types/message
import discord_gleam/discord/intents
import gleam/list
import gleam/string
import logging

pub fn main() {
  logging.configure()
  logging.set_level(logging.Info)

  let bot = discord_gleam.bot("YOUR TOKEN", "YOUR CLIENT ID", intents.default())

  discord_gleam.run(bot, [event_handler])
}

fn event_handler(bot, packet: event_handler.Packet) {
  case packet {
    event_handler.MessagePacket(message) -> {
      logging.log(logging.Info, "Got message: " <> message.d.content)

      case message.d.content {
        "!ping" -> {
          discord_gleam.send_message(bot, message.d.channel_id, "Pong!", [])

          Nil
        }

        _ -> Nil
      }
    }
    
    _ -> Nil
  }
}
```

Further documentation can be found at <https://hexdocs.pm/discord_gleam>.

## Custom Handlers

discord_gleam now supports custom loop and close handlers, allowing you to override the default Discord WebSocket message processing and connection close behavior with your own custom logic.

### Basic Usage

```gleam
import discord_gleam
import discord_gleam/custom_handlers
import discord_gleam/discord/intents
import discord_gleam/ws/event_loop
import gleam/option
import stratus

pub fn main() {
  let bot = discord_gleam.bot("TOKEN", "CLIENT_ID", intents.default())
  
  let custom_handlers = custom_handlers.CustomHandlers(
    loop: my_custom_loop,
    close: my_custom_close
  )
  
  discord_gleam.run_with_custom_handlers(
    bot, 
    [event_handler], 
    option.Some(custom_handlers)
  )
}

fn my_custom_loop(state: event_loop.State, msg: stratus.Message, conn: stratus.Connection) {
  // Your custom message handling logic here
  case msg {
    stratus.Text(text) -> {
      // Log all text messages
      io.println("Received: " <> text)
      stratus.continue(state)
    }
    _ -> stratus.continue(state)
  }
}

fn my_custom_close(state: event_loop.State) {
  // Your custom close handling logic here
  io.println("Connection closed!")
  Nil
}
```

### Helper Functions

The `custom_handlers` module provides helper functions for common use cases:

- `default_continue_loop_handler()` - A simple pass-through loop handler
- `default_noop_close_handler()` - A no-op close handler

### Fallback to Default Behavior

You can use `option.None` with `run_with_custom_handlers` to fall back to the default Discord protocol handling:

```gleam
discord_gleam.run_with_custom_handlers(bot, [event_handler], option.None)
// This is equivalent to: discord_gleam.run(bot, [event_handler])
```

### Examples

See the `examples/` directory for complete examples:
- `examples/custom_handlers.gleam` - Basic custom handler example
- `examples/enhanced_custom_handlers.gleam` - Advanced example with message monitoring

## Development

```sh
gleam test  # Run the tests
```

## Features:

| Feature               | Status  |
| --------------------- | ------  |
| Basic events          | ✅      |
| Sending messages      | ✅      |
| Ban/kick              | ✅      |
| Deleting messages     | ✅      |
| Embeds                | ✅      |
| Basic Slash commands  | ✅      |
| Message Cache         | ✅      |
| Intents               | ✅*     |
| Custom Handlers       | ✅      |

✅ - Done | 🔨 - In Progress | 📆 - Planned | ❌ - Not Planned \
\* all intents are implemented, but not all are used yet

## Supported events:

- [x] READY
- [x] INTERACTION_CREATE

Intent: guild_messages/direct_messages (optional: message_content)
- [x] MESSAGE_CREATE
- [x] MESSAGE_DELETE
- [x] MESSAGE_UPDATE
- [x] MESSAGE_DELETE_BULK

Intent: guilds
- [ ] GUILD_CREATE
- [ ] GUILD_UPDATE
- [ ] GUILD_DELETE
- [x] CHANNEL_CREATE
- [x] CHANNEL_UPDATE
- [x] CHANNEL_DELETE
- [ ] CHANNEL_PINS_UPDATE
- [ ] THREAD_CREATE
- [ ] THREAD_UPDATE
- [ ] THREAD_DELETE
- [ ] THREAD_LIST_SYNC
- [ ] THREAD_MEMBER_UPDATE
- [ ] THREAD_MEMBERS_UPDATE
- [ ] STAGE_INSTANCE_CREATE
- [ ] STAGE_INSTANCE_UPDATE
- [ ] STAGE_INSTANCE_DELETE
- [x] GUILD_ROLE_CREATE
- [x] GUILD_ROLE_UPDATE
- [x] GUILD_ROLE_DELETE

Intent: guild_members
- [ ] GUILD_MEMBER_ADD
- [ ] GUILD_MEMBER_UPDATE
- [x] GUILD_MEMBER_REMOVE
- [ ] GUILD_MEMBERS_CHUNK
- [ ] THREAD_MEMBERS_UPDATE

Intent: guild_moderation
- [ ] GUILD_AUDIT_LOG_ENTRY_CREATE
- [x] GUILD_BAN_ADD
- [x] GUILD_BAN_REMOVE

Intent: guild_expressions
- [ ] GUILD_EMOJIS_UPDATE
- [ ] GUILD_STICKERS_UPDATE
- [ ] GUILD_SOUNDBOARD_SOUND_CREATE
- [ ] GUILD_SOUNDBOARD_SOUND_UPDATE
- [ ] GUILD_SOUNDBOARD_SOUND_DELETE
- [ ] GUILD_SOUNDBOARD_SOUNDS_UPDATE

Intent: guild_integrations
- [ ] GUILD_INTEGRATIONS_UPDATE
- [ ] INTEGRATION_CREATE
- [ ] INTEGRATION_UPDATE
- [ ] INTEGRATION_DELETE

Intent: guild_webhooks
- [ ] WEBHOOKS_UPDATE

Intent: guild_invites
- [ ] INVITE_CREATE
- [ ] INVITE_DELETE

Intent: guild_voice_states
- [ ] VOICE_CHANNEL_EFFECT_SEND
- [ ] VOICE_STATE_UPDATE

Intent: guild_presences
- [ ] PRESENCE_UPDATE

Intent: guild_message_reactions/direct_message_reactions
- [ ] MESSAGE_REACTION_ADD
- [ ] MESSAGE_REACTION_REMOVE
- [ ] MESSAGE_REACTION_REMOVE_ALL
- [ ] MESSAGE_REACTION_REMOVE_EMOJI

Intent: guild_message_typing/direct_message_typing
- [ ] TYPING_START

Intent: guild_scheduled_events
- [ ] GUILD_SCHEDULED_EVENT_CREATE
- [ ] GUILD_SCHEDULED_EVENT_UPDATE
- [ ] GUILD_SCHEDULED_EVENT_DELETE
- [ ] GUILD_SCHEDULED_EVENT_USER_ADD
- [ ] GUILD_SCHEDULED_EVENT_USER_REMOVE

Intent: auto_moderation_configuration
- [ ] AUTO_MODERATION_RULE_CREATE
- [ ] AUTO_MODERATION_RULE_UPDATE
- [ ] AUTO_MODERATION_RULE_DELETE

Intent: auto_moderation_execution
- [ ] AUTO_MODERATION_ACTION_EXECUTION

Intent: guild_message_polls
- [ ] MESSAGE_POLL_VOTE_ADD
- [ ] MESSAGE_POLL_VOTE_REMOVE

Intent: direct_message_polls
- [ ] MESSAGE_POLL_VOTE_ADD
- [ ] MESSAGE_POLL_VOTE_REMOVE
