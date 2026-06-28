import discord_gleam/discord/snowflake.{type Snowflake}
import discord_gleam/types/emoji
import discord_gleam/types/role
import gleam/dynamic/decode
import gleam/option.{type Option, None}

/// See https://discord.com/developers/docs/resources/guild#guild-resource
pub type Guild {
  UnavailableGuild(id: Snowflake(snowflake.Guild), unavailable: Bool)
  Guild(
    id: Snowflake(snowflake.Guild),
    name: String,
    icon: Option(String),
    icon_hash: Option(String),
    splash: Option(String),
    discovery_splash: Option(String),
    // should almost always be false
    owner: Option(Bool),
    owner_id: Snowflake(snowflake.User),
    permissions: Option(String),
    afk_channel_id: Option(Snowflake(snowflake.Channel)),
    afk_timeout: Int,
    widget_enabled: Option(Bool),
    widget_channel_id: Option(Snowflake(snowflake.Channel)),
    verification_level: Int,
    default_message_notifications: Int,
    explicit_content_filter: Int,
    roles: List(role.Role),
    emojis: List(emoji.Emoji),
    features: List(String),
    mfa_level: Int,
    application_id: Option(Snowflake(snowflake.Application)),
    system_channel_id: Option(Snowflake(snowflake.Channel)),
    system_channel_flags: Int,
    rules_channel_id: Option(Snowflake(snowflake.Channel)),
    max_presences: Option(Int),
    max_members: Option(Int),
    vanity_url_code: Option(String),
    description: Option(String),
    banner: Option(String),
    premium_tier: Int,
    premium_subscription_count: Option(Int),
    preferred_locale: String,
    public_updates_channel_id: Option(Snowflake(snowflake.Channel)),
    max_video_channel_users: Option(Int),
    max_stage_video_channel_users: Option(Int),
    approximate_member_count: Option(Int),
    approximate_presence_count: Option(Int),
    // welcome_screen: Option(WelcomeScreen), todo: implement
    nsfw_level: Int,
    // stickers: List(emoji.Sticker), todo: implement
    premium_progress_bar_enabled: Bool,
    safety_alerts_channel_id: Option(Snowflake(snowflake.Channel)),
    // incidents_data: Option(IncidentsData),
  )
}

