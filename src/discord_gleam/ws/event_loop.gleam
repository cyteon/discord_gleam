//// Event loop for handling the discord gateway websocket
//// Dispatches events to registered event handlers

import booklet
import discord_gleam/event_handler
import discord_gleam/internal/error
import discord_gleam/types/bot
import discord_gleam/ws/packets/generic
import discord_gleam/ws/packets/hello
import discord_gleam/ws/packets/identify
import gleam/dict
import gleam/erlang/process
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json
import gleam/option
import gleam/otp/actor
import gleam/result
import logging
import repeatedly
import stratus

/// The message type for the event loop actor
pub type EventLoopMessage {
  Start
  Restart(host: String, session_id: String)
  Stop
}

/// Start the event loop, with a set of event handlers.
pub fn start_event_loop(
  mode: event_handler.Mode(user_state, user_message),
  host: String,
  reconnect: Bool,
  session_id: String,
  state_ets: booklet.Booklet(dict.Dict(String, String)),
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
      Restart(host, session_id) -> {
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

pub type WebsocketState(user_state) {
  State(
    has_received_hello: Bool,
    s: Int,
    event_loop_subject: process.Subject(EventLoopMessage),
    user_state: user_state,
  )
}

pub type WebsocketMessage(user_message) {
  BotMessage(bot.BotMessage)
  User(user_message)
}

fn start_discord_websocket(
  mode: event_handler.Mode(user_state, user_message),
  event_loop_subject: process.Subject(EventLoopMessage),
  host: String,
  reconnect: Bool,
  session_id: String,
  state_ets: booklet.Booklet(dict.Dict(String, String)),
) -> Result(Nil, actor.StartError) {
  let req =
    request.new()
    |> request.set_host(host)
    |> request.set_scheme(http.Https)
    |> request.set_path("/?v=10&encoding=json")
    |> request.set_header(
      "User-Agent",
      "DiscordBot (https://github.com/cyteon/discord_gleam, 1.7.1)",
    )
    |> request.set_header("Host", "gateway.discord.gg")
    |> request.set_header("Connection", "Upgrade")
    |> request.set_header("Upgrade", "websocket")
    |> request.set_header("Sec-WebSocket-Version", "13")

  logging.log(logging.Debug, "Creating websocket client builder")

  let name: process.Name(bot.BotMessage) = process.new_name("bot_msg_subject")
  let bot =
    bot.Bot(
      ..event_handler.bot_from_mode(mode),
      websocket_name: option.Some(name),
    )

  let started =
    stratus.new_with_initialiser(request: req, init: fn() {
      process.register(process.self(), name)
      |> result.map(fn(_nil) {
        let selector =
          process.new_selector()
          |> process.select(process.named_subject(name))
          |> process.map_selector(BotMessage)

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
          )

        stratus.initialised(initial_state)
        |> stratus.selecting(selector)
      })
      |> result.replace_error("Failed to initialise websocket client")
    })
    |> stratus.on_message(fn(state, msg, conn) {
      case msg {
        stratus.Text(msg) ->
          handle_text_message(
            conn,
            state,
            msg,
            bot,
            mode,
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
              bot,
              state.user_state,
              event_handler.InternalUser(msg),
              mode,
              state_ets,
            )

          case next {
            event_handler.Continue(user_state, opt) -> {
              let new_state = State(..state, user_state:)
              let next = stratus.continue(new_state)

              case opt {
                option.Some(user_selector) ->
                  stratus.with_selector(
                    next,
                    process.map_selector(user_selector, User),
                  )
                option.None -> next
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
    Error(stratus.ActorFailed(actor_failed)) -> Error(actor_failed)
    Error(stratus.HandshakeFailed(_)) ->
      Error(actor.InitFailed("handshake failed"))
    Error(stratus.FailedToTransferSocket(_)) ->
      Error(actor.InitFailed("failed to transfer socket"))
    Ok(_) -> Ok(Nil)
  }
}

fn handle_text_message(
  conn: stratus.Connection,
  state: WebsocketState(user_state),
  msg: String,
  bot: bot.Bot,
  mode: event_handler.Mode(user_state, user_message),
  reconnect: Bool,
  session_id: String,
  state_ets: booklet.Booklet(dict.Dict(String, String)),
) {
  logging.log(logging.Debug, "Gateway text msg: " <> msg)

  case state.has_received_hello {
    False -> {
      let identify = case reconnect {
        True ->
          identify.create_resume_packet(
            bot.token,
            bot.intents,
            session_id,
            case dict.get(booklet.get(state_ets), "sequence") {
              Ok(s) -> s
              Error(_) -> "0"
            },
          )

        False -> identify.create_packet(bot.token, bot.intents)
      }

      let _ = stratus.send_text_message(conn, identify)

      let new_state =
        State(
          has_received_hello: True,
          s: 0,
          event_loop_subject: state.event_loop_subject,
          user_state: state.user_state,
        )

      case hello.string_to_data(msg) {
        Ok(data) -> {
          process.spawn(fn() {
            repeatedly.call(data.d.heartbeat_interval, Nil, fn(_state, _count_) {
              let s = case dict.get(booklet.get(state_ets), "sequence") {
                Ok(s) ->
                  case int.parse(s) {
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

              logging.log(logging.Debug, "Sending heartbeat: " <> packet)

              let _ = stratus.send_text_message(conn, packet)

              Nil
            })
          })

          Nil
        }

        Error(err) -> {
          logging.log(
            logging.Critical,
            "Failed to decode hello packet: "
              <> error.json_decode_error_to_string(err),
          )

          let _ = stratus.close(conn, stratus.Normal(<<>>))

          logging.log(logging.Critical, "Closing websocket due to fatal error")
        }
      }

      stratus.continue(new_state)
    }

    True -> {
      let generic_packet = generic.string_to_data(msg)

      case generic_packet.s {
        0 -> Nil

        _ -> {
          booklet.update(state_ets, fn(cache) {
            dict.insert(
              cache,
              "sequence",
              case dict.get(booklet.get(state_ets), "sequence") {
                Ok(s) -> s
                Error(_) -> "0"
              },
            )
          })

          Nil
        }
      }

      case generic_packet.op {
        7 -> {
          logging.log(logging.Debug, "Received a reconnect request")
          case stratus.close_custom(conn, 4009, <<>>) {
            Ok(_) -> logging.log(logging.Debug, "Closed websocket")
            Error(_) -> logging.log(logging.Error, "Failed to close websocket")
          }

          let host = case
            dict.get(booklet.get(state_ets), "resume_gateway_url")
          {
            Ok(url) -> url
            Error(_) -> "gateway.discord.gg"
          }
          let session_id = case dict.get(booklet.get(state_ets), "session_id") {
            Ok(s) -> s
            Error(_) -> ""
          }

          process.send(state.event_loop_subject, Restart(host:, session_id:))
        }

        _ -> Nil
      }

      let new_state =
        State(
          has_received_hello: True,
          s: generic_packet.s,
          event_loop_subject: state.event_loop_subject,
          user_state: state.user_state,
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
            option.Some(user_selector) ->
              stratus.with_selector(
                next,
                process.map_selector(user_selector, User),
              )
            option.None -> next
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
  state: WebsocketState(user_state),
  state_ets: booklet.Booklet(dict.Dict(String, String)),
  close_reason: stratus.CloseReason,
) {
  logging.log(logging.Debug, "The webhook was closed")

  case close_reason {
    stratus.Custom(custom_close_reason) -> {
      case stratus.get_custom_code(custom_close_reason) {
        4000 -> {
          logging.log(logging.Error, "Unknown error, not reconnecting")
        }

        4001 -> {
          logging.log(logging.Error, "Unknown opcode, not reconnecting")
        }

        4002 -> {
          logging.log(
            logging.Error,
            "Decode error, open a github issue, not reconnecting",
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

          let host = case
            dict.get(booklet.get(state_ets), "resume_gateway_url")
          {
            Ok(url) -> url
            Error(_) -> "gateway.discord.gg"
          }

          process.send(state.event_loop_subject, Restart(host:, session_id: ""))
        }

        4008 -> {
          logging.log(
            logging.Error,
            "You have been ratelimited, not reconnecting",
          )
        }

        4009 -> {
          logging.log(logging.Error, "Session timed out, reconnecting")

          let host = case
            dict.get(booklet.get(state_ets), "resume_gateway_url")
          {
            Ok(url) -> url
            Error(_) -> "gateway.discord.gg"
          }
          let session_id = case dict.get(booklet.get(state_ets), "session_id") {
            Ok(s) -> s
            Error(_) -> ""
          }

          process.send(state.event_loop_subject, Restart(host:, session_id:))
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
            "Disallowed intents used, did you remember to enable any priveleged intents you used in the Discord Developer Portal (https://discord.dev)? Not reconnecting",
          )
        }

        _ -> {
          logging.log(logging.Error, "Unknown close code, not reconnecting")
        }
      }
    }
    _ -> Nil
  }
}
