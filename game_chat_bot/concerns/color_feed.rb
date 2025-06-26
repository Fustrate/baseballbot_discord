# frozen_string_literal: true

module GameChatBot
  module ColorFeed
    def process_color_feed
      color_feed_items.each do |item|
        @bot.redis.sadd "#{redis_key}_color", item.dig('data', 'mediaPlaybackId') || item['guid']

        embed = color_feed_embed_for(item)

        next unless embed

        send_message embed: embed.to_h
      end
    end

    def color_feed_items
      return [] unless @color_feed&.items

      @color_feed.items.first(5).reject { posted_color_feed_item?(it) }
    end

    def posted_color_feed_item?(item)
      # Non-play videos have a guid of "video_undefined"
      @bot.redis.sismember "#{redis_key}_color", item.dig('data', 'mediaPlaybackId') || item['guid']
    end

    def color_feed_embed_for(item)
      case item['group']
      when 'statcastGFX'
        Embeds::StatcastGfx.new(item, self)
      when 'social'
        Embeds::Social.new(item, self)
      when 'video'
        Embeds::Video.new(item, self)
      end
    end
  end
end
