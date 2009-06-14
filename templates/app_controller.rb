#--
# Rakefile for MaglevDNS
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

class ApplicationController < ::MaglevDNS::BaseController
  def handle_query
    #if recursion_desired? and match_ip? ["10.159.0.0/16", "127.0.0.1", "::1"] and match_zone? "example.com"
    #  forward_to :host => "10.0.0.2"
    #end
    #forward_to "10.0.0.1", :port => 40053
  end
end
