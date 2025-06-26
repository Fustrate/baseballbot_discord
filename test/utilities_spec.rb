# frozen_string_literal: true

require 'minitest/autorun'

require_relative '../shared/utilities'

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
    BaseballDiscord::Utilities.teams_by_name.each do |team_id, names|
      names.each { assert_equal team_id, BaseballDiscord::Utilities.find_team_by_name(it) }
    end

    assert_equal 110, BaseballDiscord::Utilities.find_team_by_name('orioles')
    assert_equal 120, BaseballDiscord::Utilities.find_team_by_name('dc')
    assert_equal 145, BaseballDiscord::Utilities.find_team_by_name('cws')
  end

  def test_extract_date
    team, date = BaseballDiscord::Utilities.extract_date('dodgers 4/4/85')

    assert_equal 'dodgers', team
    assert_equal Date.new(1985, 4, 4), date
  end
end
