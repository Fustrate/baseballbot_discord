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
        send_message embed: Embeds::StatcastGfx.new(item).to_h
      when 'social'
        send_message embed: Embeds::Social.new(item).to_h
      when 'video'
        send_video_message(item)
      end
    end

    def send_video_message(item)
      thumbnail = item.dig('data', 'thumbnails', 'thumb')
        .select { |thumb| thumb['type'] == 13 }

      send_message embed: {
        title: item.dig('data', 'headline'),
        description: item.dig('data', 'url', 0, '_'),
        video: {
          url: item.dig('data', 'url', 0, '_'),
          height: 720,
          width: 1280
        },
        thumbnail: {
          url: thumbnail['_'],
          height: 180,
          width: 320
        }
      }
    end
  end
end
