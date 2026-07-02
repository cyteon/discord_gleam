pub type GatewayState {
  GatewayState(sequence: Int, session_id: String, resume_gateway_url: String)
}

pub fn new() -> GatewayState {
  GatewayState(
    sequence: 0,
    session_id: "",
    resume_gateway_url: "gateway.discord.gg",
  )
}
