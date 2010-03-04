if Rails.env.production?
  Rails::Application.middleware.use Hassle
end