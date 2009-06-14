require 'maglevdns/version'
require 'maglevdns/threadcontainer'
require 'maglevdns/requesthandler'
require 'maglevdns/basecontroller'
require 'maglevdns/dispatcher'
require 'maglevdns/listener'
require 'maglevdns/dns'
require 'maglevdns/main'

module MaglevDNS
  MAGLEV_ROOT_DIR = File.dirname(__FILE__) + "/.."
  MAGLEV_TEMPLATES_DIR = MAGLEV_ROOT_DIR + "/templates"
end
