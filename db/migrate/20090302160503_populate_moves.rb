module Enumerable
  def two_rand
    el = rand()
    20.times do
      other = rand()
      return [el,other] unless el == other
    end
    raise 'foo'
  end
end

class PopulateMoves < ActiveRecord::Migration
  def self.addresses
    res = []
    res << "254 Woodland Road, 07940"
    res << "2 Research Way, 08540"
    res << "1827 Stuart Rd W, 08540"
    res << "20 Nassau St, 08540"
    res << "61 Church St, New Brunswick, NJ 08901"
    res << "426 Main St, Metuchen, NJ 08840"
    res << "99 Susan Dr, Chatham, NJ 07928"
  end
  def self.customers
    ["Walmart",'Target','Dow Chemical','KMart']
  end
  def self.statuses
    ['Open','In Progress','Closed']
  end
  def self.up
    15.times do
      addrs = addresses.two_rand
      cust = customers.rand
      status = statuses.rand
      Move.new(:orig => addrs[0], :dest => addrs[1], :status => status, :customer => cust).save!
    end
  end

  def self.down
  end
end
