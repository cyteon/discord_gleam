//// Snowflakes is discord's type for unique identifiers. \
//// They are 64-bit unsigned integers, represented as strings. \
//// See https://discord.com/developers/docs/reference#snowflakes

import gleam/dynamic/decode
import gleam/int

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

pub fn from_string(value: String) -> Snowflake(kind) {
  Snowflake(value)
}

pub fn to_string(snowflake: Snowflake(kind)) -> String {
  snowflake.value
}

/// API should not give a int, but incase it does we will convert to string.
pub fn decoder() {
  decode.one_of(decode.string, [decode.int |> decode.map(int.to_string)])
  |> decode.map(Snowflake)
}
