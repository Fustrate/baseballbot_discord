# frozen_string_literal: true

require 'discordrb'
require 'mlb_stats_api'
require 'rufus-scheduler'
require 'terminal-table'

require_relative 'baseball_discord/utilities'

class Output
  protected

  def squish(text)
    text.gsub(/\s{2,}/, ' ').strip
  end

  def titleize(text)
    text.tr('_', ' ').gsub(/\b[a-z]/, &:capitalize)
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
end

class GameAlert < Output
  def initialize(alert, game)
    @alert = alert
    @game = game
  end

  def embed
    return end_of_inning_embed if @alert['category'] == 'end_of_half_inning'

    return end_of_game_embed if @alert['category'] == 'game_over'

    basic_embed
  end

  def end_of_inning_embed
    {
      title: @game.line_score.line_score_inning,
      description: "```\n#{@game.line_score.rhe_table}\n```",
      color: '109799'.to_i(16)
    }
  end

  def end_of_game_embed
    {
      title: 'Game Over',
      color: 'ffffff'.to_i(16),
      description: <<~DESCRIPTION
        #{description}

        ```
        #{@game.line_score.rhe_table}
        ```
      DESCRIPTION
    }
  end

  def basic_embed
    {
      title: titleize(@alert['category']),
      description: description,
      color: '109799'.to_i(16)
    }
  end

  def description
    # Get rid of the "In Los Angeles:" part that's in every description
    @alert['description'].gsub(/\Ain [a-z\. ]+: /i, '')
  end
end

class GamePlay < Output
  def initialize(play, game)
    @play = play
    @game = game
  end

  def embed
    case type
    when 'Walk', 'Strikeout' then strikeout_or_walk_embed
    when 'Home Run' then home_run_embed
    else
      basic_embed
    end
  end

  protected

  def type
    @type ||= @play.dig('result', 'event')
  end

  def description
    description = @play.dig('result', 'description')

    return description unless @play.dig('about', 'isScoringPlay')

    "#{description}\n\n```\n#{@game.line_score.rhe_table}\n```"
  end

  def count
    the_count = @play['count'].values_at('balls', 'strikes')

    # The API likes to show 4 balls or 3 strikes. HBP on what would be ball 4
    # also shows as Ball 4.
    the_count[0] = 3 if type == 'Walk' || the_count[0] == 4
    the_count[1] = 2 if type == 'Strikeout' || the_count[1] == 3

    the_count.join('-')
  end

  def strikeout_or_walk_embed
    {
      title: "#{type} (#{count})",
      description: description,
      color: color
    }
  end

  def home_run_embed
    event = @play['playEvents'].last

    hit = event['hitData']

    {
      title: "#{type} (#{count})",
      description: description,
      color: color,
      fields: [
        { name: 'Launch Angle', value: "#{hit['launchAngle']}°", inline: true },
        { name: 'Launch Speed', value: "#{hit['launchSpeed']} mph", inline: true },
        { name: 'Distance', value: hit['totalDistance'], inline: true },
        { name: 'Pitch', value: pitch_type(event), inline: true }
      ]
    }
  end

  def pitch_type(event)
    speed = event.dig('pitchData', 'startSpeed')

    "#{speed} mph #{event.dig('details', 'type', 'description')}"
  end

  def basic_embed
    {
      title: "#{type} (#{count})",
      description: description,
      color: color
    }
  end

  def color
    return '3a9910'.to_i(16) if @play.dig('about', 'isScoringPlay')

    return '991010'.to_i(16) if @play.dig('about', 'hasOut')

    '106499'.to_i(16)
  end
end

class LineScore < Output
  POSTGAME_STATUSES = [
    'Final', 'Game Over', 'Postponed', 'Completed Early'
  ].freeze

  def initialize(game)
    @game = game
  end

  def line_score
    rows = base_line_score

    @game.feed.live_data.dig('linescore', 'innings').each do |inning|
      rows[2][inning['num']] = inning.dig('away', 'runs')
      rows[3][inning['num']] = inning.dig('home', 'runs')
    end

    prettify_table Terminal::Table.new(rows: rows)
  end

  def base_line_score
    [
      [''] + (1..innings).to_a + %w[R H E],
      :separator,
      team_line_score(away_team_name, innings, away_rhe),
      team_line_score(home_team_name, innings, home_rhe)
    ]
  end

  def team_line_score(name, innings, rhe)
    [name] + [''] * innings + rhe
  end

  def line_score_inning
    linescore = @game.feed.live_data['linescore']

    format(
      '%<side>s of the %<inning>s',
      side: linescore['inningState'],
      inning: linescore['currentInningOrdinal']
    )
  end

  def rhe_table
    prettify_table Terminal::Table.new(
      rows: [
        ['', 'R', 'H', 'E'],
        :separator,
        [away_team_name] + away_rhe,
        [home_team_name] + home_rhe
      ]
    )
  end

  def line_score_state
    status = @game.feed.game_data.dig('status', 'abstractGameState')

    if POSTGAME_STATUSES.include?(status)
      return innings == 9 ? 'Final' : "Final/#{innings}"
    end

    str = line_score_inning

    linescore = @game.feed.live_data['linescore']

    if %w[Top Bottom].include?(linescore['inningState'])
      outs = linescore['outs'] == 1 ? '1 Out' : "#{linescore['outs']} Outs"

      str = "#{outs}, #{str}"
    end

    str
  end

  protected

  def innings
    [@game.feed.live_data.dig('linescore', 'innings').count, 9].max
  end

  def away_rhe
    @game.feed.live_data.dig('linescore', 'teams', 'away')
      .values_at('runs', 'hits', 'errors')
  end

  def home_rhe
    @game.feed.live_data.dig('linescore', 'teams', 'home')
      .values_at('runs', 'hits', 'errors')
  end

  def away_team_name
    @game.feed.game_data.dig('teams', 'away', 'abbreviation')
  end

  def home_team_name
    @game.feed.game_data.dig('teams', 'home', 'abbreviation')
  end
