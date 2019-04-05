# frozen_string_literal: true

module GameChatBot
  module Embeds
    class Color
      include OutputHelpers

      def initialize(item, channel)
        @item = item
        @channel = channel
      end
    end
  end
end
