# frozen_string_literal: true

module BaseballDiscord
  class SlashCommand
    LOG_LEVELS = %i[debug info warn error fatal unknown].freeze

    attr_reader :event

    def initialize(event)
      @event = event

      # log event.message.content if event.respond_to?(:message)
    end

    protected

    def load_data_from_stats_api(path, **interpolations)
      url = "https://statsapi.mlb.com/api#{interpolate_path(path, interpolations)}"

      log "[URL Load] #{url}", level: :debug

      JSON.parse(URI.parse(url).open.read)
    end

    def interpolate_path(path, interpolations)
      date = interpolations[:date] || (Time.now - 7200)

      format path, interpolations.merge(year: date.year, t: Time.now.to_i, date: date.strftime('%m/%d/%Y'))
    end

    def log(str, level: :info)
      @log_tags ||= "[#{target.id}] [#{user.distinct}]"

      str.lines.map(&:strip).each do |line|
        bot.logger.add LOG_LEVELS.index(level), "#{@log_tags} #{line}"
      end
    end

    # Try the channel first, then roles, then the server
    def names_from_context
      ([team_name_from_channel_name] + team_names_from_roles + [bot.config.dig(server.id, 'default_team')]).compact
    end

    def team_name_from_channel_name = channel.name.downcase.tr('-', ' ')

    def team_names_from_roles = user.roles.map(&:name).map(&:downcase)

    def send_pm(message)
      user.pm message

      nil
    end

    def format_table(table) = "```\n#{table}\n```"

    def bot = event.bot

    def channel = event.channel

    def target = event.target

    def server = event.server

    def user = event.user
  end
end
