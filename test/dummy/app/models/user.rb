class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # Users 0.32 also adds :confirmable at boot.
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  before_validation :skip_confirmation_for_tests, on: :create, if: -> { Rails.env.test? }

  private

  def skip_confirmation_for_tests
    skip_confirmation! if respond_to?(:skip_confirmation!) && !confirmed?
  end
end