pub fn json_decoder() -> decode.Decoder(Guild) {
  use id <- decode.field("id", snowflake.decoder())
  use unavailable <- decode.optional_field("unavailable", False, decode.bool)

  case unavailable {
    True -> decode.success(UnavailableGuild(id:, unavailable:))
    False -> {
      use name <- decode.field("name", decode.string)

      use icon <- decode.optional_field(
        "icon",
        None,
        decode.optional(decode.string),
      )

      use icon_hash <- decode.optional_field(
        "icon_hash",
        None,
        decode.optional(decode.string),
      )

      use splash <- decode.optional_field(
        "splash",
        None,
        decode.optional(decode.string),
      )

      use discovery_splash <- decode.optional_field(
        "discovery_splash",
        None,
        decode.optional(decode.string),
      )

      use owner <- decode.optional_field(
        "owner",
        None,
        decode.optional(decode.bool),
      )

      use owner_id <- decode.field("owner_id", snowflake.decoder())

      use permissions <- decode.optional_field(
        "permissions",
        None,
        decode.optional(decode.string),
      )

      use afk_channel_id <- decode.optional_field(
        "afk_channel_id",
        None,
        decode.optional(snowflake.decoder()),
      )

      use afk_timeout <- decode.field("afk_timeout", decode.int)

      use widget_enabled <- decode.optional_field(
        "widget_enabled",
        None,
        decode.optional(decode.bool),
      )

      use widget_channel_id <- decode.optional_field(
        "widget_channel_id",
        None,
        decode.optional(snowflake.decoder()),
      )

      use verification_level <- decode.field("verification_level", decode.int)

      use default_message_notifications <- decode.field(
        "default_message_notifications",
        decode.int,
      )

      use explicit_content_filter <- decode.field(
        "explicit_content_filter",
        decode.int,
      )

      use roles <- decode.field("roles", decode.list(role.json_decoder()))

      use emojis <- decode.field("emojis", decode.list(emoji.json_decoder()))

      use features <- decode.field("features", decode.list(decode.string))

      use mfa_level <- decode.field("mfa_level", decode.int)

      use application_id <- decode.optional_field(
        "application_id",
        None,
        decode.optional(snowflake.decoder()),
      )

      use system_channel_id <- decode.optional_field(
        "system_channel_id",
        None,
        decode.optional(snowflake.decoder()),
      )

      use system_channel_flags <- decode.field(
        "system_channel_flags",
        decode.int,
      )

      use rules_channel_id <- decode.optional_field(
        "rules_channel_id",
        None,
        decode.optional(snowflake.decoder()),
      )

      use max_presences <- decode.optional_field(
        "max_presences",
        None,
        decode.optional(decode.int),
      )

      use max_members <- decode.optional_field(
        "max_members",
        None,
        decode.optional(decode.int),
      )

      use vanity_url_code <- decode.optional_field(
        "vanity_url_code",
        None,
        decode.optional(decode.string),
      )

      use description <- decode.optional_field(
        "description",
        None,
        decode.optional(decode.string),
      )

      use banner <- decode.optional_field(
        "banner",
        None,
        decode.optional(decode.string),
      )

      use premium_tier <- decode.field("premium_tier", decode.int)

      use premium_subscription_count <- decode.optional_field(
        "premium_subscription_count",
        None,
        decode.optional(decode.int),
      )

      use preferred_locale <- decode.field("preferred_locale", decode.string)

      use public_updates_channel_id <- decode.optional_field(
        "public_updates_channel_id",
        None,
        decode.optional(snowflake.decoder()),
      )

      use max_video_channel_users <- decode.optional_field(
        "max_video_channel_users",
        None,
        decode.optional(decode.int),
      )

      use max_stage_video_channel_users <- decode.optional_field(
        "max_stage_video_channel_users",
        None,
        decode.optional(decode.int),
      )

      use approximate_member_count <- decode.optional_field(
        "approximate_member_count",
        None,
        decode.optional(decode.int),
      )

      use approximate_presence_count <- decode.optional_field(
        "approximate_presence_count",
        None,
        decode.optional(decode.int),
      )

      // todo: implement welcome_screen

      use nsfw_level <- decode.field("nsfw_level", decode.int)

      // todo: implement stickers

      use premium_progress_bar_enabled <- decode.field(
        "premium_progress_bar_enabled",
        decode.bool,
      )

      use safety_alerts_channel_id <- decode.optional_field(
        "safety_alerts_channel_id",
        None,
        decode.optional(snowflake.decoder()),
      )

      // todo: implement incidents_data

      decode.success(Guild(
        id:,
        name:,
        icon:,
        icon_hash:,
        splash:,
        discovery_splash:,
        owner:,
        owner_id:,
        permissions:,
        afk_channel_id:,
        afk_timeout:,
        widget_enabled:,
        widget_channel_id:,
        verification_level:,
        default_message_notifications:,
        explicit_content_filter:,
        roles:,
        emojis:,
        features:,
        mfa_level:,
        application_id:,
        system_channel_id:,
        system_channel_flags:,
        rules_channel_id:,
        max_presences:,
        max_members:,
        vanity_url_code:,
        description:,
        banner:,
        premium_tier:,
        premium_subscription_count:,
        preferred_locale:,
        public_updates_channel_id:,
        max_video_channel_users:,
        max_stage_video_channel_users:,
        approximate_member_count:,
        approximate_presence_count:,
        // welcome_screen:,
        nsfw_level:,
        // stickers:,
        premium_progress_bar_enabled:,
        safety_alerts_channel_id:,
        // incidents_data:,
      ))
    }
  }
}
