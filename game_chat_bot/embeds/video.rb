# frozen_string_literal: true

module GameChatBot
  module Embeds
    # A video highlight from the color feed.
    class Video < Color
      include OutputHelpers

      def to_h
        {
          title: @item.dig('data', 'headline'),
          description: @item.dig('data', 'url', 0, '_'),
          video: video,
          thumbnail: thumbnail,
          color: '999999'.to_i(16)
        }
      end

      def video
        {
          url: @item.dig('data', 'url', 0, '_'),
          height: 720,
          width: 1280
        }
      end

      def thumbnail
        thumbnail_url = @item.dig('data', 'thumbnails', 'thumb')
          .find { |thumb| thumb['type'] == 13 }
          &.dig('_')

        {
          url: thumbnail_url,
          height: 180,
          width: 320
        }
      end
    end
  end
end
