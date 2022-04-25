# frozen_string_literal: true

module GameChatBot
  module Embeds
    class StrikeoutOrWalk < Play
      def to_h
        {
          title: "#{team_emoji} #{@play.dig('result', 'event')} (#{count})",
          description:,
          color: color.to_i(16),
          footer: resulting_context
        }
      end
    end
  end
end
