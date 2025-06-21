import gleam/dynamic
import gleam/dynamic/decode
import gleam/hackney
import gleam/json
import gleam/list
import gleam/otp/actor
import gleam/string

pub type DiscordError {
  UnknownAccount
  EmptyOptionWhenRequired
  JsonDecodeError(json.DecodeError)
  InvalidDynamicList(List(dynamic.DecodeError))
  InvalidFormat(dynamic.DecodeError)
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

pub fn json_decode_error_to_string(error: json.DecodeError) -> String {
  case error {
    json.UnexpectedEndOfInput -> "Unexpected end of input"

    json.UnexpectedByte(byte) -> {
      "Unexpected byte: " <> byte
    }

    json.UnexpectedSequence(sequence) -> {
      "Unexpected sequence: " <> sequence
    }

    json.UnexpectedFormat(errs) -> {
      "Unable to decode: "
      <> string.join(list.map(errs, dynamic_decode_error_to_string), with: ", ")
    }

    json.UnableToDecode(errs) -> {
      "Unable to decode: "
      <> string.join(list.map(errs, decode_error_to_string), with: ", ")
    }
  }
}

pub fn dynamic_decode_error_to_string(error: dynamic.DecodeError) -> String {
  "Expected "
  <> error.expected
  <> ", but found "
  <> error.found
  <> " at "
  <> string.join(error.path, with: ".")
}

pub fn decode_error_to_string(error: decode.DecodeError) -> String {
  "Expected "
  <> error.expected
  <> ", but found "
  <> error.found
  <> " at "
  <> string.join(error.path, with: ".")
}
