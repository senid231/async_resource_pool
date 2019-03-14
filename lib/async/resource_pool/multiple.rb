require_relative 'simple'

module Async
  module ResourcePool
    class Multiple < Simple

      # @return [Integer] how many resource have been acquired by fiber.
      def acquired_count
        @owners[Fiber.current]
      end

      # @return [True|False] returns true if resource already acquired by fiber.
      def already_acquired?
        acquired_count > 0
      end

      # @return [True|False] returns true if pool has available resource.
      # Depends on a limit for current resource pool.
      def can_be_acquired?
        @owners.values.sum < @limit
      end

      # @return [True|False] returns true if fiber allowed to acquire resource.
      # Always return false.
      def acquire_allowed?
        false
      end

      # @return [Hash] represents current state of resource pool.
      #   waiters - how many fibers waits for resource.
      #   owners - how many fibers own resource.
      #   limit - maximum of resources that can be owned simultaneously.
      def info
        {
            waiters: @waiters.size,
            owners: @owners.values.sum,
            limit: @limit
        }
      end

      private

      def initialize_owners
        Hash.new(0)
      end

      def add_owner
         @owners[Fiber.current] += 1
      end

      def remove_owner
        fiber = Fiber.current
        @owners[fiber] -= 1
        @owners.delete(fiber) if @owners[fiber] == 0
      end

    end
  end
end
