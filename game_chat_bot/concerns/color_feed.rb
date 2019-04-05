# frozen_string_literal: true

module GameChatBot
  module ColorFeed
    def process_color_feed
      color_feed_items.each do |item|
        @bot.redis.sadd "#{redis_key}_color", item['guid']

        send_color_feed_embed_for(item)
      end
    end

    def color_feed_items
      return [] unless @color_feed.items

      @color_feed.items
        .first(5)
        .reject { |item| posted_color_feed_item?(item) }
    end

    def posted_color_feed_item?(item)
      @bot.redis.sismember "#{redis_key}_color", item['guid']
    end

    def send_color_feed_embed_for(item)
      case item['group']
      when 'statcastGFX'
        send_statcast_message(item)
      when 'social'
        send_social_message(item)
      when 'video'
        send_message item.dig('data', 'url', 0, '_')
      end
    end

    def send_statcast_message(item)
      send_message <<~DESCRIPTION
        #{item.dig('data', 'details', 'description_tracking')}

        #{item.dig('data', 'url')}
      DESCRIPTION
    end

    def send_social_message(item)
      tweet = item.dig('data', 'tweet')
      username = tweet.dig('user', 'screen_name')

      send_message "https://twitter.com/#{username}/status/#{tweet['id']}"
    end
  end
end
