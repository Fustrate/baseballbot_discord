# frozen_string_literal: true

require 'terrapin'

module GameChatBot
  module Embeds
    # A statcast graphic from the color feed.
    class StatcastGfx < Color
      include OutputHelpers

      STATCAST_IMAGE_DIMENSIONS = {
        'playdiagram' => [640, 640],
        'sideways' => [640, 265]
      }.freeze

      def to_h
        {
          title: @item.dig('data', 'details', 'des'),
          description: description,
          image: image
        }
      end

      def description() = @item.dig('data', 'details', 'description_tracking').gsub(%r{<b>(.*?)</b>}, '**\1**')

      def image
        width, height = STATCAST_IMAGE_DIMENSIONS[@item['id']] || [640, 640]

        {
          url: @item.dig('data', 'url'),
          height: height,
          width: width
        }
      end
    end
  end
end
