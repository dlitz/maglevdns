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
require 'enumerator'
require 'strscan'

module MaglevDNS
  module DNS

    # Given a human-readable DNS name as a string, return the corresponding
    # array of labels.
    #
    # Example:
    #   parse_display_name('john\.smith.example.com') #=> ["john.smith", "example", "com"]
    def self.parse_display_name(display_name)
      name = []
      label = ""
      s = StringScanner.new(display_name)
      until s.eos?
        if s.scan /\A[^.\\]+/
          label += s.matched
        elsif s.scan /\A\./
          name << label
          label = ""
        elsif s.scan /\A\\(\d{1,3})/    # \DDD (decimal octet)
          label += $1.to_i.chr
        elsif s.scan /\A\\([^\d])/    # \DDD (decimal octet)
          label += $1
        end
      end
      name << label unless label.empty?
      return name.select{ |label| not label.empty? }
    end

    # Given an array of labels, return the corresponding human-readable DNS
    # name.
    #
    # Example:
    #   encode_display_name(["john.smith", "example", "com"]) #=> 'john\.smith.example.com'
    def self.encode_display_name(labels)
      return name.map{|label| label.gsub(/([\\.])/, '\\\1')}.join(".").select{ |label| not label.empty? }
    end

    module HeaderParser

      # RCODE values
      module RCODE
        NOERROR = 0
        FORMERR = 1
        SERVFAIL = 2
        NXDOMAIN = 3
        NOTIMP = 4
        REFUSED = 5
      end

      # Opcode values
      module OPCODE
        QUERY = 0
        IQUERY = 1
        STATUS = 2
      end

      # Bitfield Masks & Shifts
      module BMS
        # Masks and shifts for header_flags
        RCODE_SHIFT = 0
        RCODE_MASK = 0x000f
        AD_SHIFT = 5      # Authentic Data - RFC 4035
        AD_MASK = (1<<5)
        CD_SHIFT = 6      # Checking Disabled - RFC 4035
        CD_MASK = (1<<6)
        RA_SHIFT = 7
        RA_MASK = (1<<7)
        RD_SHIFT = 8
        RD_MASK = (1<<8)
        TC_SHIFT = 9
        TC_MASK = (1<<9)
        AA_SHIFT = 10
        AA_MASK = (1<<10)
        OPCODE_SHIFT = 11
        OPCODE_MASK = (0xf<<11)
        QR_SHIFT = 15
        QR_MASK = (1<<15)
      end

      def id
        return @msg[0,2].unpack("n")[0]
      end

      def id=(value)
        return @msg[0,2] = [value].pack("n")
      end

      def header_flags
        return @msg[2,2].unpack("n")[0]
      end

      def header_flags=(value)
        return @msg[2,2] = [value].pack("n")
      end

      def qdcount
        return @msg[4,2].unpack("n")[0]
      end

      def ancount
        return @msg[6,2].unpack("n")[0]
      end

      def nscount
        return @msg[8,2].unpack("n")[0]
      end

      def arcount
        return @msg[10,2].unpack("n")[0]
      end

      def rcode
        return (header_flags & BMS::RCODE_MASK) >> BMS::RCODE_SHIFT
      end

      def rcode=(value)
        header_flags = (header_flags & ~BMS::RCODE_MASK) | ((value << BMS::RCODE_SHIFT) & BMS::RCODE_MASK)
      end

      def ra
        return (header_flags >> 7) & 1
      end

      def ra=(value)
        header_flags = (header_flags & ~BMS::RA_MASK) | ((value << BMS::RA_SHIFT) & BMS::RA_MASK)
      end

      def rd
        return (header_flags >> 8) & 1
      end

      def rd=(value)
        header_flags = (header_flags & ~BMS::RD_MASK) | ((value << BMS::RD_SHIFT) & BMS::RD_MASK)
      end

      def tc
        return (header_flags >> 9) & 1
      end

      def tc=(value)
        header_flags = (header_flags & ~BMS::TC_MASK) | ((value << BMS::TC_SHIFT) & BMS::TC_MASK)
      end

      def aa
        return (header_flags >> 10) & 1
      end

      def aa=(value)
        header_flags = (header_flags & ~BMS::AA_MASK) | ((value << BMS::AA_SHIFT) & BMS::AA_MASK)
      end

      def opcode
        return (header_flags >> 11) & 0xf
      end

      def opcode=(value)
        header_flags = (header_flags & ~BMS::OPCODE_MASK) | ((value << BMS::OPCODE_SHIFT) & BMS::OPCODE_MASK)
      end

      def qr
        return (header_flags >> 15) & 1
      end

      def qr=(value)
        header_flags = (header_flags & ~BMS::QR_MASK) | ((value << BMS::QR_SHIFT) & BMS::QR_MASK)
      end

    end

    module NameParser
      def raw_name_at(offset)
        raise ArgumentError.new("First argument must be Integer") unless offset.is_a?(Integer)
        raise ArgumentError.new("Negative offsets not allowed") if offset < 0
        raise ArgumentError.new("Message corrupt (truncated) (offset=#{offset.inspect}; msglength=#{@msg.length}") if offset >= @msg.length
        p = offset
        name = ""
        loop do
          label = raw_label_at(p)
          name += label
          p += label.length

          n = label[0].ord
          break if n == 0 # End of normal name
          break if (n & 0xc0) == 0xc0   # End of compressed name
        end
        return name
      end

      def raw_label_at(offset)
        raise ArgumentError.new("First argument must be Integer") unless offset.is_a?(Integer)
        raise ArgumentError.new("Negative offsets not allowed") if offset < 0
        raise ArgumentError.new("Message corrupt (truncated)") if offset >= @msg.length
        n = @msg[offset].ord
        if (n & 0xc0) == 0  # 0 0
          # Normal label.  n is the length of the label
          length = n+1
        elsif (n & 0xc0) == 0xc0  # 1 1
          # Pointer label (used in DNS message compression)
          length = 2
        else
          raise ArgumentError.new("Unrecognized label type: 0x#{n.to_s(16)}")
        end
        retval = @msg[offset,length]
        raise ArgumentError.new("Message corrupt (truncated)") if retval.nil? or retval.length != length
        return retval
      end

      def name_at(offset)
        name = []
        until ((raw_label = raw_label_at(offset)) == "\0")
          n = raw_label[0].ord
          if (n & 0xc0) == 0  # 0 0
            # Normal label.  n is the length of the label
            name << raw_label[1,n]
            offset += raw_label.length
          elsif (n & 0xc0) == 0xc0  # 1 1
            # Pointer label (used in DNS message compression)
            offset = raw_label.unpack("n")[0] & 0x3fff
          else
            raise ArgumentError.new("Unrecognized label type: 0x#{n.to_s(16)}")
          end
        end
        return name
      end
    end

    module QuestionParser
      include NameParser

      def qname
        return nil if qdcount == 0
        raise ArgumentError.new("Don't know how to handle qdcount > 1") if qdcount > 1
        return name_at(@cache[:question][:offset])
      end

      def raw_qname
        return nil if qdcount == 0
        raise ArgumentError.new("Don't know how to handle qdcount > 1") if qdcount > 1
        return @msg[@cache[:question][:offset],@cache[:question][:qname_length]]
      end


      def qtype
        return nil if qdcount == 0
        raise ArgumentError.new("Don't know how to handle qdcount > 1") if qdcount > 1
        return @msg[@cache[:question][:qtype_offset],2].unpack("n")[0]
      end

      def qclass
        return nil if qdcount == 0
        raise ArgumentError.new("Don't know how to handle qdcount > 1") if qdcount > 1
        return @msg[@cache[:question][:qclass_offset],2].unpack("n")[0]
      end

      protected
      def rebuild_question_cache
        case qdcount
        when 0
          @cache[:question] = {:offset => 12, :length => 0}
        when 1
          offset = 12
          raw_name = raw_name_at(offset)
          length = raw_name.length  # QNAME
          length += 2   # QTYPE
          length += 2   # QCLASS
          raise ArgumentError.new("Message corrupt (truncated)") if offset+length > @msg.length
          @cache[:question] = {
            :offset => offset,
            :length => length,
            :qname_length => raw_name.length,
            :qtype_offset => 12 + raw_name.length,
            :qclass_offset => 12 + raw_name.length + 2,
          }
        else
          raise ArgumentError.new("Don't know how to handle qdcount > 1") if qdcount > 1
        end
      end
    end

    class RR
      def initialize(msg, section, i, offset, raw_rr)
        @msg = msg
        @section = section
        @i = i
        @offset = offset
        @raw = raw_rr
        @name_length = raw_name.length  # cached
      end

      def raw_name
        @msg.send(:raw_name_at, @offset)
      end

      def name
        @msg.send(:name_at, @offset)
      end

      def type
        @raw[@name_length,2].unpack("n")[0]
      end

      def klass
        @raw[@name_length+2,2].unpack("n")[0]
      end

      def ttl
        @raw[@name_length+4,4].unpack("N")[0]
      end

      def rdlength
        @raw[@name_length+8,2].unpack("n")[0]
      end

      def rdata
        @raw[@name_length+10,rdlength]
      end

    end

    class Section
      include Enumerable
      def initialize(msg, section, count_method)
        @msg = msg
        @section = section
        @count_method = count_method
      end

      def [](i)
        @msg.send(:rr_at_index, @section, i)
      end

      def length
        return @msg.send(@count_method)
      end

      def each
        count = @msg.send(@count_method)
        count.times do |i|
          yield self[i]
        end
        return nil
      end

    end


    module ResourceRecordParser
      def answer
        return Section.new(self, :answer, :ancount)
      end

      def authority
        return Section.new(self, :authority, :nscount)
      end

      def additional
        return Section.new(self, :additional, :arcount)
      end

      protected
      def rr_at_index(section, i)
        rrcache = @cache[section]
        offset = rrcache[:record_offsets][i]
        length = rrcache[:record_lengths][i]
        raw_rr = @msg[offset,length]
        return RR.new(self, :section, i, offset, raw_rr)
      end

      def raw_rr_at(offset)
        length = raw_name_at(offset).length  # NAME
        length += 2   # TYPE
        length += 2   # CLASS
        length += 4   # TTL

        # Read RDLENGTH
        raise ArgumentError.new("Message corrupt (truncated)") if offset+length+2 > @msg.length
        rdlength = @msg[offset+length,2].unpack("n")[0]
        length += 2   # RDLENGTH

        # Read RDATA
        length += rdlength
        raise ArgumentError.new("Message corrupt (truncated)") if offset+length > @msg.length
        return @msg[offset,length]
      end

      def calculate_rr_section_length(offset, count)
        length = 0
        count.times do
          length += raw_rr_at(offset+length).length
        end
        raise ArgumentError.new("Message corrupt (truncated)") if offset+length > @msg.length
        return length
      end

      def rebuild_rr_cache
        offset = @cache[:question][:offset] + @cache[:question][:length]

        for section, count in {:answer => ancount, :authority => nscount, :additional => arcount}
          rr_offsets = []
          rr_lengths = []
          length = 0
          count.times do
            rr_length = raw_rr_at(offset).length
            rr_offsets << offset
            rr_lengths << rr_length
            offset += rr_length
            length += rr_length
          end
          @cache[section] = {
            :offset => offset,
            :length => length,
            :record_offsets => rr_offsets,
            :record_lengths => rr_lengths,
          }
        end
      end

    end

    class Message
      include HeaderParser
      include QuestionParser
      include ResourceRecordParser

      def initialize(raw_message)
        @msg = raw_message
        @cache = {}
        rebuild_cache
      end

      def rebuild_cache
        @cache = {}
        rebuild_question_cache
        rebuild_rr_cache
        return nil
      end

      def to_s
        return @msg
      end
    end

  end
end
