require 'prime'

require_relative 'string.rb'
require_relative 'integer.rb'

module LimitlessPad

  def self.create_key(activators:, non_activators:, element_count:, element_length:, file_name: nil)
    args = [activators, non_activators, element_count]
    unless args.all? {|a| a.class == Integer && a > 0}
      raise 'All arguments must be positive integers'  
    end

    raise 'element_count must be a prime number' unless Prime.prime?(element_count)

    file_name ||= "keys/key_#{activators}_#{non_activators}_#{element_count}_#{element_length}.asm"
    
    asm = {
      iteration: 0,
      values: {}
    }
    asm[:values][activators + non_activators] = 0

    while asm[:values].count < element_count
      is_active = false
      asm[:values].each do |length, value|
        value = (value + 1) % length
        begin 
          value.to_binary_string element_length
        rescue StandardError
          raise 'ASM violates element_length constraint. You must increase the element_length paramter'
        end

        asm[:values][length] = value 
        is_active ||= value <= activators - 1
      end

      asm[:iteration] += 1
      asm[:values][activators + non_activators + asm[:iteration]] = 0 unless is_active
    end

    key = {
      element_length: element_length,
      activators: activators,
      non_activators: non_activators,
      elements: asm[:values].keys.sort
    }
    puts "Writing key to #{file_name}"
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
    raise 'Invalid key provided: missing non_activators' unless key[:non_activators]
    raise 'All elements must be positive integers' unless key[:elements].all? {|k| k.class == Integer && k > 1}

    first_element = key[:elements][index]
    first_position = (key[:activators] + key[:non_activators] + iteration) % first_element
    
    element_count = key[:elements].count
    adjusted_position = first_element % (element_count)

    raise 'Invalid (iteration, element) pair - element is 0.' if adjusted_position == 0

    permuted_indices = modulate(element_count, adjusted_position)
    permuted_indices.delete_at(permuted_indices.length - 1)
   
    positions = permuted_indices.map do |index|
      element = key[:elements][index]
      position = (key[:activators] + key[:non_activators] + iteration) % element
      position.to_binary_string
    end

    xor_key = positions.join ''
    message = message.as_binary_number.pad_end(xor_key.length)
    raise "Supplied message is too long to encrypt. Maximum message length is #{xor_key.length}" if xor_key.length < message.length
    
    message =  xor_key ^ message

    {
      iteration: iteration,
      index: index,
      message: message
    }
  end

  def self.decrpyt(key: nil, key_path: nil, iteration:, index:, message:) #(**params)
    #encrpyt(params)[:message]

    raise "You must provide a key or a filepath to one." unless key || key_path

    unless key
      raise "No key found at #{key_path}" unless File.exist?(key_path)
      key = JSON.parse File.open(key_path, 'r').read
    end

    key = JSON.parse(key.to_json, symbolize_names: true)

    raise 'Invalid Key provided: Key is not an array' unless key.is_a?(Hash)
    raise 'Invalid Key provided: missing elements' unless key[:elements]
    raise 'Invalid Key provided: missing activators' unless key[:activators]
    raise 'Invalid key provided: missing non_activators' unless key[:non_activators]
    raise 'All elements must be positive integers' unless key[:elements].all? {|k| k.class == Integer && k > 1}

    first_element = key[:elements][index]
    first_position = (key[:activators] + key[:non_activators] + iteration) % first_element
    
    element_count = key[:elements].count
    adjusted_position = first_element % (element_count)

    raise 'Invalid (iteration, element) pair - element is 0.' if adjusted_position == 0

    permuted_indices = modulate(element_count, adjusted_position)
    permuted_indices.delete_at(permuted_indices.length - 1)

    positions = permuted_indices.map do |index|
      element = key[:elements][index]
      position = (key[:activators] + key[:non_activators] + iteration) % element
      position.to_binary_string
    end

    xor_key = positions.join ''
    message =  xor_key ^ message

    message[0...(message.length / 8)*8].from_binary_number
  end

  def self.modulate(group, generator)
    elements = [generator]
    next_ele = 2*generator % group
    while !elements.include? next_ele
      elements << next_ele 
      next_ele += generator
      next_ele %= group
    end

    elements
  end

  def self.test_it

    # message = "Hello, I am a test message. The purpose of me is to prove that whatever I encrypt can be correctly " \
    #           "decrpyted. To test this, we are going to create several different keys and then encrypt this message " \
    #           "with a bunch of different iterations and indices. Then we will decrypt the message and conform that " \
    #           "it starts with this text here."
    message = "Small test message"

    enc_and_decs = []
    (200...205).each do |activators|
      (100...105).each do |non_activators|
        
        puts "Testing key #{activators}, #{non_activators}"
        key = self.create_key(
          activators: activators, 
          non_activators: non_activators, 
          element_length: 20,
          element_count: 97
        )

        #(500...510).each do |iteration|
        #  (50...55).each do |index| 
            begin 
              enc = self.encrpyt(
                key: key,
                message: message,
                iteration: 513434,#iteration,
                index: 34#index
              )

              dec = self.decrpyt(enc.merge(key: key))
              raise "Failed #{iteration}, #{index}" unless dec.start_with? message

              enc_and_decs << [enc[:message], dec]
            rescue StandardError => ex 
              raise "Failed #{iteration}, #{index}" unless ex.message == 'Invalid (iteration, element) pair - element is 0.'
              puts "Invalid (#{iteration}, #{index})"
            end
          #end
        #end
      end
    end
    enc_and_decs
  end

end