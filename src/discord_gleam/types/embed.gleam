import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}

pub type EmbedImage {
  EmbedImage(url: String)
}

pub type EmbedThumbnail {
  EmbedThumbnail(url: String)
}

pub type EmbedFooter {
  EmbedFooter(text: String, icon_url: Option(String))
}

pub type EmbedAuthor {
  EmbedAuthor(name: String, url: Option(String), icon_url: Option(String))
}

pub type EmbedField {
  EmbedField(name: String, value: String, inline: Bool)
}

pub type Embed {
  Embed(
    title: String,
    description: String,
    color: Int,
    url: Option(String),
    image: Option(EmbedImage),
    thumbnail: Option(EmbedThumbnail),
    footer: Option(EmbedFooter),
    author: Option(EmbedAuthor),
    fields: List(EmbedField),
  )
}

pub fn new(
  title title: String,
  description description: String,
  color color: Int,
) -> Embed {
  Embed(
    title: title,
    description: description,
    color: color,
    url: None,
    image: None,
    thumbnail: None,
    footer: None,
    author: None,
    fields: [],
  )
}

pub fn set_url(embed: Embed, url url: String) -> Embed {
  Embed(..embed, url: Some(url))
}

pub fn set_image(embed: Embed, image_url image_url: String) -> Embed {
  Embed(..embed, image: Some(EmbedImage(url: image_url)))
}

pub fn set_thumbnail(
  embed: Embed,
  thumbnail_url thumbnail_url: String,
) -> Embed {
  Embed(..embed, thumbnail: Some(EmbedThumbnail(url: thumbnail_url)))
}

pub fn set_footer(
  embed: Embed,
  text text: String,
  icon_url icon_url: Option(String),
) -> Embed {
  Embed(..embed, footer: Some(EmbedFooter(text: text, icon_url: icon_url)))
}

pub fn set_author(
  embed: Embed,
  name name: String,
  url url: Option(String),
  icon_url icon_url: Option(String),
) -> Embed {
  Embed(
    ..embed,
    author: Some(EmbedAuthor(name: name, url: url, icon_url: icon_url)),
  )
}

pub fn add_field(
  embed: Embed,
  name name: String,
  value value: String,
  inline inline: Bool,
) -> Embed {
  let new_field = EmbedField(name: name, value: value, inline: inline)
  Embed(..embed, fields: list.append(embed.fields, [new_field]))
}

pub fn embed_to_json(embed: Embed) -> json.Json {
  let base_fields = [
    #("title", json.string(embed.title)),
    #("description", json.string(embed.description)),
    #("color", json.int(embed.color)),
  ]

  let with_url = case embed.url {
    Some(url) -> list.append(base_fields, [#("url", json.string(url))])
    None -> base_fields
  }

  let with_image = case embed.image {
    Some(image) -> {
      list.append(with_url, [
        #("image", json.object([#("url", json.string(image.url))])),
      ])
    }
    None -> with_url
  }

  let with_thumbnail = case embed.thumbnail {
    Some(thumb) -> {
      list.append(with_image, [
        #("thumbnail", json.object([#("url", json.string(thumb.url))])),
      ])
    }
    None -> with_image
  }

  let with_footer = case embed.footer {
    Some(footer) -> {
      let footer_obj = [#("text", json.string(footer.text))]
      let footer_obj = case footer.icon_url {
        Some(icon) ->
          list.append(footer_obj, [#("icon_url", json.string(icon))])
        None -> footer_obj
      }
      list.append(with_thumbnail, [#("footer", json.object(footer_obj))])
    }
    None -> with_thumbnail
  }

  let with_author = case embed.author {
    Some(author) -> {
      let author_obj = [#("name", json.string(author.name))]
      let author_obj = case author.url {
        Some(url) -> list.append(author_obj, [#("url", json.string(url))])
        None -> author_obj
      }
      let author_obj = case author.icon_url {
        Some(icon) ->
          list.append(author_obj, [#("icon_url", json.string(icon))])
        None -> author_obj
      }
      list.append(with_footer, [#("author", json.object(author_obj))])
    }
    None -> with_footer
  }

  let with_fields = case embed.fields {
    [] -> with_author
    fields -> {
      let fields_json =
        list.map(fields, fn(field) {
          json.object([
            #("name", json.string(field.name)),
            #("value", json.string(field.value)),
            #("inline", json.bool(field.inline)),
          ])
        })
      list.append(with_author, [
        #("fields", json.array(fields_json, of: fn(x) { x })),
      ])
    }
  }

  json.object(with_fields)
}
