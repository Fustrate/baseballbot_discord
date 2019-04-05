# frozen_string_literal: true

module GameChatBot
  module Embeds
    class Social < Color
      def to_h
        {
          url: "https://twitter.com/#{user['screen_name']}/status/#{tweet['id']}",
          author: tweet_author(user),
          description: tweet['full_text'],
          color: '109799'.to_i(16)
        }
      end

      def tweet_author(user)
        {
          name: "#{user.dig['name']} (#{user['screen_name']})",
          url: "https://twitter.com/#{user['screen_name']}",
          icon_url: user['profile_image_url_https']
        }
      end
    end
  end
end
