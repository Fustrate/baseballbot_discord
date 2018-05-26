# frozen_string_literal: true

module BaseballDiscord
  class Command
    def self.run(event, *args)
      new.run(event, *args)
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

      unless BaseballDiscord::Bot::NON_TEAM_CHANNELS.include?(channel_name)
        search_for << channel_name
      end

      role_names = event.user.roles.map(&:name).map(&:downcase) - %w[mods]

      search_for + role_names
    end

    def react_to_event(event, reaction)
      event.message.react reaction

      nil
    end
  end
end
