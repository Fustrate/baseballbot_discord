# frozen_string_literal: true

module BaseballDiscord
  class Command
    LOG_LEVELS = %i[debug info warn error fatal unknown].freeze

    attr_reader :event, :args

    def initialize(event, *args)
      @event = event
      @args = args

      log event.message.content if event.respond_to?(:message)
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

    def log(str, level: :info)
      @log_tags ||= "[#{message.id}] [#{user.distinct}]"

      bot.logger.add LOG_LEVELS.index(level), "#{@log_tags} #{str}"
    end

    def names_from_context
      search_for = []

      channel_name = channel.name.gsub(/[^a-z]/, ' ')

      unless BaseballDiscord::Bot::NON_TEAM_CHANNELS.include?(channel_name)
        search_for << channel_name
      end

      role_names = user.roles.map(&:name).map(&:downcase) -
                   BaseballDiscord::Bot::NON_TEAM_ROLES

      search_for + role_names
    end

    def react_to_message(reaction)
      message.react reaction

      nil
    end

    def send_pm(message)
      user.pm message

      nil
    end

    def bot
      event.bot
    end

    def channel
      event.channel
    end

    def message
      event.message
    end

    def server
      event.server
    end

    def user
      event.user
    end
  end
end
