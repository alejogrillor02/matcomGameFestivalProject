extends Node2D

@onready var tile_map: TileMap = $TileMap
@onready var move_timer: Timer = $MoveTimer
@onready var dwarf_instance: Node2D = $Dwarf
@onready var camera = $Camera2D
@onready var title_text = $CanvasLayer/TitleText
@onready var press_space_text = $CanvasLayer/PressSpaceText
@onready var restart_button = $ButtonLayer/RestartButton
@onready var exit_instance = $Exit
@onready var sign_button = $ButtonLayer/SignButton
@onready var sign_preview: Sprite2D = $SignPreview

var sign_scene = preload("res://scenes/sign.tscn")

var dirs = {
	"N": Vector2i(0, 1),
	"S": Vector2i(0, -1),
	"E": Vector2i(1, 0),
	"W": Vector2i(-1, 0)
}

var level_counters = {
	"1": 3,
	"2": 5,
	"3": 6
}

var dwarf_dir = "E"
var sign_counter

var game_started = false
var sign_placement_mode = false

var dwarf_pos: Vector2i
var exit_pos: Vector2i

var grid: Array = []
var signs_placed: Array = []


func _ready() -> void:
	
	var level = int(get_tree().current_scene.scene_file_path[18])
	sign_counter = level_counters[str(level)]
	title_text.text = title_text.text + str(level)
	
	dwarf_pos = local_to_used_rect(dwarf_instance.position + Vector2(13, 13))
	exit_pos = local_to_used_rect(exit_instance.position + Vector2(13, 13))
	
	dwarf_instance.get_node("AnimatedSprite2D").play("idle")
	
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
	
	# Configurar boton
	sign_button.get_node("Label").text = "x%d" % sign_counter
	
	restart_button.disabled = true
	sign_button.disabled = true
	
	sign_preview.hide()


func _process(_delta) -> void:
	if not game_started and Input.is_action_just_pressed("ui_accept"):
		game_started = true
		$MoveTimer.start()
		$CanvasLayer.hide()
		
		# Animación de alejamiento de la cámara
		var tween = create_tween()
		tween.tween_property(camera, "zoom", Vector2(2, 2), 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		
		dwarf_instance.get_node("AnimatedSprite2D").play("walk")
		
		restart_button.disabled = false
		sign_button.disabled = false


func local_to_used_rect(pixel_pos: Vector2) -> Vector2i:
	# Convertir posición en píxeles a coordenadas del used_rect
	var tile_pos = tile_map.local_to_map(pixel_pos)
	var used_rect = tile_map.get_used_rect()
	return Vector2i(
		tile_pos.x - used_rect.position.x,
		tile_pos.y - used_rect.position.y
	)


func used_rect_to_local(pos: Vector2i) -> Vector2:
	# Convertir a coordenadas absolutas del TileMap
	var used_rect = tile_map.get_used_rect()
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
		
		if grid[ny][nx] == 1 and not check_for_sign(Vector2i(nx, ny)):
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
	
	if(dwarf_pos != exit_pos):
		move_dwarf(dwarf_dir)
		$MoveTimer.start()
	else:
		
		dwarf_instance.get_node("AnimatedSprite2D").play("win")
		await get_tree().create_timer(2).timeout
		
		# Cargar proxima escena a partir del path
		var level = int(get_tree().current_scene.scene_file_path[18]) + 1
		var path = "res://scenes/level"+str(level)+".tscn"
		get_tree().change_scene_to_file(path)


func move_dwarf(direction: String) -> void:
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


func _on_sign_button_pressed():
	sign_placement_mode = true
	sign_preview.show()
	sign_preview.position = get_global_mouse_position()		


func _input(event):
	if sign_placement_mode:
		sign_preview.position = get_global_mouse_position()
	
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			exit_sign_placement_mode()
			
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_pos = get_global_mouse_position()
			var tile_pos = tile_map.local_to_map(mouse_pos)
			var tile_data = tile_map.get_cell_tile_data(0, tile_pos)
			
			if tile_data and tile_data.get_custom_data("path"):
				place_sign(mouse_pos)
			
			else:
				exit_sign_placement_mode()


func place_sign(pos: Vector2) -> void:
	var new_sign = sign_scene.instantiate()
	new_sign.position = pos
	add_child(new_sign)
	exit_sign_placement_mode()
	signs_placed.append(local_to_used_rect(pos))
	sign_counter -= 1
	sign_button.get_node("Label").text = "x%d" % sign_counter
	if sign_counter == 0:
		sign_button.disabled = true


func exit_sign_placement_mode():
	sign_placement_mode = false
	sign_preview.hide()


func check_for_sign(tile_position: Vector2i) -> bool:
	for placed_sign in signs_placed:
		if placed_sign == tile_position:
			return true
	return false
