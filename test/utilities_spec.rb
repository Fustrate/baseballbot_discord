# frozen_string_literal: true

require 'minitest/autorun'
require 'chronic'

require_relative '../baseball_discord/utilities.rb'

class TestApi < MiniTest::Test
  def test_proper_league
    assert_equal 103, BaseballDiscord::Utilities.league_for_team(118)
    assert_equal 103, BaseballDiscord::Utilities.league_for_team(133)
    assert_equal 103, BaseballDiscord::Utilities.league_for_team(147)

    assert_equal 104, BaseballDiscord::Utilities.league_for_team(119)
    assert_equal 104, BaseballDiscord::Utilities.league_for_team(121)
    assert_equal 104, BaseballDiscord::Utilities.league_for_team(158)
  end

  def test_find_team_by_name
    BaseballDiscord::Utilities::TEAMS_BY_NAME.each do |team_id, names|
      names.each do |name|
        assert_equal team_id, BaseballDiscord::Utilities.find_team_by_name(name)
      end
    end
  end

  def test_extract_date
    team, date = BaseballDiscord::Utilities.extract_date('dodgers 4/4/57')

    assert_equal 'dodgers', team
    assert_equal Date.new(1957, 4, 4), date
  end
end
