require 'tempfile'
require 'strscan'

class MmapScanner
  attr_reader :size

  def initialize(src, offset=0, size=nil)
    offset ||= 0
    raise RangeError, "length out of range: #{size}" if size && size < 0
    case src
    when Tempfile, File
      pos_saved = src.pos
      begin
        src.pos = offset
        @size = size || src.size - offset
        @ss = StringScanner.new(src.read(@size))
      ensure
        src.pos = pos_saved
      end
    when String
      @size = size || src.bytesize - offset
      src = src.encode('ASCII-8BIT', 'ASCII-8BIT')
      @ss = StringScanner.new(src[offset, @size])
    when MmapScanner
      @size = size || src.size - offset
      @ss = StringScanner.new(src.to_s[offset, @size])
    else
      raise TypeError
    end
  end

  def pos=(n)
    raise RangeError, "out of range: #{n}" if n < 0
    raise RangeError, "out of range: #{n} > #{size}" if n > size
    @ss.pos = n
  end

  def pos
    @ss.pos
  end

  def to_s
    @ss.string
  end

  def terminate
    @ss.terminate
    self
  end

  def inspect
    "#<#{self.class.name}>"
  end

  def slice(pos, len)
    MmapScanner.new(@ss.string.slice(pos, len))
  end

  [:scan, :scan_until, :scan_full, :check, :check_until, :skip, :skip_until, :match?, :exist?, :peek, :eos?, :search_full, :rest].each do |m|
    define_method(m) do |*args|
      s = @ss.__send__(m, *args)
      s.is_a?(String) ? MmapScanner.new(s) : s
    end
  end

  def matched(n=nil)
    if n.nil?
      @ss.matched
    elsif n < 0
      nil
    else
      @ss[n]
    end
  end
end
