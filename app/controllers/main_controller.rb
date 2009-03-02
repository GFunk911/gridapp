class MainController < ApplicationController
  def index
    @moves = []
    @moves << Move.new(:move_id => 1, :orig_address => '254 Woodland Road, 07940')
    @moves << Move.new(:move_id => 2, :orig_address => '2 Research Way, 08540')
    @moves << Move.new(:move_id => 3, :orig_address => '1827 Stuart Rd W, 08540')
    @moves << Move.new(:move_id => 4, :orig_address => '21 Constitution Way, Somerset, NJ')
    @moves << Move.new(:move_id => 3, :orig_address => '115 Reinman, Warren, NJ')
  end
end
