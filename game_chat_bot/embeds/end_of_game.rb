# frozen_string_literal: true

module GameChatBot
  module Embeds
    class EndOfGame < Alert
      def to_h
        {
          title: 'Game Over',
          color: 'ffffff'.to_i(16),
          description: <<~DESCRIPTION
            #{description}

            ```
            #{@channel.rhe_table}
            ```
          DESCRIPTION
        }
      end
    end
  end
end
