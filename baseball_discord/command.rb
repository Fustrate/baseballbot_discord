# frozen_string_literal: true

module BaseballDiscord
  class Command
    def self.run(event, *args)
      new(event, *args).run
    end

    def initialize(event, *args)
      @event = event
      @args = args

      log event.message.content
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

    def log(message, level: :info)
      @log_tags ||= "[#{@event.message.id}] [#{@event.user.distinct}]"

      @event.bot.logger.add level, "#{@log_tags} #{message}"
    end

    def names_from_context
      search_for = []

      channel_name = @event.channel.name.gsub(/[^a-z]/, ' ')

      unless BaseballDiscord::Bot::NON_TEAM_CHANNELS.include?(channel_name)
        search_for << channel_name
      end

      role_names = @event.user.roles.map(&:name).map(&:downcase) -
                   BaseballDiscord::Bot::NON_TEAM_ROLES

      search_for + role_names
    end

    def react_to_message(reaction)
      @event.message.react reaction

      nil
    end
  end
end
