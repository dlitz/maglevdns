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

# Version information
require 'maglevdns/version'

# Abstract data types and base classes
require 'maglevdns/exception'
require 'maglevdns/dns'
require 'maglevdns/request'
require 'maglevdns/stoppablethread'

# DNS packets flow through the following files (in reverse order)
require 'maglevdns/scriptevalcontext'
require 'maglevdns/requesthandlerthread'
require 'maglevdns/threadstopper'
require 'maglevdns/dispatcherthread'
require 'maglevdns/server'

# Listeners
require 'maglevdns/tcpconnectionthread'
require 'maglevdns/tcplistener'
require 'maglevdns/udplistener'

