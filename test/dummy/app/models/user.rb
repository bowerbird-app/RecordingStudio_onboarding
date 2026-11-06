class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Recording Studio 6.5 requires an actor on Directory profile writes.
  # OmniAuth creates the user before Warden signs them in.
  after_create :assume_actor_for_directory_writes

  private

  def assume_actor_for_directory_writes
    return unless Thread.current[:recording_studio_user_directory_create]

    Current.actor ||= self
  end
end
