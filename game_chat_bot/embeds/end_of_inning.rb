# frozen_string_literal: true

module GameChatBot
  module Embeds
    class EndOfInning < Alert
      def to_h
        {
          title: @channel.line_score_inning,
          color: '109799'.to_i(16),
          fields: due_up_next_inning,
          description: <<~DESCRIPTION
            ```
            #{@channel.rhe_table}
            ```
          DESCRIPTION
        }
      end

      protected

      def due_up_next_inning
        players = @channel.feed.linescore['offense']
          .values_at('batter', 'onDeck', 'inHole')

        [
          { name: 'At Bat', value: players[0]['fullName'], inline: true },
          { name: 'On Deck', value: players[1]['fullName'], inline: true },
          { name: 'In the Hole', value: players[2]['fullName'], inline: true }
        ]
      end
    end
  end
end
