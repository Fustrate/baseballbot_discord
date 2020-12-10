# frozen_string_literal: true

require 'open-uri'
require 'redis'

require 'discordrb'
require 'discordrb/light'
require 'discordrb/api'
require 'discordrb/api/channel'
require 'discordrb/api/server'

class SeriesChannelsBot
  SERVER_ID = 400516567735074817
  GAME_CHATS_ID = 458025594517454858
  LIVE_GAMES_ID = 458025632102744074

  LIVE_GAME_STATUSES = %w[Live Preview].freeze

  SCHEDULE = 'https://statsapi.mlb.com/api/v1/schedule?sportId=1&date=%<date>s&' \
             'hydrate=game(content(summary)),linescore,flags,team&t=%<t>d'

  def initialize(token:)
    @token = "Bot #{token}"
    @redis = Redis.new
  end

  def update_channels
    existing = existing_channels
    goal = series_channels.keys

    to_create = goal - existing.map { |_, channel| channel['name'] }
    to_remove = existing.reject { |_, channel| goal.include?(channel['name']) }

    to_create.each { |name| create_channel(name) }
    to_remove.each { |channel_id, _channel| remove_channel(channel_id) }
  end

  def move_channels
    @all_channels = nil

    existing_channels.each do |channel_id, channel|
      game_is_live = series_channels[channel['name']]

      new_category = game_is_live ? LIVE_GAMES_ID : GAME_CHATS_ID

      next if channel['parent_id'].to_i == new_category

      move_channel(channel_id, new_category)
    end
  end

  protected

  def series_channels
    channels = {}

    active_games = {}

    todays_games.map do |game|
      name = channel_name_for_game(game)

      active_games[name] = game['gamePk'].to_s if game_is_live?(game)

      # In case of a double header, || the status
      channels[name] ||= game_is_live?(game)
    end

    update_redis(active_games)

    channels
  end

  def channel_name_for_game(game)
    [
      game.dig('teams', 'away', 'team', 'teamName'),
      game.dig('teams', 'home', 'team', 'teamName')
    ].join(' at ').downcase.gsub(/[^a-z]/, '-').gsub(/-{2,}/, '-')
  end

  def update_redis(active_games)
    current_value = @redis.hgetall('live_games')

    return if current_value == active_games

    delete_keys = current_value.keys - active_games.keys

    @redis.hdel 'live_games', *delete_keys if delete_keys.any?
    @redis.mapped_hmset 'live_games', active_games if active_games.any?
  end

  def existing_channels
    all_channels.select do |_, channel|
      [GAME_CHATS_ID, LIVE_GAMES_ID].include?(channel['parent_id'].to_i)
    end
  end

  # @!group MLB Data

  def todays_games
    url = format SCHEDULE, date: Time.now.strftime('%m/%d/%Y'), t: Time.now.to_i

    JSON.parse(URI.parse(url).open.read).dig('dates', 0, 'games')
  end

  def game_is_live?(game)
    return true if game.dig('status', 'abstractGameState') == 'Live'

    %w[Pre-Game Warmup].include? game.dig('status', 'detailedState')
  end

  # @!endgroup MLB Data

  # @!group Discord

  def all_channels
    @all_channels ||= begin
      response = Discordrb::API::Server.channels(@token, SERVER_ID)

      JSON.parse(response).map { |channel| [channel['id'].to_i, channel] }.to_h
    end
  end

  def create_channel(name)
    data = { name: name, type: 0, parent_id: GAME_CHATS_ID }

    JSON.parse request(:guilds_sid_channels, SERVER_ID, :post, "guilds/#{SERVER_ID}/channels", data)
  end

  def remove_channel(channel_id)
    Discordrb::API::Channel.delete(@token, channel_id)
  end

  def move_channel(channel_id, parent_id)
    data = { parent_id: parent_id }

    request :channels_cid, channel_id, :patch, "channels/#{channel_id}", data
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

  # @!endgroup Discord
end
