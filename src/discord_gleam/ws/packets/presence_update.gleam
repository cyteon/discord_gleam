import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/activity
import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None, Some}

// TODO: Move to types/user.gleam?
pub type PartialUser {
  PartialUser(id: Snowflake)
}

pub type ClientStatus {
  ClientStatus(
    desktop: Option(String),
    mobile: Option(String),
    web: Option(String),
  )
}

pub type PresenceUpdatePacketData {
  PresenceUpdatePacketData(
    user: PartialUser,
    guild_id: Snowflake,
    status: String,
    activities: List(activity.Activity),
    client_status: ClientStatus,
  )
}

pub type PresenceUpdatePacket {
  PresenceUpdatePacket(t: String, s: Int, op: Int, d: PresenceUpdatePacketData)
}

pub fn string_to_data(
  encoded: String,
) -> Result(PresenceUpdatePacket, json.DecodeError) {
  let decoder = {
    use t <- decode.field("t", decode.string)
    use s <- decode.field("s", decode.int)
    use op <- decode.field("op", decode.int)
    use d <- decode.field("d", {
      use user <- decode.field("user", partial_user_decoder())
      use guild_id <- decode.field("guild_id", snowflake.decoder())
      use status <- decode.field("status", decode.string)
      use activities <- decode.field(
        "activities",
        decode.list(activity.from_json_decoder()),
      )
      use client_status <- decode.field(
        "client_status",
        client_status_decoder(),
      )

      decode.success(PresenceUpdatePacketData(
        user:,
        guild_id:,
        status:,
        activities:,
        client_status:,
      ))
    })
    decode.success(PresenceUpdatePacket(t:, s:, op:, d:))
  }

  json.parse(from: encoded, using: decoder)
}

fn partial_user_decoder() {
  use id <- decode.field("id", snowflake.decoder())
  decode.success(PartialUser(id:))
}

fn client_status_decoder() {
  use desktop <- decode.optional_field(
    "desktop",
    None,
    decode.string |> decode.map(Some),
  )
  use mobile <- decode.optional_field(
    "mobile",
    None,
    decode.string |> decode.map(Some),
  )
  use web <- decode.optional_field(
    "web",
    None,
    decode.string |> decode.map(Some),
  )

  decode.success(ClientStatus(desktop:, mobile:, web:))
}
