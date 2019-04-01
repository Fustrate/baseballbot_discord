# frozen_string_literal: true

module GameChatBot
  module Embeds
    class StatcastGfx < Color
      include OutputHelpers

      def initialize(item, channel)
        @item = item
        @channel = channel
      end

      def embed
        {
          title: @item['des'],
          description: @item['description_tracking'],
          image: {
            url: @item['data']['url'],
            height: 640,
            width: 640
          },
          color: '999999'.to_i(16)
        }
      end
    end
  end
end
