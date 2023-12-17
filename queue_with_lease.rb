require 'set'
require 'timeout'
require 'monitor'

class QueueWithLease
  include MonitorMixin

  SYNC_TIMEOUT_SEC = 60

  attr_reader :initialized_at, :last_activity_at, :mutex

  def initialize(entries = [])
    super()
    @entries = entries.dup
    @leased = {}
    @completed = Set.new
    @initialized_at = Time.now
    @mutex = Mutex.new
  end

  def lease
    loop do
      sleep 0.1

      next if entries.empty?

      entry = synchronize_with_timeout { entries.pop }
      next unless entry

      next if completed?(entry)

      record_lease(entry)
      return entry
    end
  end

  def repush(entry)
    synchronize_with_timeout do
      leased.delete(entry)

      entries.insert(entries.empty? ? -1 : -2, entry)
    end
  end

  def release(entry)
    return if completed?(entry)

    synchronize_with_timeout do
      leased.delete(entry)
      completed.add(entry)
    end
  end

  def completed?(entry)
    synchronize_with_timeout { completed.include?(entry) }
  end

  def empty?
    size.zero?
  end

  def size
    synchronize_with_timeout { leased.size + entries.size }
  end

  def completed_size
    completed.size
  end

  def leased_size
    leased.size
  end

  def select_leased(&block)
    synchronize_with_timeout { leased.dup.select(&block) }
  end

  def entries_list
    synchronize_with_timeout { entries }
  end

  def visited?
    @last_activity_at != nil
  end

  private

  attr_reader :entries, :completed, :leased

  def record_lease(entry)
    synchronize_with_timeout do
      leased[entry] = Time.now
      @last_activity_at = Time.now
    end
  end

  def synchronize_with_timeout(&block)
    Timeout.timeout(SYNC_TIMEOUT_SEC) do
      mutex.synchronize do
        yield block
      end
    end
  rescue Timeout::Error
    raise 'Timeout while waiting for synchronization (deadlock)!'
  end
end
