# frozen_string_literal: true

# Recording Studio 6.5 needs an actor on writes. Users/Devise controllers
# do not always run ApplicationController's Current.actor assignment.
Warden::Manager.after_set_user do |user, _auth, _opts|
  Current.actor = user
end

Warden::Manager.before_logout do |_user, _auth, _opts|
  Current.actor = nil
end
