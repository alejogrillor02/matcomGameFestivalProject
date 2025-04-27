extends Node2D

@onready var tile_map: TileMap = $TileMap
@onready var move_timer: Timer = $MoveTimer

var dirs = {
	"N": Vector2i(0, 1),
	"S": Vector2i(0, -1),
	"E": Vector2i(1, 0),
	"W": Vector2i(-1, 0)
}

var dwarf_pos = Vector2i(5, 5)
var dwarf_dir = dirs["N"]

var grid: Array = []


func _ready() -> void:
	# Preparar el Grid
	for y in tile_map.get_used_rect().size.y:
		grid.append([])
		for x in tile_map.get_used_rect().size.x:
			
			var tile_position = Vector2i(
				x + tile_map.get_used_rect().position.x,
				y + tile_map.get_used_rect().position.y
			)
			var tile_data = tile_map.get_cell_tile_data(0, tile_position)
			
			if tile_data == null or not tile_data.get_custom_data("path"):
				grid[y].append(0)
			else:
				grid[y].append(1)
	
	#print(grid)


func _on_move_timer_timeout() -> void:
	# Logica del movimiento
	var path_count = 0
	
	var valid_dirs: Array = []
	
	for dir in dirs:
		var nx = dwarf_pos.x + dirs[dir].x
		var ny = dwarf_pos.y + dirs[dir].y
		
		if grid[ny][nx] == 1:
			valid_dirs.append(dir)
	if valid_dirs.size() != 1:		
		if dwarf_dir == "N":
			valid_dirs = valid_dirs.filter(func(item): return item != "S")
		elif dwarf_dir == "S":
			valid_dirs = valid_dirs.filter(func(item): return item != "N")
		elif dwarf_dir == "E":
			valid_dirs = valid_dirs.filter(func(item): return item != "W")
		else:
			valid_dirs = valid_dirs.filter(func(item): return item != "E")
		
		dwarf_dir = valid_dirs.pick_random()
	else:
		dwarf_dir = valid_dirs[0]
		
	# TODO: Moverse hacia atras
	
