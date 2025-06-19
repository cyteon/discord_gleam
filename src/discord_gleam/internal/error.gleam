import gleam/dynamic/decode
import gleam/hackney
import gleam/json
import gleam/otp/actor

pub type DiscordError {
  UnknownAccount
  EmptyOptionWhenRequired
  JsonDecodeError(json.DecodeError)
  InvalidDynamicList(List(decode.DecodeError))
  InvalidFormat(decode.DecodeError)
  WebsocketError(Nil)
  /// When a request to the API fails
  HttpError(hackney.Error)
  /// When the API returns an error, but the request was successful
  GenericHttpError(status_code: Int, body: String)
  ActorError(actor.StartError)
  NilMapEntry(Nil)
  /// Used when a builder dosen't have all of the properties it requires
  BadBuilderProperties(String)
  Unauthorized(String)
}
