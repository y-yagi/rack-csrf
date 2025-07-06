# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rack/csrf"
require "rack/test"
require "debug"

class Minitest::Test
  include Rack::Test::Methods

  def app
    Rack::Builder.new do
      use Rack::CSRF

      run lambda { |_env| [200, {}, ["Hello World"]] }
    end.to_app
  end
end

require "minitest/autorun"
