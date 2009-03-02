class CreateMoves < ActiveRecord::Migration
  def self.up
    create_table :moves do |t|
      t.string :orig
      t.string :dest
      t.string :status
      t.string :customer

      t.timestamps
    end
  end

  def self.down
    drop_table :moves
  end
end
