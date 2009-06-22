#--
# MaglevDNS
# Copyright (c) 2009 Dwayne C. Litzenberger <dlitz@dlitz.net>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++
require 'thread'

module MaglevDNS

  # Keeps track of running threads.
  class ThreadContainer
    def initialize
      @mutex = Mutex.new
      @threads = []
    end

    # Track the specified thread.
    def << (thread)
      @mutex.synchronize {
        @threads << thread
      }
      return self
    end

    # Invoke the request_stop method on all tracked threads.
    def request_stop
      @mutex.synchronize {
        for thread in @threads
          thread.request_stop
        end
      }
      return nil
    end

    # Wait for all tracked threads to complete.
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
end
