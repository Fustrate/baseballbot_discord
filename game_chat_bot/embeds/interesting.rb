# frozen_string_literal: true

module GameChatBot
  module Embeds
    class Interesting
      def initialize(play, channel, description)
        @play = play
        @channel = channel
        @description = description
      end

      def embed
        {
          description: @description,
          color: '999999'.to_i(16)
        }
      end

      def post_at
        Time.parse(@play['playEndTime']) + 15
      end
    end
  end
end
