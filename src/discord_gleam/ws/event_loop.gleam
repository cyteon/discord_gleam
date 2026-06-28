//// Event loop for handling the discord gateway websocket \
//// Dispatches events to registered event handlers

import booklet
import discord_gleam/bot
import discord_gleam/event_handler
import discord_gleam/internal/error
import discord_gleam/ws/gateway_state
import discord_gleam/ws/packets/generic
import discord_gleam/ws/packets/hello
import discord_gleam/ws/packets/identify
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http
import gleam/http/request
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import logging
import repeatedly
import stratus

/// The message type for the event loop actor
pub type EventLoopMessage {
  Start
  Restart(host: String, session_id: String, reconnect: Bool)
  Stop
}

/// Start the event loop, with a set of event handlers.
pub fn start_event_loop(
  mode mode: event_handler.Mode(user_state, user_message),
  host host: String,
  reconnect reconnect: Bool,
  session_id session_id: String,
  state_ets state_ets: booklet.Booklet(gateway_state.GatewayState),
) {
  logging.log(logging.Debug, "Starting event loop")

  actor.new_with_initialiser(1000, fn(subject) {
    logging.log(logging.Debug, "Sending start message")
    actor.send(subject, Start)

    actor.initialised(subject)
    |> actor.returning(subject)
    |> Ok
  })
  |> actor.on_message(fn(subject, msg) {
    case msg {
      Start -> {
        logging.log(logging.Debug, "Received start message")
        let started =
          start_discord_websocket(
            mode,
            subject,
            host,
            reconnect,
            session_id,
            state_ets,
          )

        case started {
          Ok(Nil) -> actor.continue(subject)
          Error(_actor_failed) ->
            actor.stop_abnormal("failed to start discord websocket")
        }
      }

      Restart(host, session_id, reconnect) -> {
        logging.log(logging.Debug, "Restarting discord websocket")

        let started =
          start_discord_websocket(
            mode,
            subject,
            host,
            reconnect,
            session_id,
            state_ets,
          )

        case started {
          Ok(Nil) -> actor.continue(subject)
          Error(_actor_failed) ->
            actor.stop_abnormal("failed to restart discord websocket")
        }
      }

      Stop -> actor.stop()
    }
  })
  |> actor.start()
}

pub type WebsocketState(user_state, user_message) {
  State(
    has_received_hello: Bool,
    s: Int,
    event_loop_subject: process.Subject(EventLoopMessage),
    user_state: user_state,
    bot: bot.Bot,
    mode: event_handler.Mode(user_state, user_message),
    heartbeat: Option(repeatedly.Repeater(Nil)),
  )
}

pub type WebsocketMessage(user_message) {
  BotMessage(bot.BotMessage)
  User(user_message)
}

fn start_discord_websocket(
  mode mode: event_handler.Mode(user_state, user_message),
  event_loop_subject event_loop_subject: process.Subject(EventLoopMessage),
  host host: String,
  reconnect reconnect: Bool,
  session_id session_id: String,
  state_ets state_ets: booklet.Booklet(gateway_state.GatewayState),
) -> Result(Nil, actor.StartError) {
  let req =
    request.new()
    |> request.set_host(host)
    |> request.set_scheme(http.Https)
    |> request.set_path("/?v=10&encoding=json")
    |> request.set_header(
      "User-Agent",
      "DiscordBot (https://github.com/cyteon/discord_gleam, 3.0.0)",
    )
    |> request.set_header("Host", "gateway.discord.gg")
    |> request.set_header("Connection", "Upgrade")
    |> request.set_header("Upgrade", "websocket")
    |> request.set_header("Sec-WebSocket-Version", "13")

  logging.log(logging.Debug, "Creating websocket client builder")

  let started =
    stratus.new_with_initialiser(request: req, init: fn() {
      use selector <- result.try(case event_handler.name_from_mode(mode) {
        Ok(name) -> {
          process.register(process.self(), name)
          |> result.map(fn(_nil) {
            process.new_selector()
            |> process.select_map(process.named_subject(name), User)
          })
          |> result.replace_error(
            "failed to register name for websocket client process",
          )
        }
        Error(_) -> Ok(process.new_selector())
      })

      let bot_message_subject = process.new_subject()
      let bot =
        bot.Bot(
          ..event_handler.bot_from_mode(mode),
          subject: bot_message_subject,
        )
      let mode = event_handler.set_bot(mode, bot)

      let selector =
        process.select_map(selector, bot_message_subject, BotMessage)

      let #(user_state, selector) = case mode {
        event_handler.Normal(on_init:, ..) -> {
          let #(user_state, user_selector) = on_init(process.new_selector())

          let selector =
            process.map_selector(user_selector, User)
            |> process.merge_selector(selector, _)

          #(user_state, selector)
        }
        event_handler.Simple(nil_state:, ..) -> {
          #(nil_state, selector)
        }
      }

      let initial_state =
        State(
          has_received_hello: False,
          s: 0,
          event_loop_subject:,
          user_state:,
          bot:,
          mode:,
          heartbeat: None,
        )

      stratus.initialised(initial_state)
      |> stratus.selecting(selector)
      |> Ok
    })
    |> stratus.on_message(fn(state, msg, conn) {
      case msg {
        stratus.Text(msg) ->
          handle_text_message(
            conn,
            state,
            msg,
            state.bot,
            state.mode,
            reconnect,
            session_id,
            state_ets,
          )

        stratus.User(BotMessage(bot.SendPacket(packet))) -> {
          logging.log(logging.Debug, "User packet: " <> packet)

          let _ = stratus.send_text_message(conn, packet)

          stratus.continue(state)
        }

        stratus.User(User(msg)) -> {
          let next =
            event_handler.handle_event(
              state.bot,
              state.user_state,
              event_handler.InternalUser(msg),
              state.mode,
              state_ets,
            )

          case next {
            event_handler.Continue(user_state, opt) -> {
              let new_state = State(..state, user_state:)
              let next = stratus.continue(new_state)

              case opt {
                Some(user_selector) ->
                  stratus.with_selector(
                    next,
                    process.map_selector(user_selector, User),
                  )

                None -> next
              }
            }
            event_handler.Stop -> {
              logging.log(
                logging.Debug,
                "Stopping discord websocket connection",
              )
              process.send(state.event_loop_subject, Stop)
              stratus.stop()
            }
            event_handler.StopAbnormal(reason) -> {
              logging.log(
                logging.Error,
                "Stopping discord websocket connection with abnormal reason: "
                  <> reason,
              )
              stratus.stop_abnormal(reason)
            }
          }
        }

        stratus.Binary(_) -> {
          logging.log(logging.Debug, "Binary message")
          stratus.continue(state)
        }
      }
    })
    |> stratus.on_close(fn(state, close_reason) {
      on_close(state, state_ets, close_reason)
    })
    |> stratus.start()

  case started {
    Error(err) -> Error(err)
    Ok(_) -> Ok(Nil)
  }
}

