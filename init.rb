if (defined? Rails.env ? Rails.env : RAILS_ENV) == "production"
  if defined? Rails.configuration && defined? Rails.configuration.middleware
    Rails.configuration.middleware.use(Hassle)
  elsif defined? ActionController::Dispatcher && defined? ActionController::Dispatcher.middleware
    ActionController::Dispatcher.middleware.use Hassle
  end  
end