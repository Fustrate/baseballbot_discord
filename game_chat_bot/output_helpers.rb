# frozen_string_literal: true

module GameChatBot
  module OutputHelpers
    def squish(text)
      text.gsub(/\s{2,}/, ' ').strip
    end

    def titleize(text)
      text&.tr('_', ' ')&.gsub(/\b[a-z]/, &:capitalize)
    end

    def format_table(table)
      "```\n#{table}\n```"
    end
  end
end
