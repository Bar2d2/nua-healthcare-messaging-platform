# frozen_string_literal: true

require 'database_cleaner/active_record'

DatabaseCleaner.strategy = :truncation

Around do |_scenario, block|
  DatabaseCleaner.cleaning do
    # Ensure seed data is loaded before each scenario
    Rails.application.load_seed unless User.exists?
    block.call
  end
end
