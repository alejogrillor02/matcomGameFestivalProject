extends Node2D

@onready var tile_map: TileMap = $TileMap
@onready var move_timer: Timer = $MoveTimer
@onready var dwarf_instance: Node2D = null  # Guardaremos la instancia del enano aquí

var dirs = {
	"N": Vector2i(0, 1),
	"S": Vector2i(0, -1),
	"E": Vector2i(1, 0),
	"W": Vector2i(-1, 0)
}

var dwarf_pos = Vector2i(5, 5)
var dwarf_dir = "E"

var grid: Array = []


func _ready() -> void:
	# Crear instancia del enano en la posición inicial
	spawn_dwarf_at_start()
	
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
				
	$MoveTimer.start()


func spawn_dwarf_at_start():
	# Cargar la escena del enano
	var dwarf_scene = preload("res://scenes/dwarf.tscn")
	dwarf_instance = dwarf_scene.instantiate()
	add_child(dwarf_instance)
	
	# Posicionar el enano en su posición inicial
	var tile_center = used_rect_to_local(dwarf_pos) - Vector2(13, 13)
	dwarf_instance.position = tile_center
	
	# Configurar la animación inicial
	var animated_sprite = dwarf_instance.get_node("AnimatedSprite2D")
	animated_sprite.play("walk")
	
	# Configurar flip horizontal según dirección inicial
	if dwarf_dir == "E":
		animated_sprite.flip_h = false
	else:
		animated_sprite.flip_h = true

func used_rect_to_local(pos: Vector2i):
	var used_rect = tile_map.get_used_rect()

	# Convertir a coordenadas absolutas del TileMap
	var absolute_tile_pos = Vector2i(
		used_rect.position.x + pos.x,
		used_rect.position.y + pos.y
	)
	
	var absolute_position = tile_map.map_to_local(absolute_tile_pos)
	
	return absolute_position


func _on_move_timer_timeout() -> void:
	# Lógica del movimiento
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
		
	move_dwarf(dwarf_dir)
	$MoveTimer.start()


func move_dwarf(direction: String):
	dwarf_pos += dirs[direction]
	
	var target_position = used_rect_to_local(dwarf_pos) - Vector2(13, 13)
	
	# Mover el enano suavemente
	var tween = create_tween()
	tween.tween_property(dwarf_instance, "position", target_position, 0.2)
	
	# Configurar flip horizontal según dirección
	var animated_sprite = dwarf_instance.get_node("AnimatedSprite2D")
	if direction == "E":
		animated_sprite.flip_h = false
	elif direction == "W":
		animated_sprite.flip_h = true
	
	if not animated_sprite.is_playing():
		animated_sprite.play("walk")
