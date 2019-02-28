# frozen_string_literal: true

module GameChatBot
  module Alerts
    IGNORE_ALERT_CATEGORIES = %w[scoring_position_extra].freeze

    def output_alerts
      alerts.each do |alert|
        next if posted_alert?(alert)

        @bot.redis.sadd "#{redis_key}_alerts", alert.id

        send_message embed: alert.embed, at: alert.post_at

        send_lineups if alert.description['Lineups posted']

        # Stop trying to update
        @game_over = true if alert.game_over?
      end
    end

    def alerts
      return [] unless @feed.game_data

      @feed.game_data['alerts']
        .reject { |alert| IGNORE_ALERT_CATEGORIES.include?(alert['category']) }
        .map { |alert| embed_for(alert) }
    end

    def posted_alert?(alert)
      @bot.redis.sismember "#{redis_key}_alerts", alert.id
    end

    def embed_for(alert)
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
