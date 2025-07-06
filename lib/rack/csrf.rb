# frozen_string_literal: true

require_relative "csrf/version"
require "rack"
require "uri"

module Rack
  class CSRF
    def initialize(app, opts = {})
      @app = app
      @exclude = opts[:exclude]
      set_trusted_origins(opts)
    end

    def call(env)
      return @app.call(env) if safe_request?(env)

      [ 403, {}, ["Forbidden\n"]]
    end

    private

    def set_trusted_origins(opts)
      @trusted_origins = {}
      return unless opts[:trusted_origins]

      raise ArgumentError, "trusted_origins must be an array" unless opts[:trusted_origins].is_a?(Array)

      opts[:trusted_origins].each do |origin|
        uri = URI.parse(origin)
        raise ArgumentError, "trusted_origins has invalid data: #{origin}" unless uri.is_a?(URI::HTTP)

        @trusted_origins[uri.origin] = true
      end
    end

    def safe_request?(env)
      return true if safe_request_method?(env)
      return true if request_from_safe_site?(env)

      false
    end

    def safe_request_method?(env)
      %w(GET HEAD OPTIONS).include?(env["REQUEST_METHOD"]) ? true : false
    end

    def request_from_safe_site?(env)
      sec_fetch_site = env["Sec-Fetch-Site"]
      return true if %w(same-origin none).include?(sec_fetch_site)
      if env["Sec-Fetch-Site"].to_s != ""
        return (exclude_request?(env) ? true : false)
      end

      origin = env["Origin"]
      return true if origin.to_s == ""
      uri = URI.parse(origin)
      return true if uri.host == env["Host"]

      exclude_request?(env) ? true : false
    end

    def exclude_request?(env)
      return true if @trusted_origins[env["Origin"]]
      return true if @exclude && @exclude.call(env)
      false
    end
  end
end
