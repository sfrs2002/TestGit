class User::ApplicationController < ApplicationController
  layout 'layouts/user'

  before_filter :require_sign_in
end
