class ThreadContainer
  def initialize
    @mutex = Mutex.new
    @threads = []
  end

  def << (thread)
    @mutex.synchronize {
      @threads << thread
    }
    return self
  end

  def request_stop
    @mutex.synchronize {
      for thread in @threads
        thread.request_stop
      end
    }
    return nil
  end

  def join
    @mutex.synchronize {
      for thread in @threads
        thread.join
      end
    }
    return nil
  end

  # Prune threads that are no longer alive.
  def prune!
    @mutex.synchronize {
      @threads.delete_if { |thread| not thread.alive? }
    }
    return nil
  end

end
