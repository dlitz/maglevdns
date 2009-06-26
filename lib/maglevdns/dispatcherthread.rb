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

require 'maglevdns/stoppablethread'

module MaglevDNS

  class DispatcherThread < StoppableThread

    def initialize(request_queue, script_filename)
      @request_queue = request_queue
      @script_filename = script_filename
      super()
    end

    # Ask this thread to stop.
    def request_stop
      super { @request_queue << :NOOP }
    end

    private
    def thread_main
      loop do
        request = @request_queue.shift
        check_stop
        next if request == :NOOP
        RequestHandlerThread.new(request, @script_filename)
      end
    end

  end

end
