class String
  #def ^( other )
  #  b1 = self.unpack("U*")
  #  b2 = other.unpack("U*")
  #  longest = [b1.length,b2.length].max
  #  b1 = [0]*(longest-b1.length) + b1
  #  b2 = [0]*(longest-b2.length) + b2
  #  b1.zip(b2).map{ |a,b| a^b }.pack("U*")
  #end

  def ^( other )
    b1 = self.unpack("U*")
    b2 = other.unpack("U*")

    vals = [b1,b2].sort { |a,b| a.length <=> b.length }
    v1 = vals.first
    v2 = vals.last

    v1 = vals.first + v1 while (vals.first.length + v1.length <= v2.length)
    v1 = vals.first[0...(v2.length - v1.length)] + v1
    v1.zip(v2).map{ |a,b| a^b }.pack("U*")
  end
end