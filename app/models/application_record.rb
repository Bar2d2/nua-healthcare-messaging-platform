# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  self.implicit_order_column = 'created_at'

  before_create :generate_uuid, if: :uuid_primary_key?

  private

  def generate_uuid
    self.id = SecureRandom.uuid if id.blank?
  end

  def uuid_primary_key?
    klass = self.class
    klass.primary_key == 'id' && klass.columns_hash['id']&.type == :string
  end
end
