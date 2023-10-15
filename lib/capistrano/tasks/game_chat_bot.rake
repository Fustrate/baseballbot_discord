# frozen_string_literal: true

namespace :game_chat_bot do
  %i[start stop restart].each do |action|
    desc "#{action} the game chat bot"
    task action do
      on roles(:web) do
        within release_path do
          execute :bundle, :exec, :ruby, 'game_chat_bot/control.rb', action
        end
      end
    end
  end
end
