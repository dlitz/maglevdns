require 'lib/maglevdns/version'

Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = "maglev-dns"
  s.version = MaglevDNS::PKG_VERSION
  s.summary = "DNS application framework"
  s.description = <<-EOF.strip.gsub(/\n\s+/, ' ')
    MaglevDNS is a DNS application framework, similar to Ruby on Rails but
    for DNS queries instead of HTTP requests.
  EOF
  s.authors = ["Dwayne C. Litzenberger"]
  s.email = ["dlitz@dlitz.net"]
  s.homepage = "http://www.dlitz.net/software/maglev-dns"
  s.require_path = 'lib'
  s.files = Dir.glob ['lib/**/*.rb', 'templates/**/*']
  s.executables = ['maglevdns']
  s.has_rdoc = true
  s.rubyforge_project = "maglev-dns"
end
