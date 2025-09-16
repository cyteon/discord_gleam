//// Custom handler types for customizing Discord bot behavior
//// This module provides types and utilities for creating custom loop and close handlers

import stratus

/// Custom loop handler function type
/// Receives the current state, incoming message, and connection
/// Should return a stratus continuation action
pub type CustomLoopHandler(state) = fn(state, stratus.Message, stratus.Connection) -> stratus.Next(state)

/// Custom close handler function type  
/// Receives the final state when the connection closes
/// Can perform cleanup or reconnection logic
pub type CustomCloseHandler(state) = fn(state) -> Nil

/// Configuration for custom handlers
pub type CustomHandlers(state) {
  CustomHandlers(
    loop: CustomLoopHandler(state),
    close: CustomCloseHandler(state)
  )
}

/// Helper function to create a simple pass-through loop handler that just continues
/// This can be useful as a starting point for customization
pub fn default_continue_loop_handler(state: s, _msg: stratus.Message, _conn: stratus.Connection) -> stratus.Next(s) {
  stratus.continue(state)
}

/// Helper function to create a simple no-op close handler
/// This can be useful when you only want to customize the loop handler
pub fn default_noop_close_handler(_state: s) -> Nil {
  Nil
}