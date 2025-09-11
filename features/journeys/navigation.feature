# frozen_string_literal: true

Feature: Navigation Journey
  As a user
  I want to navigate the messaging system easily
  So that I can access all features efficiently

  Background:
    Given the application is running
    And I have test users in the system

  @navigation @core
  Scenario: User navigates between inbox and outbox
    Given I am logged in as a patient
    When I visit the root page
    Then I should see my inbox page
    When I navigate to outbox
    Then I should see my outbox page
    When I navigate to inbox
    Then I should see my inbox page

  @navigation @core
  Scenario: User can access messaging features
    Given I am logged in as a patient
    When I visit my inbox
    Then I should see my inbox page
    When I visit my outbox
    Then I should see my outbox page
