import discord_gleam/discord/intents

pub fn no_intents_test() {
  assert intents.intents_to_bitfield(intents.none()) == 0
}

pub fn default_intents_test() {
  assert intents.intents_to_bitfield(intents.default()) == 13_825
}

pub fn default_with_message_contents_intents_test() {
  assert intents.intents_to_bitfield(intents.default_with_message_intent())
    == 46_593
}

pub fn all_intents_test() {
  assert intents.intents_to_bitfield(intents.all()) == 53_608_447
}
