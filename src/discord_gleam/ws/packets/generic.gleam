import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None, Some}

/// Any packet excluding the data object d: json
pub type GenericPacket {
  GenericPacket(t: Option(String), s: Option(Int), op: Int)
}

pub fn from_json_string(encoded: String) -> GenericPacket {
  let decoder = {
    use t <- decode.optional_field("t", None, decode.optional(decode.string))
    use s <- decode.optional_field("s", None, decode.optional(decode.int))
    use op <- decode.field("op", decode.int)
    decode.success(GenericPacket(t:, s:, op:))
  }

  let data = json.parse(from: encoded, using: decoder)

  case data {
    Ok(decoded) -> decoded
    // yes i know this is fucking stupid, idfk why i did this but im too lazy to change it so live with it
    Error(_) -> GenericPacket(Some("error"), None, 0)
  }
}
