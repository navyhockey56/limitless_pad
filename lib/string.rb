class String

  # def ^( other )
  #   b1 = self.unpack("C*")
  #   b2 = other.unpack("C*")

  #   vals = [b1,b2].sort { |a,b| a.length <=> b.length }
  #   v1 = vals.first
  #   v2 = vals.last

  #   v1 = vals.first + v1 while (vals.first.length + v1.length <= v2.length)
  #   v1 = vals.first[0...(v2.length - v1.length)] + v1
  #   v1.zip(v2).map{ |a,b| a^b }.pack("C*")
  # end

  def ^( other )
    self.check_binary_number
    other.check_binary_number
    raise 'Lengths must be equal' unless self.length == other.length

    new_string = ''
    (0...(self.length)).each do |i|
      new_string += (self[i].to_i ^ other[i].to_i).to_s
    end

    new_string
  end

  def as_binary_number
    values = self.unpack("C*")
    values.map do |v| 
      v.to_binary_string 8
    end.join ''
  end

  def check_binary_number
    all_chars = self.chars.uniq.sort
    raise 'Invalid value - String must be all 0s and 1s' unless [%w[0 1], %w[0], %w[1]].include?(all_chars)
  end

  def from_binary_number
    check_binary_number
    raise 'Invalid value - length is not a multiple of 8' unless self.length % 8 == 0

    values = []
    self.chars.each_slice(8) do |s| 
      values <<  s.join('').to_i(2)
    end
    values.pack('C*')
  end

  def pad_end(length, padding=nil)
    def get_padding(padding)
      padding ? padding : rand(2).to_s
    end
    raise "Padding must be a single character" unless padding.nil? || padding.length == 1

    new_str = self.dup
    new_str += get_padding(padding) while new_str.length < length
    new_str
  end

  def pad_front(length, padding=nil)
    def get_padding(padding)
      padding ? padding : rand(256).to_char
    end
    raise "Padding must be a single character" unless padding.nil? || padding.length == 1

    new_str = self.dup
    new_str = get_padding(padding) + new_str while new_str.length < length
    new_str
  end

end