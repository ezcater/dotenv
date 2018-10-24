require "dotenv/rails"

# In Skyline (Docker and *NOT* the test environment)
if File.exist?("/.dockerenv") && ENV["RAILS_ENV"] != "test"
  Dotenv::Railtie.load
else # Running things the old way, meaning we need the overload behaviour
  Dotenv::Railtie.overload
end

