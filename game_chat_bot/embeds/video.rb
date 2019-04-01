# frozen_string_literal: true

module GameChatBot
  module Embeds
    class Video < Color
      include OutputHelpers

      def initialize(item, channel)
        @item = item
        @channel = channel
      end

      def to_h
        {
          title: @item.dig('data', 'title'),
          video: {
            url: @item.dig('data', 'url', 0, '_'),
            height: 720,
            width: 1280
          },
          color: '999999'.to_i(16)
        }
      end
    end
  end
end
