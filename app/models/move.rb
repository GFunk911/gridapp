module FromHash
  def from_hash(ops)
    ops.each do |k,v|
      send("#{k}=",v)
    end
  end
  def initialize(ops={})
    from_hash(ops)
  end
end

class Move
  include FromHash
  attr_accessor :move_id, :orig_address, :dest_address
end