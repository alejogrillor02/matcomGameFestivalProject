extends Node2D

@onready var tile_map: TileMap = $TileMap
@onready var move_timer: Timer = $MoveTimer

@export var grid: Array = []


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
	pass
