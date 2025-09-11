# frozen_string_literal: true

Feature: Message Validation Journey
  As a user
  I want clear feedback when my message is invalid
  So that I can correct my input and send messages successfully

  Background:
    Given the application is running
    And I have test users in the system

  @validation @core
  Scenario: User submits empty message
    Given I am logged in as a patient
    When I try to send an empty message
    Then I should see validation error for blank message
    And I should remain on the message form

  @validation @core
  Scenario: User submits message that's too long
    Given I am logged in as a patient
    When I try to send a message that's too long
    Then I should see validation error for message length
    And I should remain on the message form

  @validation @core
  Scenario: User fixes validation error and sends successfully
    Given I am logged in as a patient
    When I try to send a message that's too long
    And I see validation error for message length
    When I correct the message with valid content
    And I submit the corrected message
    Then I should see message sent successfully
