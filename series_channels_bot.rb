# frozen_string_literal: true

require 'open-uri'

require 'discordrb'
require 'discordrb/light'
require 'discordrb/api'
require 'discordrb/api/channel'
require 'discordrb/api/server'

class SeriesChannelsBot
  # rubocop:disable Style/NumericLiterals
  SERVER_ID = 450792745553100801
  GAME_CHATS_ID = 453783775302909952
  LIVE_GAMES_ID = 453783826095669248
  # rubocop:enable Style/NumericLiterals

  LIVE_GAME_STATUSES = [].freeze

  SCHEDULE = \
    'https://statsapi.mlb.com/api/v1/schedule?sportId=1&date=%<date>s&' \
    'hydrate=game(content(summary)),linescore,flags,team&t=%<t>d'

  def initialize(token:)
    @token = "Bot #{token}"
  end

  def bot
    @bot ||= Discordrb::Light::LightBot.new(@token)
  end

  def server
    @server ||= bot.servers.find { |data| data.id == SERVER_ID }
  end

  def create_channel(name)
    data = { name: name, type: 0, parent_id: GAME_CHATS_ID }

    response = request(
      :guilds_sid_channels,
      SERVER_ID,
      :post,
      "guilds/#{SERVER_ID}/channels",
      data
    )

    JSON.parse(response)
  end

  def series_channels
    channels = {}

    todays_games.map do |game|
      name = [
        game.dig('teams', 'away', 'team', 'teamName'),
        game.dig('teams', 'home', 'team', 'teamName')
      ].join(' at ').downcase.gsub(/[^a-z]/, '-').gsub(/\-{2,}/, '-')

      status = game.dig('status', 'abstractGameState')

      channels[name] ||= LIVE_GAME_STATUSES.include?(status)
    end

    channels
  end

  def all_channels
    @all_channels ||= begin
      response = Discordrb::API::Server.channels(@token, SERVER_ID)

      JSON.parse(response).map { |channel| [channel['id'].to_i, channel] }.to_h
    end
  end

  def existing_channels
    all_channels.select do |_, channel|
      [GAME_CHATS_ID, LIVE_GAMES_ID].include?(channel['parent_id'].to_i)
    end
  end

  def todays_games
    url = format SCHEDULE, date: Time.now.strftime('%m/%d/%Y'), t: Time.now.to_i

    JSON.parse(URI.parse(url).open.read).dig('dates', 0, 'games')
  end

  def move_channels_around
    @all_channels = nil

    all_channels.each do |channel_id, channel|
      game_is_live = series_channels[channel['name']]

      next if game_is_live && channel['parent_id'].to_i == LIVE_GAMES_ID
      next unless game_is_live && channel['parent_id'].to_i == GAME_CHATS_ID

      move_channel(channel_id, game_is_live ? LIVE_GAMES_ID : GAME_CHATS_ID)
    end
  end

  def move_channel(channel_id, parent_id)
    data = { parent: parent_id }

    request(:channels_cid, channel_id, :patch, "channels/#{channel_id}", data)
  end

  def request(key, major_parameter, method, endpoint, data = {})
    Discordrb::API.request(
      key,
      major_parameter,
      method,
      "#{Discordrb::API.api_base}/#{endpoint}",
      data.to_json,
      Authorization: @token,
      content_type: :json,
      'X-Audit-Log-Reason': nil
    )
  end
end

bot = SeriesChannelsBot.new(token: ENV['DISCORD_TOKEN'])

existing = bot.existing_channels
goal = bot.series_channels.keys

to_create = goal - existing.map { |_, channel| channel['name'] }
to_remove = existing.reject { |_, channel| goal.include?(channel['name']) }

puts "Create: #{to_create.join(', ')}"
puts "Remove: #{to_remove.map { |_, channel| channel['name'] }.join(', ')}"

to_create.each do |name|
  bot.create_channel(name)
end

bot.move_channels_around
