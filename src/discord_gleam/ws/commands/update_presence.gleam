import discord_gleam/bot
import gleam/json
import gleam/option.{type Option, None, Some}

pub type Status {
  Online
  Idle
  DoNotDisturb
  Invisible
  Offline
}

pub type ActivityType {
  Playing
  Streaming
  Listening
  Watching
  Custom
  Competing
}

pub type Activity {
  Activity(
    type_: ActivityType,
    name: String,
    url: Option(String),
    state: Option(String),
  )
}

pub type Presence {
  Presence(
    status: Status,
    activities: List(Activity),
    afk: Bool,
    since: Option(Int),
  )
}

pub fn playing(name: String) -> Activity {
  Activity(type_: Playing, name:, url: None, state: None)
}

pub fn streaming(name: String, url: String) -> Activity {
  Activity(type_: Streaming, name:, url: Some(url), state: None)
}

pub fn listening(name: String) -> Activity {
  Activity(type_: Listening, name:, url: None, state: None)
}

pub fn watching(name: String) -> Activity {
  Activity(type_: Watching, name:, url: None, state: None)
}

pub fn custom(text: String) -> Activity {
  Activity(type_: Custom, name: "Custom Activity", url: None, state: Some(text))
}

pub fn competing(name: String) -> Activity {
  Activity(type_: Competing, name:, url: None, state: None)
}

pub fn update_presence(bot: bot.Bot, presence: Presence) -> Nil {
  let packet =
    json.object([
      #("op", json.int(3)),
      #("d", to_json(presence)),
    ])
    |> json.to_string

  bot.send_packet(bot, packet)
}

pub fn to_json(presence: Presence) -> json.Json {
  json.object([
    #("since", case presence.since {
      None -> json.null()
      Some(s) -> json.int(s)
    }),
    #("status", json.string(status_to_string(presence.status))),
    #("afk", json.bool(presence.afk)),
    #("activities", json.array(presence.activities, of: activity_to_json)),
  ])
}

pub fn status_to_string(status: Status) -> String {
  case status {
    Online -> "online"
    Idle -> "idle"
    DoNotDisturb -> "dnd"
    Invisible -> "invisible"
    Offline -> "offline"
  }
}

pub fn activity_to_json(activity: Activity) -> json.Json {
  json.object([
    #("name", json.string(activity.name)),
    #("type", json.int(type_to_int(activity.type_))),
    #("url", case activity.url {
      None -> json.null()
      Some(url) -> json.string(url)
    }),
    #("state", case activity.state {
      None -> json.null()
      Some(state) -> json.string(state)
    }),
  ])
}

pub fn type_to_int(type_: ActivityType) -> Int {
  case type_ {
    Playing -> 0
    Streaming -> 1
    Listening -> 2
    Watching -> 3
    Custom -> 4
    Competing -> 5
  }
}
