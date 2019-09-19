require_relative 'string.rb'

module LimitlessPad

  def self.create_key(activators:, nonActivators:, iterations:, file_name: nil)
    args = [activators, nonActivators, iterations]
    unless args.all? {|a| a.class == Integer && a > 0}
      raise 'All arguments must be positive integers'  
    end

    file_name ||= "keys/key_#{activators}_#{nonActivators}_#{iterations}.txt"

    asm = {
      iteration: 0,
      values: {}
    }
    asm[:values][activators + nonActivators] = 0

    while iterations > 0
      is_active = false
      asm[:values].each do |length, value|
        asm[:values][length] = (value + 1) % length
        is_active ||= asm[:values][length] <= activators - 1
      end

      asm[:iteration] += 1
      asm[:values][activators + nonActivators + asm[:iteration]] = 0 unless is_active
      
      iterations -= 1
    end

    key = {
      activators: activators,
      nonActivators: nonActivators,
      elements: asm[:values].keys.sort
    }

    File.open(file_name, 'w') { |f| f.write(JSON.pretty_generate(key)) }
    key
  end

  def self.encrpyt(key: nil, key_path: nil, iteration:, index:, message:)
    raise "You must provide a key or a filepath to one." unless key || key_path

    unless key
      raise "No key found at #{key_path}" unless File.exist?(key_path)
      key = JSON.parse File.open(key_path, 'r').read
    end

    key = JSON.parse(key.to_json, symbolize_names: true)

    raise 'Invalid Key provided: Key is not an array' unless key.is_a?(Hash)
    raise 'Invalid Key provided: missing elements' unless key[:elements]
    raise 'Invalid Key provided: missing activators' unless key[:activators]
    raise 'Invalid key provided: missing nonActivators' unless key[:nonActivators]
    raise 'All elements must be positive integers' unless key[:elements].all? {|k| k.class == Integer && k > 1}

    element = key[:elements][index]
    position = (key[:activators] + key[:nonActivators] + iteration) % element

    {
      iteration: iteration,
      index: index,
      message: position.to_s(2) ^ message
    }
  end

  def self.decrpyt(**params)
    encrpyt(params)[:message]
  end

end