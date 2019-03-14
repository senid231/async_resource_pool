# AsyncResourcePool

[![Gem Version](https://badge.fury.io/rb/async_resource_pool.svg)](https://rubygems.org/gems/async_resource_pool)
[![Build Status](https://travis-ci.com/senid231/async_resource_pool.svg?branch=master)](https://travis-ci.com/senid231/async_resource_pool)

TODO:
* write description
* acquire more than one connection

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'async_resource_pool'
```

or 

```ruby
gem 'async/resource_pool'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install async_resource_pool

## Usage

TODO: Write usage instructions here

```ruby
pool = Async::ResourcePool.new(2)

Async do
  
    Async do
        pool.acquire do
            Async::Task.current.sleep(6) 
        end
    end
    
    Async do
        pool.acquire
        Async::Task.current.sleep(6)
        pool.release
    end
    
    Async do
        begin
            pool.acquire(5) do
                # will not be here because of timeout
            end
        rescue Async::ResourcePool::TimeoutError => _
            # will be here
        end
    end
  
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/senid231/async_resource_pool. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the AsyncResourcePool project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/async_resource_pool/blob/master/CODE_OF_CONDUCT.md).
