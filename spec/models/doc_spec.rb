require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'facets/file/write'
def jit(*args,&b)
  #puts "RUNNING: #{args.first}"
  it(*args,&b)
end

def load_db_draft!
  @people.db.save_doc(:table => 'players', :name => 'Albert Pujols', :position => '1B', :bp_value => 20)
  @people.db.save_doc(:table => 'players', :name => 'Jose Reyes', :position => 'SS', :bp_value => 20)
  @people.db.save_doc(:table => 'players', :name => 'David Wright', :position => '3B', :bp_value => 20)
  @people.db.save_doc(:table => 'players', :name => 'Hanley Ramirez', :position => 'SS', :bp_value => 20)
  @people.db.save_doc(:table => 'players', :name => 'Johan Santana', :position => 'SP', :bp_value => 20)
  @people.db.save_doc(:table => 'players', :name => 'CC Sabathia', :position => 'SP', :bp_value => 20)
  @people.db.save_doc(:table => 'players', :name => 'Lance Berkman', :position => '1B', :bp_value => 20)
  @people.db.save_doc(:table => 'players', :name => 'Matt Holliday', :position => 'OF', :bp_value => 20)
  @people.db.save_doc(:table => 'players', :name => 'Mariano Rivera', :position => 'RP', :bp_value => 20)
  
  teams = ['Panda Jerks','Shealys','Unger Wu']
  (1..10).each do |round|
    (1..3).each do |pick|
      overall = (round-1)*teams.size + pick
      @people.db.save_doc(:table => 'picks', :number => overall.to_s, :team => teams[pick-1]) unless overall <= 4
    end
  end
  @people.db.save_doc(:table => 'picks', :number => '1', :team => 'Panda Jerks', :player => 'Albert Pujols')
  @people.db.save_doc(:table => 'picks', :number => '2', :team => 'Shealys', :player => 'Jose Reyes')
  @people.db.save_doc(:table => 'picks', :number => '3', :team => 'Unger Wu', :player => 'David Wright')
  @people.db.save_doc(:table => 'picks', :number => '4', :team => 'Panda Jerks', :player => 'Hanley Ramirez')
  
  @people.db.save_doc(:table => 'teams', :team => 'Panda Jerks')
  @people.db.save_doc(:table => 'teams', :team => 'Shealys')
  @people.db.save_doc(:table => 'teams', :team => 'Unger Wu')
  
  @people.db.save_doc(:table => 'columns', :constraint_type => 'foreign_key', :parent_column => 'players:name', :child_column => 'picks:player', :value => "!team")
  @people.db.save_doc(:table => 'columns', :constraint_type => 'foreign_key', :parent_column => 'picks:player', :child_column => 'players:name')
  @people.db.save_doc(:table => 'columns', :constraint_type => 'virtual_column', :parent_column => 'picks:team', :child_column => 'players:team')
  @people.db.save_doc(:table => 'columns', :constraint_type => 'foreign_key', :parent_column => 'teams:team', :child_column => 'picks:team')
  @people.db.save_doc(:table => 'columns', :constraint_type => 'calc_column', :child_column => 'teams:players', :value => "parent_rows_in_table('picks').select { |x| x.player }.size")
  %w(1B 3B OF SP).each do |pos|
    @people.db.save_doc(:table => 'columns', :constraint_type => 'calc_column', :child_column => "teams:#{pos}", :value => "parent_rows_in_table('picks').select { |x| x.position == '#{pos}' }.size")
  end
  @people.db.save_doc(:table => 'columns', :constraint_type => 'sort_column', :child_column => 'picks:foo', :parent_column => 'foo:foo', :value => "number.to_i")
  @people.db.save_doc(:table => 'columns', :constraint_type => 'calc_column', :child_column => 'teams:value_picked', :value => "parent_rows_in_table('picks').select { |x| x.player }.map { |x| x.row_in_table('players').bp_value.to_i }.sum")
end

