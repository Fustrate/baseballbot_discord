# frozen_string_literal: true

require 'discordrb'
require 'mlb_stats_api'
require 'rufus-scheduler'
require 'terminal-table'

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
      description: "```\n#{rhe_table}\n```",
      color: '109799'.to_i(16)
    }
  end

  def end_of_game_embed
    {
      title: 'Game Over',
      description: "```\n#{rhe_table}\n```",
      color: 'ffffff'.to_i(16)
    }
  end

  def basic_embed
    {
      title: titleize(@alert['category']),
      description: @alert['description'].gsub(/\AIn [a-z\. ]: /i, ''),
      color: '109799'.to_i(16)
    }
  end
end

class GamePlay < Output
  def initialize(play, game)
    @play = play
    @game = game
  end

  def embed
    {
      title: @play.dig('result', 'event'),
      description: context,
      color: color
    }
  end

  def context
    format(
      'On a %<count>s count, %<description>s',
      count: @play['count'].values_at('balls', 'strikes').join('-'),
      description: @play.dig('result', 'description')
    )
  end

  def color
    return '3a9910'.to_i(16) if @play.dig('about', 'isScoringPlay')

    return '991010'.to_i(16) if @play.dig('about', 'hasOut')

    '106499'.to_i(16)
  end
end

class LineScore < Output
  def initialize(game)
    @game = game
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
    away = @game.feed.live_data.dig('linescore', 'teams', 'away')
      .values_at('runs', 'hits', 'errors')

    home = @game.feed.live_data.dig('linescore', 'teams', 'home')
      .values_at('runs', 'hits', 'errors')

    away.unshift @game.feed.game_data.dig('teams', 'away', 'abbreviation')
    home.unshift @game.feed.game_data.dig('teams', 'home', 'abbreviation')

    prettify_table Terminal::Table.new(rows: [['', 'R', 'H', 'E'], away, home])
  end

  def line_score_state
    str = line_score_inning

    linescore = @game.feed.live_data['linescore']

    if %w[Top Bottom].include?(linescore['inningState'])
      outs = linescore['outs'] == 1 ? '1 Out' : "#{linescore['outs']} Outs"

      str = "#{outs}, #{str}"
    end

    str
  end

  def away_team_name
    @game.feed.game_data.dig('teams', 'away', 'abbreviation')
  end

  def home_team_name
    @game.feed.game_data.dig('teams', 'home', 'abbreviation')
  end

  def line_score
    linescore = @game.feed.live_data['linescore']

    total_innings = [linescore['innings'].count, 9].max

    innings = [
      [''] + (1..total_innings).to_a + %w[R H E],
      :separator,
      [away_team_name] + [''] * total_innings,
      [home_team_name] + [''] * total_innings
    ]

    linescore['innings'].each do |inning|
      innings[2][inning['num']] = inning['away']['runs']
      innings[3][inning['num']] = inning['home']['runs']
    end

    innings[2].concat(
      linescore.dig('teams', 'away').values_at('runs', 'hits', 'errors')
    )

    innings[3].concat(
      linescore.dig('teams', 'home').values_at('runs', 'hits', 'errors')
    )

    prettify_table Terminal::Table.new(rows: innings)
  end
end

class BaseballGame
  attr_reader :feed, :game_pk, :line_score

  def initialize(game_pk, channel)
    @game_pk = game_pk
    @channel = channel

    @client = MLBStatsAPI::Client.new

    @feed = @client.live_feed(game_pk)

    @last_at_bat_index = -1
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

  protected

  def output_last_play
    last_play = @feed.plays['allPlays']
      .select { |play| play['about']['isComplete'] }
      .last

    return unless last_play

    index = last_play.dig('about', 'atBatIndex')

    return if index == @last_at_bat_index

    @last_at_bat_index = index

    @channel.send_embed('', GamePlay.new(last_play, self).embed)
  end

  def output_alerts
    @feed.game_data['alerts'].each do |alert|
      next if @alert_ids.include?(alert['alertId'])

      @channel.send_embed('', GameAlert.new(alert, self).embed)

      @alert_ids << alert['alertId']
    end
  end
end

class GameChannelPoster < Discordrb::Commands::CommandBot
  SERVER_ID = 450792745553100801
  CHANNEL_ID = 455657467360313357

  def initialize(attributes = {})
    super attributes.merge(prefix: '!')

    start_loop

    command(:linescore, help_available: false) do
      game.send_line_score
    end
  end

  def start_loop
    scheduler = Rufus::Scheduler.new

    scheduler.every('20s') { game.update_game_chat }
    scheduler.in('5s') { game.update_game_chat }
  end

  def game
    @game ||= BaseballGame.new(
      530388,
      servers[SERVER_ID].channels.find { |channel| channel.id == CHANNEL_ID }
    )
  end
end

@bot = GameChannelPoster.new(
  client_id: ENV['DISCORD_CLIENT_ID'],
  token: ENV['DISCORD_TOKEN']
)

trap('TERM') do
  # No sync because we're in a trap context
  @bot.stop(true)

  exit
end

# This will block the running process, so it should be executed last
@bot.run