fn handle_text_message(
  conn: stratus.Connection,
  state: WebsocketState(user_state, user_message),
  msg: String,
  bot: bot.Bot,
  mode: event_handler.Mode(user_state, user_message),
  reconnect: Bool,
  session_id: String,
  state_ets: booklet.Booklet(gateway_state.GatewayState),
) {
  logging.log(logging.Debug, "Gateway text msg: " <> msg)

  case state.has_received_hello {
    False -> {
      let generic = generic.from_json_string(msg)

      case generic.op {
        10 -> {
          case hello.from_json_string(msg) {
            Ok(data) -> {
              let repeater =
                repeatedly.call(data.d.heartbeat_interval, Nil, fn(_, _) {
                  let s = booklet.get(state_ets).sequence

                  let packet =
                    json.object([
                      #("op", json.int(1)),
                      #("d", case s {
                        0 -> json.null()
                        _ -> json.int(s)
                      }),
                    ])
                    |> json.to_string()

                  logging.log(logging.Debug, "Sending heartbeat: " <> packet)

                  let _ = stratus.send_text_message(conn, packet)

                  Nil
                })

              let identify = case reconnect {
                True ->
                  identify.create_resume_packet(
                    bot.token,
                    session_id,
                    booklet.get(state_ets).sequence,
                  )

                False -> identify.create_packet(bot.token, bot.intents)
              }

              let _ = option.map(state.heartbeat, repeatedly.stop)
              let _ = stratus.send_text_message(conn, identify)

              let new_state =
                State(
                  ..state,
                  has_received_hello: True,
                  s: 0,
                  heartbeat: Some(repeater),
                )

              stratus.continue(new_state)
            }

            Error(err) -> {
              logging.log(
                logging.Critical,
                "Failed to decode hello packet: "
                  <> error.json_decode_error_to_string(err),
              )

              let _ = stratus.close(conn, stratus.Normal(<<>>))
              logging.log(
                logging.Critical,
                "Closing websocket due to fatal error",
              )

              stratus.continue(state)
            }
          }
        }

        _ -> {
          stratus.continue(state)
        }
      }
    }

    True -> {
      let generic_packet = generic.from_json_string(msg)

      case generic_packet.s {
        Some(s) -> {
          booklet.update(state_ets, fn(state) {
            gateway_state.GatewayState(..state, sequence: s)
          })

          Nil
        }

        _ -> Nil
      }

      case generic_packet.op {
        7 -> {
          logging.log(logging.Debug, "Received a reconnect request")

          case stratus.close_custom(conn, 4009, <<>>) {
            Ok(_) -> logging.log(logging.Debug, "Closed websocket")
            Error(_) -> logging.log(logging.Error, "Failed to close websocket")
          }

          let host = booklet.get(state_ets).resume_gateway_url
          let session_id = booklet.get(state_ets).session_id

          process.send(
            state.event_loop_subject,
            Restart(host:, session_id:, reconnect: True),
          )
        }

        9 -> {
          logging.log(logging.Debug, "Invalid session, reconnecting")

          case stratus.close_custom(conn, 4009, <<>>) {
            Ok(_) -> logging.log(logging.Debug, "Closed websocket")
            Error(_) -> logging.log(logging.Error, "Failed to close websocket")
          }

          let host = booklet.get(state_ets).resume_gateway_url
          let session_id = booklet.get(state_ets).session_id

          let decoder = {
            use d <- decode.field("d", decode.bool)
            decode.success(d)
          }

          let decoded = case json.parse(from: msg, using: decoder) {
            Ok(d) -> d
            Error(_) -> False
          }

          process.send(
            state.event_loop_subject,
            Restart(host:, session_id:, reconnect: decoded),
          )
        }

        _ -> Nil
      }

      let new_state =
        State(
          has_received_hello: True,
          s: case generic_packet.s {
            Some(s) -> s
            None -> state.s
          },
          event_loop_subject: state.event_loop_subject,
          user_state: state.user_state,
          bot: state.bot,
          mode: state.mode,
          heartbeat: state.heartbeat,
        )

      let next =
        event_handler.handle_event(
          bot,
          state.user_state,
          event_handler.InternalPacket(msg),
          mode,
          state_ets,
        )

      case next {
        event_handler.Continue(user_state, opt) -> {
          let new_state = State(..new_state, user_state:)
          let next = stratus.continue(new_state)

          case opt {
            Some(user_selector) ->
              stratus.with_selector(
                next,
                process.map_selector(user_selector, User),
              )

            None -> next
          }
        }

        event_handler.Stop -> {
          logging.log(logging.Debug, "Stopping discord websocket connection")
          stratus.stop()
        }

        event_handler.StopAbnormal(reason) -> {
          logging.log(
            logging.Error,
            "Stopping discord websocket connection with abnormal reason: "
              <> reason,
          )
          stratus.stop_abnormal(reason)
        }
      }
    }
  }
}

