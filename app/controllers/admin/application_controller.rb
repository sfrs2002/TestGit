class Admin::ApplicationController < ApplicationController
  layout 'layouts/admin'

  before_filter :require_admin
end
