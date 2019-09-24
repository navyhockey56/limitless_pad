class Integer 

  def to_binary_string(length=nil)
    as_string = self.to_s(2)
    return as_string unless length 

    raise 'Binary value is longer than specified length' if length < as_string.length 
    as_string = '0' + as_string while length > as_string.length 

    as_string
  end

  def to_char
    [self.%(256)].pack('C*')
  end

end