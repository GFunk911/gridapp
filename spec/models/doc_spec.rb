require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'facets/file/write'
def jit(*args,&b)
  #puts "RUNNING: #{args.first}"
  it(*args,&b)
end

describe 'Doc ALL' do
  before(:all) do
    load_from_csv!

    @jerks = @app.get_table('teams').docs.find { |x| x.team == 'Panda Jerks' }
    @hoodlums = @app.get_table('teams').docs.find { |x| x.team == 'Hoodlums' }
    @picks = @app.get_table('picks').docs
    @panda_picks = @picks.select { |x| x.team == 'Panda Jerks' }
    @panda_first_pick = @panda_picks.find { |x| x.number.to_s == '1' }
    @panda_player_names = @panda_picks.map { |x| x.player }.select { |x| x }.sort
  end
  it 'smoke' do
    2.should == 2
  end
  describe 'Doc - draft template' do
    it 'possible_values' do
      col = Column.new(:table => 'picks', :column => 'player', :app => @app)
      col.possible_values.should == ['','CC Sabathia','Johan Santana','Lance Berkman','Mariano Rivera','Matt Holliday']
      col.dropdown?.should == true
    end
    it 'rows_for' do
      fk = @app.constraints(ForeignKey).find_h(:parent => 'teams:team')
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
    def get_virtual_table(t)
      res = @app.get_table(t)
      res.class.should == VirtualCouchTable
      res
    end
    jit 'virtual_table base_table' do
      get_virtual_table('unpicked_players').base_table_name.should == 'players'
    end
    jit 'virtual_table docs' do
      get_virtual_table('unpicked_players').all_docs.size.should == @app.get_table('players').docs.size
    end
    jit 'virtual_table filter' do
      get_virtual_table('unpicked_players').docs.size.should == 5
    end
    jit 'vt tables' do
      @app.tables.include?('unpicked_players').should == true
    end
    jit 'get returns virtual table' do
      @app.get_table('unpicked_players').class.should == VirtualCouchTable
      @app.get_table('unpicked_players').docs.size.should == 5
    end
    jit 'can get valid empty list in chain' do
      @hoodlums.children(:picks).parent(:players).position('OF').size.should == 0   
    end
  end
  describe 'Doc - people template' do
    before(:all) do
      @app = App.get('people')
      @people = @app.get_table('people')
      @adam = @people.docs.find { |x| x.name == 'Adam' }
    end
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
      @app.constraints(ForeignKey).size.should == 2
    end
    jit 'fk attrs' do
      fk = @app.constraints(ForeignKey).find { |x| x.child_table == 'people' }
      fk.parent_table.should == 'cities'
      fk.parent_column.should == 'city'
      fk.child_table.should == 'people'
      fk.child_column.should == 'city'
      fk.parent.should == 'cities:city'
      fk.child.should == 'people:city'
    end
    jit 'child table has virtual key' do
      @app.get_table('people').keys.include?('weather').should == true
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
      col = Column.new(:table => 'people2', :column => 'favorite_hot_city', :app => @app)
      col.possible_values.should == [''] + %w(Atlanta Dallas)
      col.dropdown?.should == true
    end
  end
end
