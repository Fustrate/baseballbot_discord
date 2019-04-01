# frozen_string_literal: true

module GameChatBot
  module Embeds
    class Alert
      include OutputHelpers

      def initialize(alert, channel, title: nil)
        @alert = alert
        @channel = channel
        @title = title
      end

      def id
        @alert['alertId']
      end

      def embed
        {
          title: @title || titleize(@alert['category']),
          description: description,
          color: '109799'.to_i(16)
        }
      end

      def post_at
        Time.now + 15
      end

      def description
        # Get rid of the "In Los Angeles:" part that's in every description
        @description ||= @alert['description'].gsub(/\Ain [a-z\. ]+: /i, '')
      end
    end
  end
end
