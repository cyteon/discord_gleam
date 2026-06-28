# discord_gleam

[![Package Version](https://img.shields.io/hexpm/v/discord_gleam)](https://hex.pm/packages/discord_gleam)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/discord_gleam/)

```sh
gleam add discord_gleam
```

## Example Bot

```gleam
import discord_gleam
import discord_gleam/bot
import discord_gleam/event_handler
import gleam/erlang/process
import gleam/otp/static_supervisor as supervisor
import gleam/otp/supervision
import logging

pub fn main() {
  logging.configure()
  logging.set_level(logging.Info)

  let bot =
    bot.new(
      "TOKEN",
      "CLIENT ID",
    )

  let bot =
    supervision.worker(fn() {
      discord_gleam.simple(bot, [simple_handler])
      |> discord_gleam.start()
    })

  let assert Ok(_) =
    supervisor.new(supervisor.OneForOne)
    |> supervisor.add(bot)
    |> supervisor.start()

  process.sleep_forever()
}

fn simple_handler(bot, packet: event_handler.Packet) {
  case packet {
    event_handler.ReadyPacket(ready) -> {
      logging.log(
        logging.Info,
        "Bot is ready! Logged in as: " <> ready.d.user.username,
      )
      Nil
    }

    event_handler.MessagePacket(message) -> {
      logging.log(logging.Info, "Got message: " <> message.d.content)

      case message.d.content {
        "!ping" -> {
          let _ =
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

Further documentation can be found at <https://hexdocs.pm/discord_gleam>. And more examples can be found in the `examples/` folder.

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
- [x] GUILD_CREATE
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
- [x] GUILD_MEMBER_ADD
- [x] GUILD_MEMBER_UPDATE
- [x] GUILD_MEMBER_REMOVE
- [x] GUILD_MEMBERS_CHUNK
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
- [x] PRESENCE_UPDATE

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
