# Rack::CSRF

A Rack middleware for CSRF protection without requiring tokens. This middleware provides protection against Cross-Site Request Forgery attacks by validating HTTP headers, particularly leveraging the `Sec-Fetch-Site` header and origin validation.

This gem is a port of Golang's [CrossOriginProtection](https://pkg.go.dev/net/http@master#CrossOriginProtection) to Ruby. Please see the [issue](https://github.com/golang/go/issues/73626) for more details.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rack-csrf'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install rack-csrf
```

## Usage

### Basic Usage

```ruby
require 'rack/csrf'

use Rack::CSRF
```

### With Options

```ruby
use Rack::CSRF,
  trusted_origins: ['https://trusted-domain.com', 'https://another-trusted.com'],
  exclude: ->(env) { env['PATH_INFO'] == '/webhook' }
```

## How It Works

The middleware protects against CSRF attacks by checking:

1. **Safe HTTP Methods**: `GET`, `HEAD`, and `OPTIONS` requests are always allowed
2. **Sec-Fetch-Site Header**: Modern browsers send this header with values:
   - `same-origin`: Request from the same origin (allowed)
   - `none`: Direct navigation (allowed)
   - `same-site`: Request from the same site but different origin (blocked by default)
   - `cross-site`: Request from a different site (blocked by default)
3. **Origin Validation**: When `Sec-Fetch-Site` is not present, falls back to comparing the `Origin` header with the `Host` header

## Configuration Options

### `trusted_origins`

An array of trusted origin URLs that should be allowed even for cross-site requests.

```ruby
use Rack::CSRF, trusted_origins: [
  'https://trusted-domain.com',
  'https://api.partner.com'
]
```

**Note**: Origins must be valid HTTP/HTTPS URLs. Invalid URLs will raise an `ArgumentError`.

### `exclude`

A proc/lambda that receives the Rack environment and returns `true` if the request should be excluded from CSRF protection.

```ruby
use Rack::CSRF, exclude: ->(env) do
  # Skip CSRF protection for webhook endpoints
  env['PATH_INFO'].start_with?('/webhooks/') ||
  # Skip for API endpoints with API key authentication
  env['HTTP_X_API_KEY'].present?
end
```

## Examples

### Rails Application

```ruby
# config/application.rb
class Application < Rails::Application
  config.middleware.use Rack::CSRF,
    trusted_origins: ['https://admin.myapp.com'],
    exclude: ->(env) { env['PATH_INFO'].start_with?('/api/') }
end
```

## Browser Compatibility

- `Sec-Fetch-Site` header is supported in:
  - Chrome 76+
  - Firefox 90+
  - Safari 15.4+
- For older browsers, the middleware falls back to `Origin` header validation

## References

- [Sec-Fetch-Site Header Specification](https://w3c.github.io/webappsec-fetch-metadata/)
- [OWASP CSRF Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/y-yagi/rack-csrf. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/y-yagi/rack-csrf/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Rack::Csrf project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/rack-csrf/blob/main/CODE_OF_CONDUCT.md).
