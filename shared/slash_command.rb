# frozen_string_literal: true

class SlashCommand
  LOG_LEVELS = %i[debug info warn error fatal unknown].freeze

  attr_reader :event

  def initialize(event)
    @event = event
  end

  protected

  def log(str, level: :info)
    @log_tags ||= "[/#{event.command_name}] [#{user.distinct}]"

    str.lines.map(&:strip).each do |line|
      bot.logger.add LOG_LEVELS.index(level), "#{@log_tags} #{line}"
    end
  end

  # Try the channel first, then roles, then the server
  def names_from_context
    ([team_name_from_channel_name] + team_names_from_roles + [bot.config.dig(server.id, 'default_team')]).compact
  end

  def team_name_from_channel_name = channel.name.downcase.tr('-', ' ')

  def team_names_from_roles = user.roles.map { it.name.downcase }

  def send_pm(message)
    user.pm message

    nil
  end

  def format_table(table) = "```\n#{table}\n```"

  def options = event.options

  def respond_with(content: nil, embed: nil, ephemeral: false)
    event.respond(content:, embeds: [embed].compact, ephemeral:)
  end

  def bot = event.bot

  def channel = event.channel

  def server = event.server_id ? event.server : nil

  def user = event.user

  def error_message(message) = respond_with(content: "⚠️ #{message}", ephemeral: true)
end
