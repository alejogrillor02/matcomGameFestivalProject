extends Node2D

# Tile Atlas Coords
var VOID = Vector2i(3, 0)
var FLOOR = Vector2i(1, 1)
var WALL_N = Vector2i(1, 0)
var WALL_S = Vector2i(1, 2)
var WALL_E = Vector2i(2, 1)
var WALL_W = Vector2i(0, 1)
var WALL_NE = Vector2i(2, 0)
var WALL_NW = Vector2i(0, 0)
var WALL_SE = Vector2i(2, 2)
var WALL_SW = Vector2i(0, 2)


enum Direction {
	NORTH,
	SOUTH,
	EAST,
	WEST
}

@export var move_speed: float = 100.0  # pixels per second
@export var move_delay: float = 0.5  # seconds between moves

@onready var tilemap: TileMap = $TileMap
@onready var dwarf: AnimatedSprite2D = $Dwarf
@onready var move_timer: Timer = $MoveTimer

var maze_matrix: Array = [
	[0, 0, 0, 0, 0, 0, 0],
	[0, 1, 1, 1, 1, 1, 0],
	[0, 1, 0, 0, 0, 1, 0],
	[0, 1, 1, 1, 0, 1, 0],
	[0, 0, 0, 1, 1, 1, 0],
	[0, 1, 1, 1, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0]
] # Your maze matrix (0=wall, 1=path)

var position_matrix: Array = [
	[0, 0, 0, 0, 0, 0, 0],
	[0, 1, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0]
]  # Position matrix (1=dwarf start)

var dwarf_position: Vector2i = Vector2i.ZERO
var dwarf_direction: Direction = Direction.EAST # Initial direction
var is_moving: bool = false

func _ready():
	generate_maze()
	find_dwarf_start_position()
	move_timer.wait_time = move_delay
	move_timer.start()

func generate_maze():
	for y in range(maze_matrix.size()):
		for x in range(maze_matrix[y].size()):
			if maze_matrix[y][x] == 1:
				tilemap.set_cell(0, Vector2i(x, y), 0, FLOOR)
			else:
				place_wall(x, y)

func place_wall(x: int, y: int) -> void:
	var p = {
		"n": false, "ne": false, "e": false, "se": false,
		"s": false, "sw": false, "w": false, "nw": false
	}
	
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue  # Skip
			var nx = x + dx
			var ny = y + dy
			
			if ny < 0 or ny >= maze_matrix.size() or nx < 0 or nx >= maze_matrix[ny].size():
				continue
			
			if maze_matrix[ny][nx] == 1:
				if dy == -1 and dx == 0: p["n"] = true
				elif dy == -1 and dx == 1: p["ne"] = true
				elif dy == 0 and dx == 1: p["e"] = true
				elif dy == 1 and dx == 1: p["se"] = true
				elif dy == 1 and dx == 0: p["s"] = true
				elif dy == 1 and dx == -1: p["sw"] = true
				elif dy == 0 and dx == -1: p["w"] = true
				elif dy == -1 and dx == -1: p["nw"] = true
			
	if p["s"] :
		tilemap.set_cell(0, Vector2i(x, y), 0, WALL_N)
	else:
		tilemap.set_cell(0, Vector2i(x, y), 0, VOID)

func any_other_directions(neighbors: Dictionary, exclude: Array) -> bool:
	for dir in neighbors:
		if not dir in exclude and neighbors[dir]:
			return true
	return false

func find_dwarf_start_position():
	for y in range(position_matrix.size()):
		for x in range(position_matrix[y].size()):
			if position_matrix[y][x] == 1:
				if maze_matrix[y][x] != 1:
					push_error("Dwarf start position must be on a path tile (1)")
					return
				
				dwarf_position = Vector2i(x, y)
				dwarf.position = tilemap.map_to_local(dwarf_position)
				return
	
	push_error("No dwarf start position found in position matrix")

func _on_move_timer_timeout():
	if is_moving:
		return  # Skip if we're still animating
	
	# Try to move in current direction
	var next_pos = get_position_in_direction(dwarf_position, dwarf_direction)
	
	if is_valid_move(next_pos):
		move_dwarf(next_pos)
	else:
		# Try to turn left or right randomly
		var new_dir = get_random_turn()
		var attempts = 0
		var max_attempts = 4  # Try all directions before giving up
		
		while attempts < max_attempts:
			next_pos = get_position_in_direction(dwarf_position, new_dir)
			if is_valid_move(next_pos):
				dwarf_direction = new_dir
				move_dwarf(next_pos)
				return
			
			# Try another direction
			new_dir = Direction.values()[(new_dir + 1) % Direction.size()]
			attempts += 1
		
		# If all else fails, turn around
		dwarf_direction = Direction.values()[(dwarf_direction + 2) % Direction.size()]

func get_random_turn() -> Direction:
	# 50% chance to turn left or right
	if randi() % 2 == 0:
		return Direction.values()[(dwarf_direction - 1) % Direction.size()]
	else:
		return Direction.values()[(dwarf_direction + 1) % Direction.size()]

func get_position_in_direction(pos: Vector2i, dir: Direction) -> Vector2i:
	match dir:
		Direction.NORTH: return Vector2i(pos.x, pos.y - 1)
		Direction.SOUTH: return Vector2i(pos.x, pos.y + 1)
		Direction.EAST: return Vector2i(pos.x + 1, pos.y)
		Direction.WEST: return Vector2i(pos.x - 1, pos.y)
	return pos

func is_valid_move(pos: Vector2i) -> bool:
	# Check bounds
	if pos.y < 0 or pos.y >= maze_matrix.size() or pos.x < 0 or pos.x >= maze_matrix[pos.y].size():
		return false
	
	# Check if it's a path tile
	return maze_matrix[pos.y][pos.x] == 1

func move_dwarf(new_pos: Vector2i):
	is_moving = true
	dwarf.play("walk")  # Assuming you have a "walk" animation
	
	# Calculate movement vector
	var target_pos = tilemap.map_to_local(new_pos)
	var tween = create_tween()
	tween.tween_property(dwarf, "position", target_pos, 1.0/move_speed)
	tween.tween_callback(func(): 
		dwarf_position = new_pos
		is_moving = false
		dwarf.play("idle")  # Assuming you have an "idle" animation
	)
