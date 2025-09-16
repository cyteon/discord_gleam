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