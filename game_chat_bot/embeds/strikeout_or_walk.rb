# frozen_string_literal: true

module GameChatBot
  module Embeds
    class StrikeoutOrWalk < Play
      def embed
        {
          title: "#{team_emoji} #{type} (#{count})",
          description: description,
          color: color,
          footer: resulting_context
        }
      end
    end
  end
end
