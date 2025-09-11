# frozen_string_literal: true

# Message composition and sending steps
# Handles new message creation, replies, and form interactions

When('I compose and send a new message') do
  visit new_message_path
  fill_in 'message_body', with: 'Test message content'
  click_button 'Send Message'
  @sent_message_body = 'Test message content'
end

When('I reply to the message with {string}') do |reply_content|
  click_link 'Reply'
  fill_in 'message_body', with: reply_content
  click_button 'Send Message'
  @reply_content = reply_content
end

Then('the message should appear in my outbox') do
  visit outbox_path
  expect(page).to have_css('#outbox-list .list-group-item')
end

When('I fill in and submit the message form') do
  fill_in 'message_body', with: 'Test message content'
  click_button 'Send Message'
end

Then('the reply should appear in my outbox') do
  visit outbox_path
  expect(page).to have_content(@reply_content) if @reply_content
end
