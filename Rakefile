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

require 'rubygems'

RDOC_FILES = FileList['COPYING.*', 'lib/**/*.rb']

gemspec = eval(File.read('maglevdns.gemspec'), binding, "maglevdns.gemspec", 1)
require 'rake/gempackagetask'
Rake::GemPackageTask.new(gemspec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rd|
  rd.main = "MaglevDNS"
  rd.title = "MaglevDNS - RDoc Documentation"
  rd.rdoc_files = RDOC_FILES
  rd.options += %w{ --charset UTF-8 --line-numbers }
end
