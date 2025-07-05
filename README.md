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

## Development

```sh
gleam test  # Run the tests
```

## Features:

| Feature               | Status |
| --------------------- | ------ |
| Basic events          | ✅     |
| Sending messages      | ✅     |
| Ban/kick              | ✅     |
| Deleting messages     | ✅     |
| Embeds                | ✅     |
| Basic Slash commands  | ✅     |
| Message Cache         | ✅     |
| Intents               | 🔨     |

✅ - Done | 🔨 - In Progress | 📆 - Planned | ❌ - Not Planned

## Supported events:

- [x] READY
- [x] MESSAGE_CREATE
- [x] MESSAGE_DELETE
- [x] MESSAGE_UPDATE
- [ ] MESSAGE_DELETE_BULK
- [x] INTERACTION_CREATE
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
- [ ] GUILD_MEMBER_ADD
- [ ] GUILD_MEMBER_UPDATE
- [ ] GUILD_MEMBER_REMOVE
- [ ] GUILD_MEMBERS_CHUNK
- [ ] GUILD_AUDIT_LOG_ENTRY_CREATE
- [x] GUILD_BAN_ADD
- [x] GUILD_BAN_REMOVE
- [ ] GUILD_EMOJIS_UPDATE
- [ ] GUILD_STICKERS_UPDATE
- [ ] GUILD_SOUNDBOARD_SOUND_CREATE
- [ ] GUILD_SOUNDBOARD_SOUND_UPDATE
- [ ] GUILD_SOUNDBOARD_SOUND_DELETE
- [ ] GUILD_SOUNDBOARD_SOUNDS_UPDATE
- [ ] GUILD_INTEGRATIONS_UPDATE
- [ ] INTEGRATION_CREATE
- [ ] INTEGRATION_UPDATE
- [ ] INTEGRATION_DELETE
- [ ] WEBHOOKS_UPDATE
- [ ] INVITE_CREATE
- [ ] INVITE_DELETE
- [ ] VOICE_CHANNEL_EFFECT_SEND
- [ ] VOICE_STATE_UPDATE
- [ ] VOICE_SERVER_UPDATE
- [ ] PRESENCE_UPDATE
- [x] GUILD_ROLE_CREATE
- [x] GUILD_ROLE_UPDATE
- [x] GUILD_ROLE_DELETE
- [ ] MESSAGE_REACTION_ADD
- [ ] MESSAGE_REACTION_REMOVE
- [ ] MESSAGE_REACTION_REMOVE_ALL
- [ ] MESSAGE_REACTION_REMOVE_EMOJI
- [ ] TYPING_START
- [ ] GUILD_SCHEDULED_EVENT_CREATE
- [ ] GUILD_SCHEDULED_EVENT_UPDATE
- [ ] GUILD_SCHEDULED_EVENT_DELETE
- [ ] GUILD_SCHEDULED_EVENT_USER_ADD
- [ ] GUILD_SCHEDULED_EVENT_USER_REMOVE
- [ ] AUTO_MODERATION_RULE_CREATE
- [ ] AUTO_MODERATION_RULE_UPDATE
- [ ] AUTO_MODERATION_RULE_DELETE
- [ ] AUTO_MODERATION_ACTION_EXECUTION
- [ ] MESSAGE_POLL_VOTE_ADD
- [ ] MESSAGE_POLL_VOTE_REMOVE