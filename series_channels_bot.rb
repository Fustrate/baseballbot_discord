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

  LIVE_GAME_STATUSES = %w[Live Preview].freeze

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

      # In case of a double header, || the status
      channels[name] ||= game_is_live?(game)
    end

    channels
  end

  def game_is_live?(game)
    abstract = game.dig('status', 'abstractGameState')

    return true if abstract == 'Live'

    detailed = game.dig('status', 'detailedState')

    return true if ['Pre-Game', 'Warmup'].include?(detailed)

    false
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

  def update_channel_list
    existing = existing_channels
    goal = series_channels.keys

    to_create = goal - existing.map { |_, channel| channel['name'] }
    to_remove = existing.reject { |_, channel| goal.include?(channel['name']) }

    to_create.each { |name| create_channel(name) }
    to_remove.each { |channel_id, _channel| remove_channel(channel_id) }
  end

  def move_channels_around
    @all_channels = nil

    existing_channels.each do |channel_id, channel|
      game_is_live = series_channels[channel['name']]

      new_category = game_is_live ? LIVE_GAMES_ID : GAME_CHATS_ID

      next if channel['parent_id'].to_i == new_category

      move_channel(channel_id, new_category)
    end
  end

  def move_channel(channel_id, parent_id)
    data = { parent_id: parent_id }

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

  def remove_channel(channel_id)
    puts "Remove #{channel_id}"
  end
end

bot = SeriesChannelsBot.new(token: ENV['DISCORD_TOKEN'])

bot.update_channel_list
bot.move_channels_around
