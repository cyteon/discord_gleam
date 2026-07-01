import discord_gleam/types/embed
import gleam/json
import gleam/option.{None, Some}

pub fn new_is_empty_test() {
  let embed = embed.new("", "", 0)

  assert embed.url == None
  assert embed.image == None
  assert embed.thumbnail == None
  assert embed.footer == None
  assert embed.author == None
  assert embed.fields == []
}

pub fn add_field_test() {
  let embed =
    embed.new("", "", 0)
    |> embed.add_field("name", value: "value", inline: False)

  assert embed.fields == [embed.EmbedField("name", "value", inline: False)]
}

pub fn embed_to_json_test() {
  let embed =
    embed.new("title", "description", 0)
    |> embed.set_url("https://example.com")
    |> embed.set_image("https://example.com/image.png")
    |> embed.set_thumbnail("https://example.com/thumbnail.png")
    |> embed.set_footer(
      "footer text",
      icon_url: Some("https://example.com/footer_icon.png"),
    )
    |> embed.set_author(
      "author name",
      url: Some("https://example.com/author"),
      icon_url: Some("https://example.com/author_icon.png"),
    )
    |> embed.add_field("field name", value: "field value", inline: True)

  let json = embed.embed_to_json(embed)

  assert json
    == json.object([
      #("title", json.string("title")),
      #("description", json.string("description")),
      #("color", json.int(0)),
      #("url", json.string("https://example.com")),
      #(
        "image",
        json.object([#("url", json.string("https://example.com/image.png"))]),
      ),
      #(
        "thumbnail",
        json.object([#("url", json.string("https://example.com/thumbnail.png"))]),
      ),
      #(
        "footer",
        json.object([
          #("text", json.string("footer text")),
          #("icon_url", json.string("https://example.com/footer_icon.png")),
        ]),
      ),
      #(
        "author",
        json.object([
          #("name", json.string("author name")),
          #("url", json.string("https://example.com/author")),
          #("icon_url", json.string("https://example.com/author_icon.png")),
        ]),
      ),
      #(
        "fields",
        json.array(
          [
            json.object([
              #("name", json.string("field name")),
              #("value", json.string("field value")),
              #("inline", json.bool(True)),
            ]),
          ],
          of: fn(x) { x },
        ),
      ),
    ])
}

pub fn json_decode_test() {
  let object =
    "{\"title\":\"title\",\"description\":\"description\",\"color\":0,\"url\":\"https://example.com\",\"image\":{\"url\":\"https://example.com/image.png\"},\"thumbnail\":{\"url\":\"https://example.com/thumbnail.png\"},\"footer\":{\"text\":\"footer text\",\"icon_url\":\"https://example.com/footer_icon.png\"},\"author\":{\"name\":\"author name\",\"url\":\"https://example.com/author\",\"icon_url\":\"https://example.com/author_icon.png\"},\"fields\":[{\"name\":\"field name\",\"value\":\"field value\",\"inline\":true}]}"

  let result = json.parse(object, embed.json_decoder())

  let assert Ok(embed) = result

  assert embed.title == "title"
  assert embed.description == "description"
  assert embed.color == 0
  assert embed.url == Some("https://example.com")
  assert embed.image == Some(embed.EmbedImage("https://example.com/image.png"))
  assert embed.thumbnail
    == Some(embed.EmbedThumbnail("https://example.com/thumbnail.png"))
  assert embed.footer
    == Some(embed.EmbedFooter(
      "footer text",
      Some("https://example.com/footer_icon.png"),
    ))
  assert embed.author
    == Some(embed.EmbedAuthor(
      "author name",
      Some("https://example.com/author"),
      Some("https://example.com/author_icon.png"),
    ))
  assert embed.fields
    == [embed.EmbedField("field name", "field value", inline: True)]
}
