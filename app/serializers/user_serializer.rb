# frozen_string_literal: true

# Serializer for User objects in API responses
class UserSerializer < ApplicationSerializer
  def attributes
    {
      id: object.id,
      first_name: object.first_name,
      last_name: object.last_name,
      full_name: object.full_name,
      role: object.role
    }
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