def load_db_people!
  @people.db.save_doc(:table => 'people', :name => 'Adam', :city => 'Atlanta', :favorite_hot_city => 'Dallas')
  @people.db.save_doc(:table => 'people', :name => 'Bill', :city => 'Boston')
  @people.db.save_doc(:table => 'people', :name => 'Chad', :city => 'Chicago')
  @people.db.save_doc(:table => 'people', :name => 'Dave', :city => 'Dallas')
  
  @people.db.save_doc(:table => 'people2', :name => 'Adam', :city => 'Atlanta', :favorite_hot_city => 'Dallas')
  @people.db.save_doc(:table => 'people2', :name => 'Bill', :city => 'Boston')
  @people.db.save_doc(:table => 'people2', :name => 'Chad', :city => 'Chicago')
  @people.db.save_doc(:table => 'people2', :name => 'Dave', :city => 'Dallas')
  
  @people.db.save_doc(:table => 'cities', :weather => 'Hot', :city => 'Atlanta')
  @people.db.save_doc(:table => 'cities', :weather => 'Cold', :city => 'Boston')
  @people.db.save_doc(:table => 'cities', :weather => 'Cold', :city => 'Chicago')
  @people.db.save_doc(:table => 'cities', :weather => 'Hot', :city => 'Dallas')
  
  @people.db.save_doc(:table => 'columns', :constraint_type => 'foreign_key', :parent_column => 'cities:city', :child_column => 'people:city')
  @people.db.save_doc(:table => 'columns', :constraint_type => 'virtual_column', 
                      :parent_column => 'cities:weather', :child_column => 'people:weather')
  @people.db.save_doc(:table => 'columns', :constraint_type => 'calc_column', :child_column => 'people:double_name', :value => "name + ' ' + name")
  @people.db.save_doc(:table => 'columns', :constraint_type => 'foreign_key', :child_column => 'people2:favorite_hot_city', 
                      :parent_column => 'cities:city', :value => "weather == 'Hot'")
  
  @people.db.save_doc(:table => 'junk', :weather => 'Hot', :city => 'Atlanta')
  @people.db.save_doc(:table => 'junk', :weather => 'Cold', :city => 'Boston')
  
end

FIXTURES_DIR = File.expand_path(File.dirname(__FILE__) + "/../fixtures")

def load_db!
  @people = CouchTable.new('people')
  @people.db.recreate!
  load_db_draft!
  load_db_people!
  
  @jerks = CouchTable.new('teams').docs.find { |x| x.team == 'Panda Jerks' }
  @adam = @people.docs.find { |x| x.name == 'Adam' }
end

def load_from_csv!
  require 'fastercsv'
  @people = CouchTable.new('people')
  @people.db.recreate!
  
  files = Dir["#{FIXTURES_DIR}/*.csv"]
  files.each do |file|
    load_csv_file!(file)
  end
  
  @jerks = CouchTable.new('teams').docs.find { |x| x.team == 'Panda Jerks' }
  @adam = @people.docs.find { |x| x.name == 'Adam' }
end

def load_csv_file!(file)
  table = File.basename(file).split(".")[0]
  FasterCSV.foreach(file,:headers => true) do |row| 
    @people.db.save_doc(row.to_hash.merge(:table => table))
  end
end

describe 'Doc ALL' do
  before(:all) do
    load_from_csv!
  end
  if false
    it 'make_csv' do
      CouchTable.couch_tables.each do |table|
        File.create("#{FIXTURES_DIR}/#{table.table}.csv",table.to_csv)
      end
    end
  end
  describe 'Doc2' do
    jit 'possible_values' do
      col = Column.new(:table => 'picks', :column => 'player')
      col.possible_values.should == ['','CC Sabathia','Johan Santana','Lance Berkman','Mariano Rivera','Matt Holliday']
      col.dropdown?.should == true
    end
    jit 'rows_for' do
      fk = ForeignKey.all.find { |x| x.parent_table == 'teams' and x.parent_column == 'team' }
      picks = fk.rows_for(@jerks).map { |x| x.player }.select { |x| x }.sort
      expected = CouchTable.new('picks').docs.select { |x| x.team == 'Panda Jerks' }.map { |x| x.player }.select { |x| x }.sort
      picks.size.should == 2
      picks.should == expected
    end
    jit 'c calc_column' do
      @jerks.players.to_s.should == '2'
    end
    jit 'value_picked' do
      @jerks.value_picked.to_s.should == '40'
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
    end
    jit 'child table has virtual key' do
      CouchTable.new('people').keys.include?('weather').should == true
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
