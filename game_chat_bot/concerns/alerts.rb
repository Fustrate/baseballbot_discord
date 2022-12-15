# frozen_string_literal: true

module GameChatBot
  module Alerts
    IGNORE_ALERT_CATEGORIES = %w[scoring_position_extra].freeze

    def output_alerts = alerts_to_post.each { process_alert(_1) }

    def process_alert(alert)
      @bot.redis.sadd "#{redis_key}_alerts", alert['alertId']

      embed = alert_embed_for(alert)

      send_message embed: embed.to_h, at: embed.post_at

      send_lineups if embed.description['Lineups posted']
    end

    def alerts_to_post = (@feed.game_data ? @feed.game_data['alerts'].select { post_alert?(_1) } : [])

    def post_alert?(alert) = !ignore_category?(alert['category']) && !posted?(alert['alertId'])

    def ignore_category?(category) = IGNORE_ALERT_CATEGORIES.include?(category)

    def posted?(alert_id) = @bot.redis.sismember("#{redis_key}_alerts", alert_id)

    def alert_embed_for(alert)
      case alert['category']
      when 'game_over'          then Embeds::EndOfGame.new(alert, self)
      when 'end_of_half_inning' then Embeds::EndOfInning.new(alert, self)
      when 'pitcher_change'     then Embeds::Alert.new(alert, self, title: 'Pitching Change')
      else
        Embeds::Alert.new(alert, self)
      end
    end
  end
end
