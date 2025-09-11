# frozen_string_literal: true

# Shared navigation steps for all user journeys
# Handles page navigation and basic UI interactions

When('I visit the root page') do
  visit root_path
end

When('I visit the new message page') do
  visit new_message_path
end

When('I visit my inbox') do
  visit inbox_path
end

When('I visit my outbox') do
  visit outbox_path
end

When('I navigate to inbox') do
  click_link 'Inbox'
end

When('I navigate to outbox') do
  click_link 'Outbox'
end

Then('I should see my inbox page') do
  expect(page).to have_content('Inbox')
  sleep(1)
  expect(current_path).to eq(inbox_path)
end

Then('I should see my outbox page') do
  expect(page).to have_content('Outbox')
  sleep(1)
  expect(current_path).to eq(outbox_path)
end

Then('I should see {word} interface') do |role|
  case role
  when 'patient'
    expect(page).to have_content('👩‍⚕️ Patient')
  when 'doctor'
    expect(page).to have_content('🩺 Doctor')
  when 'admin'
    expect(page).to have_content('⚙️ Admin')
  end
end
