# frozen_string_literal: true

module GameChatBot
  # Keeps track of all team logo emojis for the /r/baseball discord server.
  module Emoji
    TEAM_EMOJI = YAML.safe_load_file(File.expand_path("#{__dir__}/../config/emoji.yml"))

    def self.team_emoji(abbreviation) = "<#{TEAM_EMOJI[abbreviation.downcase]}>"
  end
end
