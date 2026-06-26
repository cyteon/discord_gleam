import gleam/dynamic/decode
import gleam/httpc
import gleam/json
import gleam/list
import gleam/otp/actor
import gleam/string

pub type DiscordError {
  JsonDecodeError(json.DecodeError)
  /// The HTTP request itself failed, e.g. due to a network error
  HttpError(httpc.HttpError)
  /// When the API returns an error, but the request was successful
  GenericHttpError(status_code: Int, body: String)
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

    json.UnableToDecode(errs) -> {
      "Unable to decode: "
      <> string.join(list.map(errs, decode_error_to_string), with: ", ")
    }
  }
}

pub fn dynamic_decode_error_to_string(error: decode.DecodeError) -> String {
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
