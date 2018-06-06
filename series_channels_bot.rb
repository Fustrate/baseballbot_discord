# frozen_string_literal: true

require 'open-uri'

require 'discordrb'
require 'discordrb/light'
require 'discordrb/api'
require 'discordrb/api/channel'
require 'discordrb/api/server'

class SeriesChannelsBot
  SERVER_ID = 450792745553100801
  GAME_CHATS_ID = 453783775302909952
  LIVE_GAMES_ID = 453783826095669248

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

  def series_channel_names
    todays_games.map do |game|
      [
        game.dig('teams', 'away', 'team', 'teamName'),
        game.dig('teams', 'home', 'team', 'teamName')
      ].join(' at ').downcase.gsub(/[^a-z]/, '-').gsub(/\-{2,}/, '-')
    end.uniq.sort
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

  def move_channel(channel_id, to_parent_id:)
    data = { parent: to_parent_id }

    request(:channels_cid, channel_id, :patch, "channels/#{channel_id}", data)
  end

  def update_channels
    all_channel_names.each do |name|
      create_channel(name, parent_id: CATEGORY_ID)
    end
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

thingy = SeriesChannelsBot.new(token: ENV['DISCORD_TOKEN'])

existing = thingy.existing_channels
goal = thingy.series_channel_names

to_create = goal - existing.map { |_, channel| channel['name'] }
to_remove = existing.reject { |_, channel| goal.include?(channel['name']) }

puts "Create: #{to_create.join(', ')}"
puts "Remove: #{to_remove.map { |_, channel| channel['name'] }.join(', ')}"

to_create.each do |name|
  thingy.create_channel(name)
end

# thingy.all_channels
#   .select { |_, channel| channel['parent_id'].to_i == 451_099_095_189_291_018 }
#   .each { |id, channel| puts "#{id}: #{channel['name']}" }
