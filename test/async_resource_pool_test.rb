require "test_helper"

class AsyncResourcePoolTest < Minitest::Test
  def setup
    @pool = Async::ResourcePool.new(2)
  end

  def test_without_timeout_and_without_block
    calls = []
    expected_calls = %w(
      1_1
      1_2
      2_1
      2_2
      3_1
      1_3
      3_2
      1_4
      2_3
      2_4
      3_3
      3_4
    )

    Async do

      Async do
        calls.push('1_1')
        @pool.acquire
        calls.push('1_2')
        Async::Task.current.sleep(2)
        calls.push('1_3')
        @pool.release
        calls.push('1_4')
      end

      Async do
        calls.push('2_1')
        @pool.acquire
        calls.push('2_2')
        Async::Task.current.sleep(2)
        calls.push('2_3')
        @pool.release
        calls.push('2_4')
      end

      Async do
        calls.push('3_1')
        @pool.acquire
        calls.push('3_2')
        Async::Task.current.sleep(2)
        calls.push('3_3')
        @pool.release
        calls.push('3_4')
      end

    end.wait

    assert_equal expected_calls, calls
  end

  def test_without_timeout_and_with_block
    calls = []
    expected_calls = %w(
      1_1
      1_2
      2_1
      2_2
      3_1
      1_3
      3_2
      1_4
      2_3
      2_4
      3_3
      3_4
    )

    Async do

      Async do
        calls.push('1_1')
        @pool.acquire do
          calls.push('1_2')
          Async::Task.current.sleep(2)
          calls.push('1_3')
        end
        calls.push('1_4')
      end

      Async do
        calls.push('2_1')
        @pool.acquire do
          calls.push('2_2')
          Async::Task.current.sleep(2)
          calls.push('2_3')
        end
        calls.push('2_4')
      end

      Async do
        calls.push('3_1')
        @pool.acquire do
          calls.push('3_2')
          Async::Task.current.sleep(2)
          calls.push('3_3')
        end
        calls.push('3_4')
      end

    end.wait

    assert_equal expected_calls, calls
  end

  def test_with_timeout_and_without_block_when_timeout_raise
    calls = []
    raised_exception = nil
    expected_calls = %w(
      1_1
      1_2
      2_1
      2_2
      3_1
      1_3
      1_4
      2_3
      2_4
    )

    Async do

      Async do
        calls.push('1_1')
        @pool.acquire
        calls.push('1_2')
        Async::Task.current.sleep(3)
        calls.push('1_3')
        @pool.release
        calls.push('1_4')
      end

      Async do
        calls.push('2_1')
        @pool.acquire
        calls.push('2_2')
        Async::Task.current.sleep(3)
        calls.push('2_3')
        @pool.release
        calls.push('2_4')
      end

      Async do
        begin
          calls.push('3_1')
          @pool.acquire(1)
          # this 3 lines of code will never run
          calls.push('3_2')
          @pool.release
          calls.push('3_3')
        rescue StandardError => e
          raised_exception = e
        end
      end

    end.wait

    assert_kind_of Async::ResourcePool::TimeoutError, raised_exception
    assert_equal 'timeout 1 seconds was elapsed', raised_exception.message
    assert_equal expected_calls, calls
  end

  def test_with_timeout_and_with_block_when_timeout_raise
    calls = []
    raised_exception = nil
    expected_calls = %w(
      1_1
      1_2
      2_1
      2_2
      3_1
      1_3
      1_4
      2_3
      2_4
    )

    Async do

      Async do
        calls.push('1_1')
        @pool.acquire do
          calls.push('1_2')
          Async::Task.current.sleep(3)
          calls.push('1_3')
        end
        calls.push('1_4')
      end

      Async do
        calls.push('2_1')
        @pool.acquire do
          calls.push('2_2')
          Async::Task.current.sleep(3)
          calls.push('2_3')
        end
        calls.push('2_4')
      end

      Async do
        begin
          calls.push('3_1')
          @pool.acquire(1) do
            # this line of code will never run
            calls.push('3_2')
          end
          # this line of code will never run
          calls.push('3_3')
        rescue StandardError => e
          raised_exception = e
        end
      end

    end.wait

    assert_kind_of Async::ResourcePool::TimeoutError, raised_exception
    assert_equal 'timeout 1 seconds was elapsed', raised_exception.message
    assert_equal expected_calls, calls
  end
end
