# frozen_string_literal: true

module BaseballDiscord
  class Bot < Discordrb::Commands::CommandBot
    NON_TEAM_CHANNELS = %w[
      general bot welcome verification discord-options
    ].freeze

    # Discord ID of the rBaseball server
    SERVER_ID = 400_516_567_735_074_817

    def self.parse_date(date)
      return Time.now if date.strip == ''

      Chronic.parse(date)
    end

    def self.parse_time(utc, time_zone: 'America/New_York')
      time_zone = TZInfo::Timezone.get(time_zone) if time_zone.is_a? String

      utc = Time.parse(utc).utc unless utc.is_a? Time

      period = time_zone.period_for_utc(utc)
      with_offset = utc + period.utc_total_offset

      Time.parse "#{with_offset.strftime('%FT%T')} #{period.zone_identifier}"
    end
  end
end
