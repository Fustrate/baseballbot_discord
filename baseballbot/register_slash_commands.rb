# frozen_string_literal: true

require_relative 'bot'

# Only uncomment a command when it needs to be updated. Re-comment after the update is deployed and this script is run.

@discord_bot = BaseballDiscord::Bot.new

# TODO: Limit to admins
# @discord_bot.register_application_command(:debug, 'Debug different parts of the bot') do |cmd|
#   cmd.string('type', 'Thing to debug', choices: %w[channel emoji pm server user].to_h { [it, it] })
# end

# @discord_bot.register_application_command(:define, 'Look up a term from FanGraphs') do |cmd|
#   cmd.string 'term', 'a term to search for', required: true
# end

# @discord_bot.register_application_command(:invite_url, 'Invite baseballbot to another server (admin only)')

# @discord_bot.register_application_command(:bbref, 'Search Baseball Reference') do |cmd|
#   cmd.string 'query', 'a term to search for', required: true
# end

# @discord_bot.register_application_command(:fangraphs, 'Search FanGraphs') do |cmd|
#   cmd.string 'query', 'a term to search for', required: true
# end

# @discord_bot.register_application_command(:scores, 'Shows scores and stuff') do |cmd|
#   cmd.string 'date', 'Date or today/yesterday/tomorrow', required: false
# end

# @discord_bot.register_application_command(:standings, 'Displays the division standings for a team') do |cmd|
#   cmd.string 'team', 'The team for which to show standings', required: false
#   cmd.string 'date', 'The date to show standings from', required: false
# end

# @discord_bot.register_application_command(:next, 'Display the next N games for a team') do |cmd|
#   cmd.number 'amount', 'The number of games to show', min_value: 1, max_value: 15, required: false
#   cmd.string 'team', 'An MLB team', required: false
# end

# @discord_bot.register_application_command(:last, 'Display the last N games for a team') do |cmd|
#   cmd.number 'amount', 'The number of games to show', min_value: 1, max_value: 15, required: false
#   cmd.string 'team', 'An MLB team', required: false
# end

# @discord_bot.register_application_command(:team, 'Change your team tag') do |cmd|
#   cmd.string 'team1', 'Primary team name', required: true
#   cmd.string 'team2', 'Secondary team name', required: false
# end

# @discord_bot.register_application_command(:username, 'Change your username') do |cmd|
#   cmd.string 'username', 'Your new username', required: true
# end

@discord_bot.delete_application_command(:verify)

# @discord_bot.register_application_command(:wildcard, 'Displays the wildcard standings for a league') do |cmd|
#   cmd.string(
#     'league',
#     'The league for which to show standings',
#     choices: { AL: 'AL', NL: 'NL' },
#     required: false
#   )

#   cmd.string 'date', 'The date to show standings from', required: false
# end
