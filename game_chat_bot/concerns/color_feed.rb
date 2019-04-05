# frozen_string_literal: true

module GameChatBot
  module ColorFeed
    def process_color_feed
      color_feed_items.each do |item|
        @bot.redis.sadd "#{redis_key}_color", item['guid']

        embed = color_feed_embed_for(item)

        next unless embed

        send_message embed: embed.to_h
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

    def color_feed_embed_for(item)
      case item['group']
      when 'statcastGFX'
        send_message embed: {
          title: item.dig('data', 'details', 'description_tracking')
            .gsub(%r{<b>(.*?)</b>}, '*\1*'),
          description: item.dig('data', 'url')
        }

        send_message embed: {
          title: item.dig('data', 'details', 'des'),
          description: item.dig('data', 'url'),
          image: {
            url: item.dig('data', 'url'),
            height: 640,
            width: 640
          }
        }

        Embeds::StatcastGfx.new(item)
      when 'social'
        Embeds::Social.new(item)
      when 'video'
        Embeds::Video.new(item)
      end
    end
  end
end
