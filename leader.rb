require 'drb/drb'
require 'json'
require_relative 'queue_with_lease'
require_relative 'watchdog'
require_relative 'worker/runner'
require_relative 'drb_callable'

class Leader
  extend DRbCallable
  attr_reader :queue

  class << self
    def start_service
      files =  TESTS.first((TESTS.length * FILES_TO_RUN_PERCENTAGE/100).ceil)
      queue = QueueWithLease.new(files)

      leader = new(queue)

      Watchdog.new(queue).start
      DRb.start_service(DRB_SERVER_URL , leader, )
      puts 'Leader ready'
      DRb.thread.join

      count_mismatch = (queue.size + queue.completed_size != files.count)

      if count_mismatch
        puts "Build count_mismatch!"
        Kernel.exit(1)
      else
        puts "Build succeeded. Files processed: #{queue.completed_size}"
      end
    end
  end

  # Object shared through DRb is open for any calls. Including eval calls
  # A simple way to prevent it - undef
  undef :instance_eval
  undef :instance_exec


  def initialize(queue)
    @queue = queue
    puts "Queue size: #{queue.size}"
  end

  drb_callable def next_file_to_run
    queue.lease.tap do |file|
      print "<"
    end
  end

  drb_callable def report_file(file_path, exception = nil)
    print '>'

    return if queue.completed?(file_path)

    if exception
      puts "Retrying #{file_path}"
      will_be_retried = true
      queue.repush(file_path)
      return
    end

    nil
  ensure
    queue.release(file_path) unless will_be_retried
    log_completed_percent
  end

  def log_completed_percent
    @logged_percents ||= []
    log_every = 10

    completed_percent = (queue.completed_size.to_f / (queue.size + queue.completed_size).to_f * 100).to_i
    bucket = completed_percent / log_every * log_every

    return if @logged_percents.include?(bucket)

    @logged_percents << bucket

    puts "Completed: #{completed_percent}%"
  end
end
