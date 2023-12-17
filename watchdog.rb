
class Watchdog
  def initialize(queue)
    @queue = queue
  end

  def start
    puts 'Starting watchdog'
    Thread.new do
      loop do
        handle_timed_out_tests

        if queue.empty? # no more tests left
          puts 'Queue is empty. Stopping.'
          DRb.current_server.stop_service
          break
        end

        Kernel.sleep(1)
      end
    end
  end

  private

  attr_reader :queue

  def timed_out_tests
    queue.select_leased do
      # Emulate timeout by randomly repushing tests back to the queue
      # But it doesn't lead to infinite loop because WD use loop with delay of 1 sec: Kernel.sleep(1)
      rand(0..100) < FILE_TO_RETURN_BY_TIMEOUT_PERCENTAGE
    end.keys
  end


  def handle_timed_out_tests
    timed_out_tests.each do |test|
      puts "#{test} (Timeout:  but will be pushed back to the queue.}"

      queue.repush(test)
    end
  end
end
