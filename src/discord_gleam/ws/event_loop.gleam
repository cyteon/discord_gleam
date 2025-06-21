//// Event loop for handling the discord gateway websocket
//// Dispatches events to registered event handlers

import birl
import birl/duration
import bravo/uset
import discord_gleam/event_handler
import discord_gleam/internal/error
import discord_gleam/types/bot
import discord_gleam/ws/packets/generic
import discord_gleam/ws/packets/hello
import discord_gleam/ws/packets/identify
import gleam/erlang/process
import gleam/function
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json
import gleam/option
import gleam/order
import gleam/otp/actor
import gleam/string
import logging
import repeatedly
import stratus

pub type State {
  State(has_received_hello: Bool, s: Int)
}

/// Start the event loop, with a set of event handlers.
pub fn main(
  bot: bot.Bot,
  event_handlers: List(event_handler.EventHandler),
  host: String,
  reconnect: Bool,
  session_id: String,
  state_uset: uset.USet(#(String, String)),
) -> Nil {
  logging.log(logging.Debug, "Requesting gateway")

  uset.insert(state_uset, [#("sequence", "0")])

  let host = string.replace(host, "wss://", "")

  let req =
    request.new()
    |> request.set_host(host)
    |> request.set_scheme(http.Https)
    |> request.set_path("/?v=10&encoding=json")
    |> request.set_header(
      "User-Agent",
      "DiscordBot (https://github.com/cyteon/discord_gleam, 1.2.0)",
    )
    |> request.set_header("Host", "gateway.discord.gg")
    |> request.set_header("Connection", "Upgrade")
    |> request.set_header("Upgrade", "websocket")
    |> request.set_header("Sec-WebSocket-Version", "13")

  logging.log(logging.Debug, "Creating builder")

  let initial_state = State(has_received_hello: False, s: 0)
  let last_connect = birl.now()

  let builder =
    stratus.websocket(
      request: req,
      init: fn() {
        logging.log(logging.Debug, "Initializing builder")
        #(initial_state, option.None)
      },
      loop: fn(msg, state, conn) {
        case msg {
          stratus.Text(msg) -> {
            logging.log(logging.Debug, "Gateway text msg: " <> msg)

            case state.has_received_hello {
              False -> {
                let identify = case reconnect {
                  True ->
                    identify.create_resume_packet(
                      bot.token,
                      bot.intents,
                      session_id,
                      case uset.lookup(state_uset, "sequence") {
                        Ok(s) -> s.1
                        Error(_) -> "0"
                      },
                    )

                  False -> identify.create_packet(bot.token, bot.intents)
                }

                let _ = stratus.send_text_message(conn, identify)

                let new_state = State(has_received_hello: True, s: 0)

                case hello.string_to_data(msg) {
                  Ok(data) -> {
                    process.start(
                      fn() {
                        repeatedly.call(
                          data.d.heartbeat_interval,
                          Nil,
                          fn(_state, _count_) {
                            let s = case uset.lookup(state_uset, "sequence") {
                              Ok(s) ->
                                case int.parse(s.1) {
                                  Ok(i) -> i
                                  Error(_) -> 0
                                }
                              Error(_) -> 0
                            }

                            let packet =
                              json.object([
                                #("op", json.int(1)),
                                #("d", case s {
                                  0 -> json.null()
                                  _ -> json.int(s)
                                }),
                              ])
                              |> json.to_string()

                            logging.log(
                              logging.Debug,
                              "Sending heartbeat: " <> packet,
                            )

                            stratus.send_text_message(conn, packet)
                          },
                        )
                      },
                      False,
                    )

                    Nil
                  }

                  Error(err) -> {
                    logging.log(
                      logging.Critical,
                      "Failed to decode hello packet: "
                        <> error.json_decode_error_to_string(err),
                    )

                    let _ = stratus.close(conn)

                    logging.log(
                      logging.Critical,
                      "Closing websocket due to fatal error",
                    )
                  }
                }

                actor.continue(new_state)
              }

              True -> {
                let generic_packet = generic.string_to_data(msg)

                case generic_packet.s {
                  0 -> Nil

                  _ -> {
                    uset.insert(state_uset, [
                      #("sequence", int.to_string(generic_packet.s)),
                    ])

                    Nil
                  }
                }

                case generic_packet.op {
                  7 -> {
                    logging.log(logging.Debug, "Received a reconnect request")
                    case stratus.close(conn) {
                      Ok(_) -> logging.log(logging.Debug, "Closed websocket")
                      Error(_) ->
                        logging.log(logging.Error, "Failed to close websocket")
                    }

                    main(
                      bot,
                      event_handlers,
                      case uset.lookup(state_uset, "resume_gateway_url") {
                        Ok(url) -> url.1
                        Error(_) -> "gateway.discord.gg"
                      },
                      reconnect,
                      case uset.lookup(state_uset, "session_id") {
                        Ok(s) -> s.1
                        Error(_) -> ""
                      },
                      state_uset,
                    )
                  }

                  _ -> Nil
                }

                let new_state =
                  State(has_received_hello: True, s: generic_packet.s)

                event_handler.handle_event(bot, msg, event_handlers, state_uset)

                actor.continue(new_state)
              }
            }
          }

          stratus.User(msg) -> {
            logging.log(logging.Debug, "Gateway user msg: " <> msg)
            actor.continue(state)
          }

          stratus.Binary(_) -> {
            logging.log(logging.Debug, "Binary message")
            actor.continue(state)
          }
        }
      },
    )
    |> stratus.on_close(fn(_) {
      logging.log(logging.Debug, "The webhook was closed")

      let diff = birl.difference(last_connect, birl.now())

      case duration.compare(diff, duration.minutes(1)) {
        order.Gt -> {
          logging.log(
            logging.Debug,
            "Over 1 minute since connection, reconnecting",
          )

          main(
            bot,
            event_handlers,
            case uset.lookup(state_uset, "resume_gateway_url") {
              Ok(url) -> url.1
              Error(_) -> "gateway.discord.gg"
            },
            reconnect,
            case uset.lookup(state_uset, "session_id") {
              Ok(s) -> s.1
              Error(_) -> ""
            },
            state_uset,
          )
        }

        _ -> {
          logging.log(
            logging.Error,
            "Disconnected after too short time, not reconnecting",
          )
          Nil
        }
      }

      Nil
    })

  let assert Ok(subj) = stratus.initialize(builder)

  process.new_selector()
  |> process.selecting_process_down(
    process.monitor_process(process.subject_owner(subj)),
    function.identity,
  )
  |> process.select_forever

  logging.log(logging.Error, "websocket go bye bye")

  process.sleep(1000)
}
