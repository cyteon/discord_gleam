import discord_gleam/discord/snowflake
import gleam/json
import gleam/order

pub fn roundtrip_test() {
  let s = "123456789012345678"
  let snowflake = snowflake.from_string(s)

  assert snowflake.to_string(snowflake) == s
}

pub fn decode_string_test() {
  let decoded = json.parse("\"123456789012345678\"", using: snowflake.decoder())

  assert decoded == Ok(snowflake.from_string("123456789012345678"))
}

pub fn decode_int_test() {
  let decoded = json.parse("123456789012345678", using: snowflake.decoder())

  assert decoded == Ok(snowflake.from_string("123456789012345678"))
}

pub fn compare_shorter_test() {
  let a = snowflake.from_string("99")
  let b = snowflake.from_string("100")

  assert snowflake.compare(a, b) == order.Lt
}

pub fn compare_same_len_test() {
  let a = snowflake.from_string("100")
  let b = snowflake.from_string("101")

  assert snowflake.compare(a, b) == order.Lt
}

pub fn compare_eq_test() {
  let a = snowflake.from_string("100")
  let b = snowflake.from_string("100")

  assert snowflake.compare(a, b) == order.Eq
}
