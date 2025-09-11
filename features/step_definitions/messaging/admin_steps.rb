# frozen_string_literal: true

# Admin-specific messaging steps
# Handles admin message routing and administrative communications

When('I switch to admin view') do
  # Use the demo user switching system (same as real app)
  User.class_eval do
    def self.current
      User.find_by(first_name: 'Obi-wan', last_name: 'Kenobi')
    end
  end
  @current_user = @admin
end

When('I compose and send a new message to admin') do
  visit new_message_path
  fill_in 'message_body', with: 'Administrative request message'
  click_button 'Send Message'
  @sent_message_body = 'Administrative request message'
end

Then('I should see the patient message in admin inbox') do
  # Verify UI shows the message in admin's inbox
  expect(page).to have_css('#inbox-list .list-group-item', wait: 10)
  expect(page).to have_content('Test message content')
end
