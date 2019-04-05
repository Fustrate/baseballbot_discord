# frozen_string_literal: true

require 'terrapin'

module GameChatBot
  module Embeds
    class StatcastGfx < Color
      include OutputHelpers

      def initialize(item, channel)
        @item = item
        @channel = channel

        # download_image
      end

      def to_h
        {
          title: @item.dig('data', 'details', 'des'),
          color: '999999'.to_i(16),
          description: <<~DESCRIPTION
            #{@item.dig('data', 'details', 'description_tracking')}

            #{@item['data']['url']}
          DESCRIPTION
        }
      end

      # def local_url
      #   "https://baseballbot.io/system/mlb/#{@item['guid']}.png"
      # end

      # def download_image
      #   command = Terrapin::CommandLine.new('wget', '-O :local :remote')

      #   output_dir = '/home/baseballbot/apps/baseballbot.io/shared/public/system/mlb'

      #   command.run(
      #     remote: @item['data']['url'],
      #     local: "#{output_dir}/#{@item['guid']}.png"
      #   )
      # end
    end
  end
end
