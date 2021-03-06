require "dotenv"

# Fix for rspec rake tasks loading in development
#
# Dotenv loads environment variables when the Rails application is initialized.
# When running `rake`, the Rails application is initialized in development.
# Rails includes some hacks to set `RAILS_ENV=test` when running `rake test`,
# but rspec does not include the same hacks.
#
# See https://github.com/bkeepers/dotenv/issues/219
if defined?(Rake.application)
  is_running_specs = Rake.application.top_level_tasks.grep(/^spec(:|$)/).any?
  Rails.env = ENV["RAILS_ENV"] ||= "test" if is_running_specs
end

Dotenv.instrumenter = ActiveSupport::Notifications

# Watch all loaded env files with Spring
begin
  require "spring/commands"
  ActiveSupport::Notifications.subscribe(/^dotenv/) do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    Spring.watch event.payload[:env].filename if Rails.application
  end
rescue LoadError
  # Spring is not available
end

module Dotenv
  # Dotenv Railtie for using Dotenv to load environment from a file into
  # Rails applications
  class Railtie < Rails::Railtie
    # Public: Load dotenv
    #
    # This will get called during the `before_configuration` callback, but you
    # can manually call `Dotenv::Railtie.load` if you needed it sooner.
    def load
      Dotenv.load(*dotenv_files)
    end

    # Internal: `Rails.root` is nil in Rails 4.1 before the application is
    # initialized, so this falls back to the `RAILS_ROOT` environment variable,
    # or the current working directory.
    def root
      Rails.root || Pathname.new(ENV["RAILS_ROOT"] || Dir.pwd)
    end

    # Rails uses `#method_missing` to delegate all class methods to the
    # instance, which means `Kernel#load` gets called here. We don't want that.
    def self.load
      instance.load
    end

    def overload
      # Because we're using the Dotenv Overload API, process ENV files in reverse order -
      # from least specific to most specific, such that more specific environment configuration
      # overload less specific configuration and all of these overload the loaded environment.
      reversed_dotenv_files = dotenv_files.reverse
      Dotenv.overload(*reversed_dotenv_files)
    end

    # Provides a Hook for Rails Overload API
    # This loads values OVER any existing definition, which is essential for reloading processes
    # like you find in Unicorn with hot restart capability.  Otherwise, values will never be
    # updated successfully without a full restart.
    def self.overload
      instance.overload
    end

    config.before_configuration { load }

    private

    def dotenv_files
      [
        root.join(".env.#{Rails.env}.local"),
        (root.join(".env.local") unless Rails.env.test?),
        root.join(".env.#{Rails.env}"),
        root.join(".env")
      ].compact
    end
  end
end
