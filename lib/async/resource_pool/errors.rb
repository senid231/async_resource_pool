module Async
  module ResourcePool

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

  end
end
