#this is a game with simple rule
#1. x can walk x step without walking backward
#2. "1" die, u will lose the game

START = 30
WHITE_COLOR = "#FFFFFF"
BLACK_COLOR = "#000000"
RED_COLOR = "#FF0000"
GREEN_COLOR = "#00FF00"
PINK_COLOR = "#FF00FF"

class GameUnit
  attr_reader :selected, :pos, :id

  def initialize(flag, id, x, y, app, size, game)
	@flag = flag
	@id = id 
	@pos = [x,y]
	@app = app
	@size = size
	@game = game
	@selected = false
  end
		
  def show_attack_range (pos)
	return if @game.same_pos?(pos, @game.current_player)

	x, y= pos[0], pos[1]
    @app.stack(:left => START+x*@size, :top => START+y*@size, :width => @size, :height => @size) do
	  size = @size
	  shape_clr = @flag == "white" ? rgb(144,255,144,0.5):rgb(47,79,79,0.5)

	  @app.fill(shape_clr)
	  shape = @app.rect(2, 2, size-2)
	  shape.style(:stroke => shape_clr)
	  @app.fill(shape_clr)

	  @app.click do |button, x, y|
		if button == 1
		  @pos = pos
		  @game.delete_unit(pos)  if @game.same_pos?(pos, @game.get_next_player)
		  @app.render_field
		  @game.next_player
		  @selected = false
		end
	  end

	end
  end

  def display
    @app.stack(:left => START+@pos[0]*@size, :top => START+@pos[1]*@size, :width => @size, :height => @size) do
	  size = @size

	  @shape_clr = @flag == "white" ? WHITE_COLOR : BLACK_COLOR
	  @text_clr = @flag == "white" ?  BLACK_COLOR : WHITE_COLOR

	  @app.fill(@shape_clr)
	  @shape = @app.oval(1, 1, size-2)
	  @shape.style(:stroke => @shape_clr)
	  @text = @app.para(@id.to_s, :top => size/4, :left => size/3, :size => 30, :stroke => @text_clr)

	  @app.hover do
		if !@selected and @flag == @game.current_player
		  @text.style(:stroke => GREEN_COLOR)
		  @shape.style(:stroke => PINK_COLOR)
		end
	  end

	  @app.leave do
		if !@selected and @flag == @game.current_player
		  @text.style(:stroke => @text_clr)
		  @shape.style(:stroke => @shape_clr) 
		end
	  end

	  @app.click do |button, x, y|
		if @game.get_reset_flag
		  @game.set_reset_flag false
		  return
		end

		if button == 1 and @flag == @game.current_player
		  @app.render_field
		  @text.style(:stroke => RED_COLOR)
		  @shape.style(:stroke => RED_COLOR)

		  poses = get_possible_poses(@id)
		  for pos in poses
			if can_reach?(pos)
			  show_attack_range pos
			end
		  end
		  @selected = true
		end
		if button == 3 and @flag == @game.current_player
		  @selected = false
		  @app.render_field
		end
	  end

	end
  end

  def get_others
	return @game.get_others(self)
  end

  def out_side?(path, max_size)
	for s in path
	  return true if s[0] < 0 or s[1] < 0 or s[0] >= max_size or s[1] >= max_size
	end
	return false
  end

  def can_reach?(pos)
	paths =  get_paths_no_back(@id, @pos, pos)
	others = get_others
	bad_paths = 0

	for p in paths
	  if out_side?(p,@app.get_game_size - 1)
		bad_paths += 1
		next
	  end
	  outing = false

	  for o in others
		if p.include?(o.pos) 
		  bad_paths += 1
		  outing = true
		  break
		end
	  end
	  if outing 
		next
	  end
	end
	return bad_paths != paths.count
  end


  def get_paths_no_back(n,start_pos,end_pos)
	return nil if n < (end_pos[0] - start_pos[0]).abs + (end_pos[1] - start_pos[1]).abs
	if n == (end_pos[0] - start_pos[0]).abs + (end_pos[1] - start_pos[1]).abs
	  return  get_shortest_paths(start_pos, end_pos)
	end

	paths = []
	next_pos = [start_pos[0]-1, start_pos[1]]
	if next_pos != end_pos
	  paths_left = get_paths_no_back(n-1, next_pos, end_pos)
	  if paths_left
		for p in paths_left 
		  if !p.include?(start_pos)
			p.unshift(next_pos)
			paths << p
		  end
		end
	  end
	end

	next_pos = [start_pos[0]+1, start_pos[1]]
	if next_pos != end_pos
	  paths_right = get_paths_no_back(n-1, next_pos, end_pos)
	  if paths_right
		for p in paths_right
		  if !p.include?(start_pos)
			p.unshift(next_pos)
			paths << p
		  end
		end
	  end
	end

	next_pos = [start_pos[0], start_pos[1]+1]
	if next_pos != end_pos
	  paths_up = get_paths_no_back(n-1, next_pos, end_pos)
	  if paths_up
		for p in paths_up 
		  if !p.include?(start_pos)
			p.unshift(next_pos)
			paths << p
		  end
		end
	  end
	end

	next_pos = [start_pos[0], start_pos[1]-1]
	if next_pos != end_pos
	  paths_down = get_paths_no_back(n-1, next_pos, end_pos)
	  if paths_down
		for p in paths_down 
		  if !p.include?(start_pos)
			p.unshift(next_pos)
			paths << p
		  end
		end
	  end
	end

	return paths

  end

  def get_shortest_paths(s, pos)
	path = []
	paths = []
	x=s[0]
	y=s[1]

	return nil if pos == s

	if pos[0] == s[0]
	  while y != pos[1] 
		path << [x,y] if y != s[1]
		y += (pos[1] - s[1])/(pos[1] - s[1]).abs
	  end
	  paths << path
	  return paths
	end

	if pos[1] == s[1]
	  while x != pos[0] 
		path << [x,y] if x != s[0]
		x += (pos[0] - s[0])/(pos[0] - s[0]).abs
	  end
	  paths << path
	  return paths
	end

	xx = pos[0]
	yy = pos[1]
	xx = pos[0] - (pos[0] - s[0])/(pos[0] - s[0]).abs 
	path_x = get_shortest_paths(s,[xx,pos[1]]) 
	if path_x
	  for p in path_x
		p << [xx, pos[1]]
		paths << p
	  end
	end

	yy = pos[1] - (pos[1] - s[1])/(pos[1] - s[1]).abs 
	path_y = get_shortest_paths(s,[pos[0], yy]) 
	if path_y 
	  for p in path_y
		p << [pos[0], yy]
		paths << p
	  end
	end

	return paths
  end

  def get_possible_poses(id)
	pos_array = []
	i = 0
	while id >= i
	  pos_array << [@pos[0]+i,@pos[1]+(id-i)] if @pos[0]+i<6 and @pos[0]+i>=0 and @pos[1]+(id-i)>=0 and @pos[1]+(id-i)<6
	  pos_array << [@pos[0]+i,@pos[1]-(id-i)] if @pos[0]+i<6 and @pos[0]+i>=0 and @pos[1]-(id-i)>=0 and @pos[1]-(id-i)<6
	  pos_array << [@pos[0]-i,@pos[1]+(id-i)] if @pos[0]-i<6 and @pos[0]-i>=0 and @pos[1]+(id-i)>=0 and @pos[1]+(id-i)<6
	  pos_array << [@pos[0]-i,@pos[1]-(id-i)] if @pos[0]-i<6 and @pos[0]-i>=0 and @pos[1]-(id-i)>=0 and @pos[1]-(id-i)<6
	  i += 1
	end
	pos_array += get_possible_poses(id-2) if id > 2
	return pos_array.uniq
  end

