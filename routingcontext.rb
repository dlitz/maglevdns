require 'ipaddr'

class RoutingContext
  # query: a DNS::Message object
  def initialize(query, address)
    @data = {}
    @data[:query] = query
    @data[:address] = address
  end

  def binding
    # The default binding method is private.  This makes it public.
    super
  end

  def query
    return @data[:query]
  end

  # Return true if the RD bit was set in the query.
  def recursion_desired?
    return @data[:query].rd
  end

  # Return true if the client address matches the specified list of IP
  # address.  The parameter may also be a single address.
  def match_ip?(addresses)
    client_address = IPAddr.new(@data[:address][3])
    addresses = [addresses] if addresses.is_a?(String)
    for address in addresses
      match_address = IPAddr.new(address)
      return true if match_address.include?(client_address)
    end
    return false
  end

  # Return true if the query is for a name in the specified zone.
  def match_zone?(zone)
    q = @data[:query].qname.map { |label| label.downcase }
    z = DNS.parse_display_name(zone.downcase)
    return z == q[-z.length..-1]  # Return true if q ends with z
  end

end
