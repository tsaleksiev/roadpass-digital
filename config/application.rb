require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module RoadpassDigital
  class Application < Rails::Application
    config.load_defaults 8.1
    config.autoload_lib(ignore: %w[assets tasks])
    config.api_only = true
    config.active_job.queue_adapter = :sidekiq
  end
end
