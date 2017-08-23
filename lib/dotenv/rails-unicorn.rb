# Extension of `dotenv/rails-now` initializer, which loads ENV config
# before Rails is loaded with the addition of using the current ENV overload
# behavior to make sure zero-downtime restarts of Unicorn or similar app servers
# pick up changes in ENV config and overload over the previously loaded ENV

require "dotenv/rails"
Dotenv::Railtie.overload
