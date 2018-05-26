# frozen_string_literal: true

require 'chronic'
require 'date'
require 'discordrb'
require 'mlb_stats_api'
require 'open-uri'
require 'terminal-table'
require 'tzinfo'

require_relative 'commands/next_ten'
require_relative 'commands/scoreboard'
require_relative 'commands/standings'
require_relative 'verification'

class BaseballDiscordBot
  NON_TEAM_CHANNELS = %w[
    general bot welcome verification discord-options
  ].freeze

  SERVER_ID = 400_516_567_735_074_817

  include BaseballDiscordBot::Commands::NextTen
  include BaseballDiscordBot::Commands::Scoreboard
  include BaseballDiscordBot::Commands::Standings
  include BaseballDiscordBot::Verification

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

discord_bot = Discordrb::Commands::CommandBot.new(
  client_id: ENV['DISCORD_CLIENT_ID'],
  token: ENV['DISCORD_TOKEN'],
  prefix: '!'
)

baseballbot = BaseballDiscordBot.new

BaseballDiscordBot::Commands::NextTen.add_to discord_bot, baseballbot
BaseballDiscordBot::Commands::Scoreboard.add_to discord_bot, baseballbot
BaseballDiscordBot::Commands::Standings.add_to discord_bot, baseballbot
BaseballDiscordBot::Verification.add_to discord_bot, baseballbot

discord_bot.run
