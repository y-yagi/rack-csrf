# frozen_string_literal: true

require "test_helper"

class Rack::TestCsrf < Minitest::Test
  def test_get_request
    get "/"
    assert_equal 200, last_response.status
  end

  def test_head_request
    head "/"
    assert_equal 200, last_response.status
  end

  def test_options_request
    options "/"
    assert_equal 200, last_response.status
  end

  def test_without_sec_fetch_site_header
    post "/"
    assert_equal 200, last_response.status
  end

  def test_host_and_origin_are_same
    post "/", {}, { "Host" => "example.com", "Origin" => "http://example.com" }
    assert_equal 200, last_response.status
  end

  def test_sec_fetch_site_header_is_none
    post "/", {}, { "Sec-Fetch-Site" => "none" }
    assert_equal 200, last_response.status
  end

  def test_sec_fetch_site_header_is_same_origin
    post "/", {}, { "Sec-Fetch-Site" => "same-origin" }
    assert_equal 200, last_response.status
  end

  def test_sec_fetch_site_header_is_same_site
    post "/", {}, { "Sec-Fetch-Site" => "same-site" }
    assert_equal 403, last_response.status
  end

  def test_sec_fetch_site_header_is_cross_site
    post "/", {}, { "Sec-Fetch-Site" => "cross-site" }
    assert_equal 403, last_response.status
  end

  def test_trusted_origins_options
    trusted_origin = "https://trusted.example.com"
    app = Rack::Builder.new do
      use Rack::CSRF, trusted_origins: [trusted_origin]
      run lambda { |_env| [200, {}, ["Hello World"]] }
    end.to_app

    rack_test_session = Rack::Test::Session.new(app)
    rack_test_session.post "/", {}, { "Sec-Fetch-Site" => "cross-site", "Origin" => trusted_origin }
    assert_equal 200, rack_test_session.last_response.status

    rack_test_session.post "/", {}, { "Sec-Fetch-Site" => "cross-site", "Origin" => "http://untrusted.example.com" }
    assert_equal 403, rack_test_session.last_response.status
  end

  def test_trusted_origins_options_are_invalid
    assert_raises ArgumentError do
      Rack::Builder.new do
        use Rack::CSRF, trusted_origins: "https://trusted.example.com"
      end.to_app
    end

    assert_raises ArgumentError do
      Rack::Builder.new do
        use Rack::CSRF, trusted_origins: "trusted.example.com"
      end.to_app
    end
  end

  def test_exclude_options
    app = Rack::Builder.new do
      use Rack::CSRF, exclude: -> (env) { env["PATH_INFO"] == "/excluded" }
      run lambda { |_env| [200, {}, ["Hello World"]] }
    end.to_app

    rack_test_session = Rack::Test::Session.new(app)
    rack_test_session.post "/excluded", {}, { "Sec-Fetch-Site" => "cross-site" }
    assert_equal 200, rack_test_session.last_response.status

    rack_test_session.post "/not-excluded", {}, { "Origin" => "http://example.com", "Host" => "dummy.example.com" }
    assert_equal 403, rack_test_session.last_response.status
  end
end
