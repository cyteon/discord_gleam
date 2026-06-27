import discord_gleam/discord/intents
import gleam/int
import gleam/json

pub fn create_packet(token: String, intents: intents.Intents) -> String {
  json.object([
    #("op", json.int(2)),
    #(
      "d",
      json.object([
        #("token", json.string(token)),
        #("intents", json.int(intents.intents_to_bitfield(intents))),
        #(
          "properties",
          json.object([
            #("os", json.string("gleam")),
            #("browser", json.string("discord_gleam")),
            #("device", json.string("discord_gleam")),
          ]),
        ),
      ]),
    ),
  ])
  |> json.to_string
}

pub fn create_resume_packet(
  token: String,
  intents: intents.Intents,
  session_id: String,
  sequence: Int,
) -> String {
  json.object([
    #("op", json.int(6)),
    #(
      "d",
      json.object([
        #("token", json.string(token)),
        #("session_id", json.string(session_id)),
        #("seq", json.int(sequence)),
        #("intents", json.int(intents.intents_to_bitfield(intents))),
      ]),
    ),
  ])
  |> json.to_string
}
