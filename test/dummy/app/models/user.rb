class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # Users also adds :confirmable at boot.
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  before_validation :skip_confirmation_for_tests, on: :create, if: -> { Rails.env.test? }

  # Password sign-up calls this so Devise does not send its own mail.
  # That account stays unconfirmed until the email code. Other test creates
  # still confirm immediately so they can sign in.
  def skip_confirmation_notification!
    @defer_test_confirmation = true
    super
  end

  private

  def skip_confirmation_for_tests
    return if @defer_test_confirmation

    skip_confirmation! if respond_to?(:skip_confirmation!) && !confirmed?
  end
end