end

class Game
  attr_reader :current_player

  def set_reset_flag(set)
	@reset_flag = set
  end
	
  def get_reset_flag
	return @reset_flag
  end
  
  def initialize(size, square_size, app)
	@reset_flag = false
    @app = app
    @size = size
    @square_size = square_size
	@white_units = []
	@black_units = []
	for i in 0..@size - 2
	  @white_units << GameUnit.new("white",@size-1-i,i,0,@app,@square_size, self)
	  @black_units << GameUnit.new("black",i+1,i,@size - 2,@app,@square_size, self)
	end

    @current_player = "black"
  end

  def reset
	(@white_units + @black_units).clear
	for i in 0..@size - 2
	  @white_units << GameUnit.new("white",@size-1-i,i,0,@app,@square_size, self)
	  @black_units << GameUnit.new("black",i+1,i,@size - 2,@app,@square_size, self)
	end
	@reset_flag = true
  end

  def get_others(u)
	us = []
	(@white_units + @black_units).each do |w|
	  us << w if w != u
	end
	return us
  end

  def delete_unit(pos)
	@units = get_next_player == "white" ? @white_units : @black_units
	@units.each do |u|
	  if u.pos == pos
		@units.delete(u)
		if u.id == 1
		  if confirm 'game over, ' + @current_player + ' wins the game!! ' + 'play again?' 
			reset
		  else
			exit
		  end
		end
	  end
	end
  end

  def same_pos?(pos, flag)
	us = flag == "white" ? @white_units : @black_units
	us.each do |u|
	  return true if u.pos == pos
	end
	return false
  end
  
  def get_next_player() #I kind of hate myself now
    return @current_player == "black" ? "white" : "black"
  end
  
  def next_player()
	@current_player = @current_player == "black" ? "white" : "black"
  end
  
  def draw()
	(@white_units + @black_units).each do |u|
	  u.display
	end
  end

end


Shoes.app :width => 600 , :height => 600 do
  @game_size = 7 #default
  @square_size = self.height/@game_size
	
  def get_game_size
	return @game_size
  end

  def render_field()
    clear do
      background rgb(119, 169, 108, 0.8)
      
      x = START
      y = START
      self.strokewidth(1)
      @game_size.times do 
        line(x, y, x, (@game_size-1)*@square_size+START)
        x += @square_size
      end
      x = START
      @game_size.times do
        line(x, y, @square_size*(@game_size-1)+START, y)
        y += @square_size
      end

      @game.draw()
    end
  end
  
  $app = self
  @game = Game.new(@game_size, @square_size, self)
  render_field
end
