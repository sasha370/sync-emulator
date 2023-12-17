require 'drb/drb'

module Worker
  class Runner
    def self.join
      status = run_from_leader
      exit(status) if status != 0
    end

    def self.run_from_leader
      leader = DRbObject.new_with_uri(DRB_SERVER_URL)
      new(leader).run
    end

    def initialize(leader)
      @leader = leader
    end

    def run(*)
      puts "Connecting to leader"
      consume_queue
      0
    end

    attr_reader :leader

    def consume_queue
      while (file_path = leader.next_file_to_run)
        print '.'
        sleep WORKER_PROCESS_TEST_TIME * rand(1..10) # Emulate test run time

        report_file_to_leader(file_path)
      end
    rescue DRb::DRbConnError => e
      puts "Disconnected from leader, finishing: #{e} "
    rescue Exception => e # rubocop:disable Lint/RescueException
      report_file_to_leader(file_path, e)
      raise
    end

    def report_file_to_leader(file_path, exception = nil)
      print "-"

      leader.report_file(file_path)
    rescue DRb::DRbConnError => e
      raise e
    end
  end
end
