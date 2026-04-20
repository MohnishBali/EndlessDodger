extends CharacterBody2D

const SPEED = 400.0
var screen_width: float
var health: int = 2
var is_invincible: bool = false

var bullet_scene = preload("res://Scenes/PlayerBullet.tscn")
var can_shoot: bool = true
var shoot_cooldown: float = 0.35  # Seconds between shots

func _ready():
	screen_width = get_viewport_rect().size.x
	position.x = screen_width / 2.0
	position.y = get_viewport_rect().size.y - 80

func _physics_process(delta):
	screen_width = get_viewport_rect().size.x
	var screen_height = get_viewport_rect().size.y
	
	var dir_x = 0
	var dir_y = 0
	
	if Input.is_action_pressed("ui_left"):
		dir_x = -1
	elif Input.is_action_pressed("ui_right"):
		dir_x = 1
	if Input.is_action_pressed("ui_up"):
		dir_y = -1
	elif Input.is_action_pressed("ui_down"):
		dir_y = 1

	velocity.x = dir_x * SPEED
	velocity.y = dir_y * SPEED
	move_and_slide()
	
	position.x = clamp(position.x, 25, screen_width - 25)
	position.y = clamp(position.y, screen_height * 0.4, screen_height - 50)

func _input(event):
	if event.is_action_pressed("ui_select") and can_shoot:
		shoot()

func shoot():
	can_shoot = false
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = global_position + Vector2(0, -60)

	# Reset cooldown
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func take_hit():
	if is_invincible:
		return
	health -= 1
	is_invincible = true
	
	#This is to flash the ship so the player knoows they've been hit
	for i in 4:
		modulate = Color(1, 0.2, 0.2, 0.4)
		await get_tree().create_timer(0.1).timeout
		modulate = Color(1, 1, 1, 1)
		await get_tree().create_timer(0.1).timeout
	
	is_invincible = false
	
	if health <= 0:
		var arena = get_tree().get_first_node_in_group("arena")
		if arena: 
			arena.play_hit_sfx("player")
			arena.trigger_game_over()
