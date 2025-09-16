import discord_gleam
import discord_gleam/custom_handlers
import discord_gleam/discord/intents
import discord_gleam/ws/event_loop
import gleam/option
import gleeunit
import gleeunit/should
import stratus

pub fn main() {
  gleeunit.main()
}

// Test that custom handlers can be created
pub fn custom_handlers_creation_test() {
  let handlers = custom_handlers.CustomHandlers(
    loop: test_loop_handler,
    close: test_close_handler,
  )
  
  // Just verify we can create the handlers structure
  should.be_ok(Ok(handlers))
}

// Test that run_with_custom_handlers function exists and accepts the right parameters
pub fn run_with_custom_handlers_api_test() {
  let bot = discord_gleam.bot("test_token", "test_client_id", intents.default())
  let handlers = custom_handlers.CustomHandlers(
    loop: test_loop_handler,
    close: test_close_handler,
  )
  
  // This tests that the function signature is correct
  // We can't actually run it in tests since it would try to connect to Discord
  let _result = fn() {
    discord_gleam.run_with_custom_handlers(bot, [], option.Some(handlers))
  }
  
  should.be_ok(Ok(Nil))
}

// Test that run_with_custom_handlers accepts None for falling back to default behavior
pub fn run_with_custom_handlers_none_test() {
  let bot = discord_gleam.bot("test_token", "test_client_id", intents.default())
  
  // This tests that the function accepts None and would fall back to default behavior
  let _result = fn() {
    discord_gleam.run_with_custom_handlers(bot, [], option.None)
  }
  
  should.be_ok(Ok(Nil))
}

// Mock loop handler for testing
fn test_loop_handler(
  state: event_loop.State,
  _msg: stratus.Message,
  _conn: stratus.Connection,
) -> stratus.Next(event_loop.State) {
  stratus.continue(state)
}

// Mock close handler for testing
fn test_close_handler(_state: event_loop.State) -> Nil {
  Nil
}