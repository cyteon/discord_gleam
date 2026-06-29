//// Snowflakes is discord's type for unique identifiers. \
//// They are 64-bit unsigned integers, represented as strings. \
//// See https://discord.com/developers/docs/reference#snowflakes

import gleam/dynamic/decode
import gleam/int
import gleam/order
import gleam/string

/// We are representing Discord's snowflake as a string
pub opaque type Snowflake(kind) {
  Snowflake(value: String)
}

pub type User

pub type Guild

pub type Channel

pub type Message

pub type Role

pub type Application

pub type Interaction

pub type Emoji

pub type Sku

pub type Webhook

pub fn from_string(value: String) -> Snowflake(kind) {
  Snowflake(value)
}

pub fn to_string(snowflake: Snowflake(kind)) -> String {
  snowflake.value
}

/// API should not give a int, but incase it does we will convert to string.
pub fn decoder() -> decode.Decoder(Snowflake(kind)) {
  decode.one_of(decode.string, [decode.int |> decode.map(int.to_string)])
  |> decode.map(Snowflake)
}

pub fn compare(a: Snowflake(kind), b: Snowflake(kind)) -> order.Order {
  case int.compare(string.length(a.value), string.length(b.value)) {
    order.Eq -> string.compare(a.value, b.value)
    other -> other
  }
}
