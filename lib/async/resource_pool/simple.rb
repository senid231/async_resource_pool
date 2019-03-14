require 'thread'
require_relative 'errors'

module Async
  module ResourcePool
    class Simple

      # @param limit [Integer] - max number of acquired resources, must be greater then 0.
      # @param wakeup_strategy [Symbol] - can be :immediately or :next_loop.
      def initialize(limit, wakeup_strategy = :immediately)
        raise ArgumentError, 'limit must be greater than 0' if limit <= 0
        unless [:immediately, :next_loop].include?(wakeup_strategy)
          raise ArgumentError, 'wakeup_strategy must be :immediately or :next_loop'
        end

        @limit = limit
        @wakeup_strategy = wakeup_strategy
        @owners = []
        @waiters = []
        @thread_mutex = Mutex.new
      end

      # Acquires resource for current fiber if available otherwise yield to reactor.
      # Will be resumed once resource available.
      # Will raise Async::ResourcePool::TimeoutError if timeout not nil and resource isn't available after timeout.
      # Will raise Async::ResourcePool::AlreadyOwnError if resource already acquired.
      # @param timeout [Integer|Float] - timeout in seconds (default nil).
      def acquire(timeout = nil)
        raise Async::ResourcePool::AlreadyOwnError.new if already_acquired?

        unless acquire_if_available
          timeout.nil? ? Async::Task.yield : wait_with_timeout(timeout)
          @thread_mutex.synchronize { @owners.push(Fiber.current) }
        end

        if block_given?
          begin
            yield
          ensure
            release
          end
        end

        nil
      end

      # Acquires resource for current fiber if resource available.
      # Will raise Async::ResourcePool::AlreadyOwnError if resource already acquired.
      # @return [True|False] returns true if resource was acquired.
      def try_acquire
        raise Async::ResourcePool::AlreadyOwnError.new if already_acquired?

        if acquire_if_available
          true
        else
          @waiters.delete(Fiber.current)
          false
        end
      end

      # Releases resource for current fiber.
      # Will resume first fiber that waits for resource immediately if wakeup_strategy == :immediately
      # Will resume first fiber that waits for resource in next reactor loop if wakeup_strategy == :next_loop
      # Will raise Async::ResourcePool::DoesNotOwnError if fiber does not own resource.
      def release
        raise Async::ResourcePool::DoesNotOwnError.new unless already_acquired?
        @owners.delete(Fiber.current)
        wakeup
      end

      # @return [True|False] returns true if resource already acquired by fiber
      def already_acquired?
        @owners.include?(Fiber.current)
      end

      # @return [True|False] returns true if pool has available resource
      def can_be_acquired?
        @owners.size < @limit
      end

      # @return [Hash] represents current state of resource pool.
      #   waiters - how many fibers waits for resource.
      #   owners - how many fibers own resource.
      #   limit - maximum of resources that can be owned simultaneously.
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
        return unless fiber.alive?

        if @wakeup_strategy == :immediately
          fiber.resume
        else
          Async::Task.current.reactor << fiber
        end
      end

      def wakeup_fiber(fiber)
        if @wakeup_strategy == :immediately
          fiber.resume
        else
          Async::Task.current.reactor << fiber
        end
      end

      def acquire_if_available
        fiber = Fiber.current

        @thread_mutex.synchronize do
          if can_be_acquired?
            @owners.push(fiber)
            true
          else
            @waiters.push(fiber)
            false
          end
        end
      end

      def wait_with_timeout(timeout)
        fiber = Fiber.current

        Async::Task.current.with_timeout(timeout) do |timer|
          begin
            Async::Task.yield
            timer.cancel
          rescue Async::TimeoutError => _
            @waiters.delete(fiber)
            raise Async::ResourcePool::TimeoutError.new(timeout)
          end
        end
      end

    end
  end
end
