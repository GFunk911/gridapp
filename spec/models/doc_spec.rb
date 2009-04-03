require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'facets/file/write'
def jit(*args,&b)
  #puts "RUNNING: #{args.first}"
  it(*args,&b)
end

describe 'Doc ALL' do
  before(:all) do
    load_from_csv!
    
    @jerks = CouchTable.get('teams').docs.find { |x| x.team == 'Panda Jerks' }
    @picks = CouchTable.get('picks').docs
    @panda_picks = @picks.select { |x| x.team == 'Panda Jerks' }
    @panda_first_pick = @panda_picks.find { |x| x.number.to_s == '1' }
    @panda_player_names = @panda_picks.map { |x| x.player }.select { |x| x }.sort
    
    @adam = @people.docs.find { |x| x.name == 'Adam' }
  end
  describe 'Doc2' do
    jit 'possible_values' do
      col = Column.new(:table => 'picks', :column => 'player')
      col.possible_values.should == ['','CC Sabathia','Johan Santana','Lance Berkman','Mariano Rivera','Matt Holliday']
      col.dropdown?.should == true
    end
    jit 'rows_for' do
      fk = ForeignKey.find_h(:parent => 'teams:team')
      picks = fk.rows_for(@jerks).map { |x| x.player }.select { |x| x }.sort
      picks.size.should == 2
      picks.should == @panda_player_names
    end
    jit 'parent_rows_in_table' do
      @jerks.parent_rows_in_table('picks').size.should == 10
    end
    jit 'link from parent' do
      @jerks.children(:picks).size.should == 10
    end
    jit 'link from child' do
      @panda_first_pick.parent(:players).name.should == 'Albert Pujols'
    end
    jit 'chained links' do
      @jerks.children(:picks).parent(:players).map { |x| x.name }.should == @panda_player_names
    end
    jit 'c calc_column' do
      @jerks.players.to_s.should == '2'
    end
    jit 'value_picked' do
      @jerks.value_picked.to_s.should == '40'
    end
    jit '1B Count' do
      @jerks.send('1B').to_s.should == '1'
    end
    jit 'virtual_table base_table' do
      VirtualCouchTable.new('unpicked_players').base_table_name.should == 'players'
    end
    jit 'virtual_table docs' do
      VirtualCouchTable.new('unpicked_players').all_docs.size.should == CouchTable.get('players').docs.size
    end
    jit 'virtual_table filter' do
      VirtualCouchTable.new('unpicked_players').docs.size.should == 5
    end
    jit 'vt tables' do
      CouchTable.tables.include?('unpicked_players').should == true
    end
    jit 'get returns virtual table' do
      CouchTable.get('unpicked_players').class.should == VirtualCouchTable
      CouchTable.get('unpicked_players').docs.size.should == 5
    end
  end

  describe 'Doc' do
    jit 'table' do
      @people.docs.size.should == 4
    end
    jit 'fk' do
      @adam.fk_row('cities').class.should == ForeignKey
    end
    jit 'row' do
      @adam.row_in_table('cities').city.should == 'Atlanta'
    end
    jit 'fk all' do
      ForeignKey.all.size.should == 5
    end
    jit 'fk attrs' do
      fk = ForeignKey.all.find { |x| x.child_table == 'people' }
      fk.parent_table.should == 'cities'
      fk.parent_column.should == 'city'
      fk.child_table.should == 'people'
      fk.child_column.should == 'city'
      fk.parent.should == 'cities:city'
      fk.child.should == 'people:city'
    end
    jit 'child table has virtual key' do
      CouchTable.get('people').keys.include?('weather').should == true
    end
    jit 'child table has virtual value' do
      @adam.weather.should == 'Hot'
    end
    jit 'double name' do
      @adam.double_name.should == 'Adam Adam'
    end
    jit 'calc_column' do
      @adam.calc_column('double_name').class.should == CalcColumn
      @adam.calc_column('double_name').value_for(@adam).should == 'Adam Adam'
    end
    jit 'possible_values' do
      col = Column.new(:table => 'people2', :column => 'favorite_hot_city')
      col.possible_values.should == [''] + %w(Atlanta Dallas)
      col.dropdown?.should == true
    end
  end
end
