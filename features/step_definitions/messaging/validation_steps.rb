# frozen_string_literal: true

# Message validation steps
# Handles form validation, error messages, and error recovery

When('I try to send an empty message') do
  visit new_message_path
  # Leave message body empty
  click_button 'Send Message'
end

When('I try to send a message that\'s too long') do
  visit new_message_path
  # Create a message that's too long (over 500 characters)
  long_message = 'A' * 501
  fill_in 'message_body', with: long_message
  click_button 'Send Message'
  @long_message = long_message
end

When('I correct the message with valid content') do
  # Clear the field and enter valid content
  fill_in 'message_body', with: 'This is a valid message'
end

When('I submit the corrected message') do
  click_button 'Send Message'
end

Then('I should see validation error for blank message') do
  has_blank_error = page.has_content?("can't be blank")
  has_error_styling = page.has_css?('.alert-danger, .invalid-feedback')
  expect(has_blank_error || has_error_styling).to be true
end

Then('I should see validation error for message length') do
  has_length_error = page.has_content?('is too long')
  has_error_styling = page.has_css?('.alert-danger, .invalid-feedback')
  expect(has_length_error || has_error_styling).to be true
end

Then('I see validation error for message length') do
  has_length_error = page.has_content?('is too long')
  has_error_styling = page.has_css?('.alert-danger, .invalid-feedback')
  expect(has_length_error || has_error_styling).to be true
end

Then('I should remain on the message form') do
  expect(page).to have_css('form')
  expect(page).to have_button('Send Message')
end
