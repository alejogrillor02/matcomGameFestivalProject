extends Node2D

@onready var tile_map: TileMap = $TileMap
@onready var move_timer: Timer = $MoveTimer
@onready var dwarf_instance: Node2D = $Dwarf # Guardaremos la instancia del enano aquí
@onready var camera = $Camera2D
@onready var title_text = $CanvasLayer/TitleText
@onready var press_space_text = $CanvasLayer/PressSpaceText
@onready var restart_button = $ButtonLayer/Button

@onready var exit_instance = $exit # Instancia de la salida

var dirs = {
	"N": Vector2i(0, 1),
	"S": Vector2i(0, -1),
	"E": Vector2i(1, 0),
	"W": Vector2i(-1, 0)
}

var dwarf_pos: Vector2i
var dwarf_dir = "E"

var exit_pos: Vector2i

var grid: Array = []
var game_started = false


func _ready() -> void:
	# Determinar posición inicial basada en la posición del nodo
	dwarf_pos = local_to_used_rect(dwarf_instance.position + Vector2(13, 13))
	# Posición de la salida
	exit_pos = local_to_used_rect(exit_instance.position + Vector2(13, 13))
	
	
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
				
	#Empezar con el boton deshabilitado
	restart_button.disabled = true


func _process(_delta):
	if not game_started and Input.is_action_just_pressed("ui_accept"):
		game_started = true
		$MoveTimer.start()
		$CanvasLayer.hide()
		
		# Animación de alejamiento de la cámara
		var tween = create_tween()
		tween.tween_property(camera, "zoom", Vector2(2, 2), 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		
		#Habilitar el boton de reinicio
		restart_button.disabled = false
		


func local_to_used_rect(pixel_pos: Vector2) -> Vector2i:
	# Convertir posición en píxeles a coordenadas del used_rect
	var tile_pos = tile_map.local_to_map(pixel_pos)
	var used_rect = tile_map.get_used_rect()
	return Vector2i(
		tile_pos.x - used_rect.position.x,
		tile_pos.y - used_rect.position.y
	)


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
		
	if(dwarf_pos!=exit_pos):
		move_dwarf(dwarf_dir)
		$MoveTimer.start()
	else:
		await get_tree().create_timer(1).timeout
		get_tree().reload_current_scene()


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

