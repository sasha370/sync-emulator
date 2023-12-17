require 'drb'
require_relative 'leader'
require_relative 'worker/runner'
require 'pry'

DRB_SERVER_URL = 'druby://localhost:8787'.freeze


NUMBER_OF_WORKERS = 200
FILES_TO_RUN_PERCENTAGE = 100 # Emulate running only part of the tests
FILE_TO_RETURN_BY_TIMEOUT_PERCENTAGE = 0 # (1..5) Emulate timeout by randomly repushing tests back to the queue
WORKER_PROCESS_TEST_TIME = 0.1 # Emulate test run time
MULTIPLIER = 20

# Prepare tests
# We use base 2000 for Features
# and base 11000 for Specs
tests = JSON.parse(File.read('tests.json')).keys
result_tests = tests.dup
MULTIPLIER.times do |i|
  new_tests = tests.map { |test| "#{test}_#{i}" }
  result_tests.concat(new_tests)
end
TESTS = result_tests

module App
  class Start
    def self.run
      puts "Starting #{NUMBER_OF_WORKERS} workers"
      started = Time.now
      start_leader
      start_workers
      time = Time.now - started
      puts "\nDuration: #{time}"
    end

    def self.start_leader
      Thread.new { Leader.start_service }
    end

    def self.start_workers
      treads = []
      NUMBER_OF_WORKERS.times do
        treads << Thread.new do
          sleep 0.5 # Let's wait for the leader to start
          Worker::Runner.join
        end
      end
      treads.each(&:join)
    end
  end
end

App::Start.run
