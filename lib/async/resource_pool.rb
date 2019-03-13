require 'async'

module Async
  class ResourcePool
    VERSION = '0.1.0'

    class Error < StandardError
    end

    class DoesNotOwnError < Error
      def initialize
        super('current fiber does not own this resource')
      end
    end

    class AlreadyOwnError < Error
      def initialize
        super('current fiber already own this resource')
      end
    end

    class TimeoutError < Error
      def initialize(timeout)
        super("timeout #{timeout} seconds was elapsed")
      end
    end

    def initialize(limit)
      @limit = limit
      @owners = []
      @waiters = []
    end

    def acquire(timeout = nil)
      raise AlreadyOwnError.new if already_acquired?

      unless can_be_acquired?
        timeout.nil? ? wait : wait_with_timeout(timeout)
      end

      @owners.push(Fiber.current)

      if block_given?
        begin
          yield
        ensure
          release
        end
      end

      nil
    end

    def release
      raise DoesNotOwnError.new unless already_acquired?
      @owners.delete(Fiber.current)
      wakeup
    end

    def already_acquired?
      @owners.include?(Fiber.current)
    end

    def can_be_acquired?
      @owners.size < @limit
    end

    def info
      {
          waiters: @waiters.size,
          owners: @owners.size,
          limit: @limit
      }
    end

    private

    def wakeup
      return if @waiters.empty?
      fiber = @waiters.shift
      fiber.resume if fiber.alive?
    end

    def wait
      @waiters.push(Fiber.current)
      Async::Task.yield
    end

    def wait_with_timeout(timeout)
      fiber = Fiber.current
      @waiters.push(Fiber.current)

      Async::Task.current.with_timeout(timeout) do |timer|
        begin
          Async::Task.yield
          timer.cancel
        rescue Async::TimeoutError => _
          @waiters.delete(fiber)
          raise TimeoutError.new(timeout)
        end
      end
    end

  end
end