end

class DiscordChannelGameFeed
  attr_reader :feed, :game_pk, :line_score, :channel

  def initialize(game_pk, channel)
    @game_pk = game_pk
    @channel = channel

    @client = MLBStatsAPI::Client.new

    @feed = @client.live_feed(game_pk)

    @last_play = nil
    @last_event = nil

    @alert_ids = []
  end

  def update_game_chat
    return unless @feed.update!

    @line_score = LineScore.new(self)

    output_last_play

    output_alerts

    @channel.topic = @line_score.line_score_state
  rescue Net::OpenTimeout, SocketError
    nil
  end

  def send_line_score
    @channel.send_message <<~LINESCORE
      #{@line_score.line_score_state}

      ```#{@line_score.line_score}```
    LINESCORE
  end

  def send_lineups
  end

  def send_lineup(event, input)
    team = BaseballDiscord::Utilities.find_team_by_name(input)

    return event.message.react '❓' unless team

    @channel.send_message "Lineup for #{team}"
  end

  def send_umpires
    umpires = @feed.live_data.dig('boxscore', 'officials').map do |umpire|
      "**#{umpire['officialType']}**: #{umpire.dig('official', 'fullName')}"
    end

    @channel.send_message umpires.join("\n")
  end

  protected

  def plays_to_output
    plays = @feed.plays['allPlays']

    # No plays yet; game probably hasn't started.
    return [] unless plays&.any?

    if @last_play
      # Check to see if the last play we looked at has any more info
      # Output any more plays after this one
    else
      # Output all plays, I guess
    end
  end

  def output_last_play
    last_play = @feed.plays['allPlays']
      .select { |play| play['about']['isComplete'] }
      .last

    return unless last_play

    index = last_play.dig('about', 'atBatIndex')

    return if index <= @last_at_bat_index

    @last_at_bat_index = index

    @channel.send_embed('', GamePlay.new(last_play, self).embed)
  end

  def output_alerts
    return unless @feed.game_data

    @feed.game_data['alerts'].each do |alert|
      next if @alert_ids.include?(alert['alertId'])

      @channel.send_embed('', GameAlert.new(alert, self).embed)

      @alert_ids << alert['alertId']
    end
  end
end

class DiscordGameFeedPoster < Discordrb::Commands::CommandBot
  SERVER_ID = 450792745553100801
  CHANNEL_ID = 455657468442443777

  def initialize(attributes = {})
    @games = {}

    super attributes.merge(prefix: '!')

    start_loop

    command(:linescore) do |event|
      @games[event.channel&.id]&.send_line_score

      nil
    end

    command(:umpires) do |event|
      @games[event.channel&.id]&.send_umpires

      nil
    end

    command(:lineup) do |event, *args|
      @games[event.channel&.id]&.send_lineup(event, args.join(' '))

      nil
    end

    command(:lineups) do |event|
      @games[event.channel&.id]&.send_lineups

      nil
    end
  end

  def start_loop
    scheduler = Rufus::Scheduler.new

    scheduler.every('20s') { update_games }
    scheduler.in('5s') { update_games }
  end

  def update_games
    load_games if @games.empty?

    @games.each_value(&:update_game_chat)
  end

  def load_games
    # @games[455657467360313357] = game_feed(530388, 455657467360313357)
    # @games[455657468442443777] = game_feed(530394, 455657468442443777)
    # @games[455657468102443018] = game_feed(530395, 455657468102443018)
    # @games[455657469268590592] = game_feed(530389, 455657469268590592)
    # @games[455657469600071684] = game_feed(530390, 455657469600071684)
    # @games[455657469947936770] = game_feed(530393, 455657469947936770)
    @games[455657470489001986] = game_feed(530392, 455657470489001986)
    @games[455657471277531159] = game_feed(530391, 455657471277531159)
  end

  def game_feed(game_pk, channel_id)
    DiscordChannelGameFeed.new(
      game_pk,
      servers[SERVER_ID].channels.find { |channel| channel.id == channel_id }
    )
  end
end

@bot = DiscordGameFeedPoster.new(
  client_id: ENV['DISCORD_CLIENT_ID'],
  token: ENV['DISCORD_TOKEN'],
  command_doesnt_exist_message: nil,
  help_command: false
)

trap('TERM') do
  # No sync because we're in a trap context
  @bot.stop(true)

  exit
end

# This will block the running process, so it should be executed last
@bot.run
