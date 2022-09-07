# frozen_string_literal: true

require_relative 'baseball_discord/bot'

@discord_bot = BaseballDiscord::Bot.new

# @discord_bot.register_application_command(:debug_emoji, 'Show all known team emojis')

# @discord_bot.register_application_command(:define, 'Look up a term from FanGraphs') do |cmd|
#   cmd.string 'term'
# end

# @discord_bot.register_application_command(:invite_url, '')

@discord_bot.register_application_command(:bbref, 'Search Baseball Reference') do |cmd|
  cmd.string 'query', 'a term to search for', required: true
end

@discord_bot.register_application_command(:fangraphs, 'Search FanGraphs') do |cmd|
  cmd.string 'query', 'a term to search for', required: true
end

# @discord_bot.register_application_command(:player, '')

# @discord_bot.register_application_command(:scores, 'Shows scores and stuff')

# @discord_bot.register_application_command(:standings, 'Displays the division standings for a team')

# @discord_bot.register_application_command(:next, 'Display the next N games for a team')

# @discord_bot.register_application_command(:last, 'Display the last N games for a team')

# @discord_bot.register_application_command(:team, 'Change your team tag')

# @discord_bot.register_application_command(:verify, 'Verify your reddit account')

# @discord_bot.register_application_command(:wcstandings, 'Displays the wildcard standings for a team')
