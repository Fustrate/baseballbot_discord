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

    protected

    def load_data_from_stats_api(url, interpolations = {})
      date = interpolations[:date] || (Time.now - 7200)

      filename = format(
        url,
        interpolations.merge(
          year: date.year,
          t: Time.now.to_i,
          date: date.strftime('%m/%d/%Y')
        )
      )

      JSON.parse(URI.parse(filename).open.read)
    end

    def names_from_context(event)
      search_for = []

      channel_name = event.channel.name.gsub(/[^a-z]/, ' ')

      search_for << channel_name unless NON_TEAM_CHANNELS.include?(channel_name)

      role_names = event.user.roles.map(&:name).map(&:downcase) - %w[mods]

      search_for + role_names
    end

    def react_to_event(event, reaction)
      event.message.react reaction

      nil
    end
  end
end
