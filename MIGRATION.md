# Migration Guide (v2 -> v3)

### 1. New bot constructor

```gleam
// v2
import discord_gleam
import discord_gleam/discord/intents

// v3
import discord_gleam/bot
import discord_gleam/discord/intents

let bot =
  bot.new(token, client_id)
  |> bot.with_intents(intents.all()) // or: intents.none(), intents.default_with_message_intent() or dont change for intents.default()
```

### 2. Snowflakes are now opaque types instead of strings

Every ID parameter now takes Snowflake(type) instead of a String. Diffrent types of snowflakes cant be mixed up at runtime due to this.

```gleam
// v2
discord_gleam.reply(bot, "CHANNEL_ID", "MESSAGE_ID", "Hello world!", [])
  
// v3
let channel_id = snowflake.from_string("CHANNEL_ID")
let message_id = snowflake.from_string("MESSAGE_ID")

discord_gleam.reply(bot, channel_id, message_id, message.new("Hello world!"))
```

### 3. Message and embeds are built instead of constructed with raw args

```gleam
// v2
import discord_gleam/types/message

let embed = message.Embed(title: "Hi", description: "Hello world!", color: 0xFF0000)
discord_gleam.send_message(bot, channel_id, "Hello world!", [embed])

// v3
import discord_gleam/types/message
import discord_gleam/types/embed

let e = embed.new(title: "Hi", description: "Hello world!", color: 0xFF0000)
  |> embed.set_footer(text: "Footer text", icon_url: None)

let msg = message.new("Hello world!")
  |> message.add_embed(e)

discord_gleam.send_message(bot, channel_id, msg)
```

### 4. discord_gleam.interaction_reply_message has been replaced

```gleam
// v2
discord_gleam.interaction_reply_message(interaction, "Hello!", False)

// v3
import discord_gleam/types/interaction
import discord_gleam/types/message

interaction.send_message(interaction, message.new("Hello!"), ephemeral: False)
// also added: interaction.defer_response, interaction.edit_response and interaction.custom_response (can be used for modals)
```

### 5. Packet data is no longer nested behind .d
```gleam
// v2
event_handler.ReadyPacket(ready) -> {
  logging.log(
    logging.Info,
    "Logged in as "
      <> ready.d.user.username
      <> "#"
      <> ready.d.user.discriminator,
  )
}

// v3
event_handler.ReadyPacket(ready) -> {
  logging.log(
    logging.Info,
    "Logged in as "
      <> ready.user.username // ready.user instead of ready.d.user
      <> "#"
      <> ready.user.discriminator,
  )
}
```

### 6. DiscordError has been reshaped
```gleam
// v2 had:
// UnknownAccount, EmptyOptionWhenRequired, JsonDecodeError, InvalidDynamicList,
// InvalidFormat, WebsocketError, HttpError, GenericHttpError, ActorError,
// NilMapEntry, BadBuilderProperties, Unauthorized

// v3 now only has JsonDecodeError, HttpError, ApiError and RateLimitError
pub type DiscordError {
  JsonDecodeError(json.DecodeError)
  HttpError(httpc.HttpError)
  ApiError(status_code: Int, body: String)
  RatelimitError(retry_after_secs: Float, global: Bool)
}
```

### 7. discord_gleam/http/endpoints module split
If you used to directly import `discord_gleam/http/endpoints`, it has been split into the following files:

```gleam
import discord_gleam/http/applications
// wipe_global_commands, wipe_guild_commands,
// register_global_command, register_guild_command
import discord_gleam/http/channels
// send_message, reply, delete_message, edit_message
import discord_gleam/http/guilds
// kick_member, ban_member
import discord_gleam/http/interactions
// send_response, edit_original
import discord_gleam/http/users
// me, create_dm_channel, send_direct_message
```

### 8. message_content removed from intents.default()
Default intents were not supposed to include message_content, but it did on accident. \
The message_content intent has been removed from intents.default() and is now only in intents.default_with_message_intent() and intents.all() by default.
