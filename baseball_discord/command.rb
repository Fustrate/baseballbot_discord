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
      filename = interpolate_url(url, interpolations)

      log "[URL Load] #{filename}", level: :debug

      JSON.parse(URI.parse(filename).open.read)
    end

    def interpolate_url(url, interpolations)
      date = interpolations[:date] || (Time.now - 7200)

      format(
        url,
        interpolations.merge(
          year: date.year,
          t: Time.now.to_i,
          date: date.strftime('%m/%d/%Y')
        )
      )
    end

    def log(str, level: :info)
      @log_tags ||= "[#{message.id}] [#{user.distinct}]"

      str.lines.map(&:strip).each do |line|
        bot.logger.add LOG_LEVELS.index(level), "#{@log_tags} #{line}"
      end
    end

    # Try the channel first, then roles, then the server
    def names_from_context
      search = [team_name_from_channel_name] + team_names_from_roles

      (search + [bot.config.dig(server.id, 'default_team')]).compact
    end

    def team_name_from_channel_name
      channel.name.downcase.tr('-', ' ')
    end

    def team_names_from_roles
      user.roles.map(&:name).map(&:downcase)
    end

    def react_to_message(reaction)
      message.react reaction

      nil
    end

    def send_pm(message)
      user.pm message

      nil
    end

    def format_table(table)
      "```\n#{prettify_table(table)}\n```"
    end

    def prettify_table(table)
      top_border, *middle, bottom_border = table.to_s.lines.map(&:strip)

      new_table = middle.map do |line|
        line[0] == '+' ? "├#{line[1...-1].tr('-+', '─┼')}┤" : line.tr('|', '│')
      end

      new_table.unshift "┌#{top_border[1...-1].tr('-+', '─┬')}┐"
      new_table.push "└#{bottom_border[1...-1].tr('-+', '─┴')}┘"

      # Move the T-shaped corners down two rows if there's a title
      if table.title
        new_table[0] = new_table[0].tr('┬', '─')
        new_table[2] = new_table[2].tr('┼', '┬')
      end

      new_table.join("\n")
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
