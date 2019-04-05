# frozen_string_literal: true

module GameChatBot
  module Alerts
    IGNORE_ALERT_CATEGORIES = %w[scoring_position_extra].freeze

    def output_alerts
      alerts.each do |alert|
        @bot.redis.sadd "#{redis_key}_alerts", alert['alertId']

        embed = alert_embed_for(alert)

        send_message embed: embed.to_h, at: embed.post_at

        send_lineups if embed.description['Lineups posted']
      end
    end

    def alerts
      return [] unless @feed.game_data

      @feed.game_data['alerts'].select { |alert| post_alert?(alert) }
    end

    def post_alert?(alert)
      return false if IGNORE_ALERT_CATEGORIES.include?(alert['category'])

      !@bot.redis.sismember "#{redis_key}_alerts", alert['alertId']
    end

    def alert_embed_for(alert)
      case alert['category']
      when 'game_over'
        Embeds::EndOfGame.new(alert, self)
      when 'end_of_half_inning'
        Embeds::EndOfInning.new(alert, self)
      when 'pitcher_change'
        Embeds::Alert.new(alert, self, title: 'Pitching Change')
      else
        Embeds::Alert.new(alert, self)
      end
    end
  end
end
