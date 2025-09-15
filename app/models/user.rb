# frozen_string_literal: true

# Represents users in the medical communication system.
# Supports three roles: patient, doctor, and admin with different message routing logic.
class User < ApplicationRecord
  # == Associations ==
  has_one :inbox, dependent: :destroy
  has_one :outbox, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :prescriptions, dependent: :destroy
  has_many :inbox_messages, through: :inbox, source: :messages
  has_many :outbox_messages, through: :outbox, source: :messages

  # == Callbacks ==
  after_create :create_inbox_and_outbox

  # == Scopes ==
  scope :patient, -> { where(is_patient: true) }
  scope :admin, -> { where(is_admin: true) }
  scope :doctor, -> { where(is_doctor: true) }

  # == Class Methods ==

  class << self
    # Returns the current user for the session.
    # Supports demo user switching in all environments for demo purposes.
    def current
      # Check for demo user switching (enabled in all environments for demo)
      demo_user_id = Thread.current[:demo_user_id]
      if demo_user_id
        demo_user = User.find_by(id: demo_user_id)
        return demo_user if demo_user
      end

      User.patient.first
    end

    # Set demo user for current thread (enabled in all environments for demo)
    def current_demo_user=(user)
      Thread.current[:demo_user_id] = user&.id
    end

    # Clear demo user for current thread
    def clear_demo_user
      Thread.current[:demo_user_id] = nil
    end

    # Returns the default admin user for system operations.
    def default_admin
      User.admin.first
    end

    # Returns the default doctor user for medical consultations.
    def default_doctor
      User.doctor.first
    end
  end

  # == Instance Methods ==

  # Returns the user's full name for display purposes.
  def full_name
    "#{first_name} #{last_name}"
  end

  # Determines the user's role in the medical communication system.
  def role
    if is_admin?
      'admin'
    elsif is_doctor?
      'doctor'
    else
      'patient'
    end
  end

  private

  # Automatically create inbox and outbox for new users
  def create_inbox_and_outbox
    create_inbox! unless inbox
    create_outbox! unless outbox
  end
end

# == Schema Information
#
# Table name: users
#
#  id         :uuid             not null, primary key
#  first_name :string
#  is_admin   :boolean          default(FALSE), not null
#  is_doctor  :boolean          default(FALSE), not null
#  is_patient :boolean          default(TRUE), not null
#  last_name  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