fn on_close(
  state: WebsocketState(user_state, user_message),
  state_ets: booklet.Booklet(gateway_state.GatewayState),
  close_reason: stratus.CloseReason,
) {
  logging.log(logging.Debug, "The websocket was closed")
  let _ = option.map(state.heartbeat, repeatedly.stop)

  case close_reason {
    stratus.Custom(custom_close_reason) -> {
      case stratus.get_custom_code(custom_close_reason) {
        4000 -> {
          logging.log(logging.Error, "Unknown error, reconnecting")

          let host = booklet.get(state_ets).resume_gateway_url
          let session_id = booklet.get(state_ets).session_id

          process.send(
            state.event_loop_subject,
            Restart(host:, session_id:, reconnect: True),
          )
        }

        4001 -> {
          logging.log(logging.Error, "Unknown opcode, not reconnecting")
        }

        4002 -> {
          logging.log(logging.Error, "Decode error, reconnecting")

          let host = booklet.get(state_ets).resume_gateway_url
          let session_id = booklet.get(state_ets).session_id

          process.send(
            state.event_loop_subject,
            Restart(host:, session_id:, reconnect: True),
          )
        }

        4003 -> {
          logging.log(logging.Error, "Not authenticated, not reconnecting")
        }

        4004 -> {
          logging.log(
            logging.Error,
            "Authentication failed, check your token, not reconnecting",
          )
        }

        4005 -> {
          logging.log(
            logging.Error,
            "Already authenticated, open a github issue, not reconnecting",
          )
        }

        4007 -> {
          logging.log(logging.Error, "Invalid sequence, reconnecting")

          let host = booklet.get(state_ets).resume_gateway_url

          process.send(
            state.event_loop_subject,
            Restart(host:, session_id: "", reconnect: False),
          )
        }

        4008 -> {
          logging.log(
            logging.Error,
            "You have been ratelimited, not reconnecting",
          )
        }

        4009 -> {
          logging.log(logging.Error, "Session timed out, reconnecting")

          let host = booklet.get(state_ets).resume_gateway_url
          let session_id = booklet.get(state_ets).session_id

          process.send(
            state.event_loop_subject,
            Restart(host:, session_id:, reconnect: True),
          )
        }

        4010 -> {
          logging.log(logging.Error, "Invalid shard, not reconnecting")
        }

        4011 -> {
          logging.log(logging.Error, "Sharding required, not reconnecting")
        }

        4012 -> {
          logging.log(
            logging.Error,
            "Invalid API version, open a github issue on the discord_gleam repository, not reconnecting",
          )
        }

        4013 -> {
          logging.log(
            logging.Error,
            "Invalid intents used, open a github issue on the discord_gleam repository, not reconnecting",
          )
        }

        4014 -> {
          logging.log(
            logging.Error,
            "Disallowed intents used, did you remember to enable any privileged intents you used in the Discord Developer Portal (https://discord.dev)? Not reconnecting",
          )
        }

        _ -> {
          logging.log(logging.Error, "Unknown close code, not reconnecting")
        }
      }
    }

    _ -> {
      let host = booklet.get(state_ets).resume_gateway_url
      let session_id = booklet.get(state_ets).session_id

      logging.log(logging.Debug, "Reconnecting to the gateway")

      process.send(
        state.event_loop_subject,
        Restart(host:, session_id:, reconnect: True),
      )
    }
  }
}
