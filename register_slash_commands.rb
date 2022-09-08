# frozen_string_literal: true

require_relative 'baseball_discord/bot'

@discord_bot = BaseballDiscord::Bot.new

# TODO: Limit to admins
@discord_bot.register_application_command(:debug, 'Debug different parts of the bot') do |cmd|
  cmd.string('type', 'Thing to debug', choices: %w[channel emoji pm server user].to_h { [_1, _1] })
end

@discord_bot.register_application_command(:define, 'Look up a term from FanGraphs') do |cmd|
  cmd.string 'term', 'a term to search for', required: true
end

# @discord_bot.register_application_command(:invite_url, '')

@discord_bot.register_application_command(:bbref, 'Search Baseball Reference') do |cmd|
  cmd.string 'query', 'a term to search for', required: true
end

@discord_bot.register_application_command(:fangraphs, 'Search FanGraphs') do |cmd|
  cmd.string 'query', 'a term to search for', required: true
end

# @discord_bot.register_application_command(:scores, 'Shows scores and stuff') do |cmd|
#   cmd.string 'date', 'today|yesterday|tomorrow|Date', required: false
# end

# @discord_bot.register_application_command(:standings, 'Displays the division standings for a team')

# @discord_bot.register_application_command(:next, 'Display the next N games for a team')

# @discord_bot.register_application_command(:last, 'Display the last N games for a team')

# @discord_bot.register_application_command(:team, 'Change your team tag')

# @discord_bot.register_application_command(:verify, 'Verify your reddit account')

# @discord_bot.register_application_command(:wcstandings, 'Displays the wildcard standings for a team')
