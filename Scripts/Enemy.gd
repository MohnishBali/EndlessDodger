extends CharacterBody2D

var speed: float = 120.0
var direction: float = 1.0
var screen_width: float
var health: int = 2

var enemy_bullet_scene = preload("res://Scenes/EnemyBullet.tscn")

@onready var shoot_timer: Timer = $ShootTimer

func _ready():
	screen_width = get_viewport_rect().size.x
	direction = [-1.0, 1.0].pick_random()
	shoot_timer.connect("timeout", _on_shoot_timer_timeout)
	shoot_timer.start()  # Always start explicitly

func _physics_process(delta):
	# Direct position — no physics collision between enemies
	position.x += direction * speed * delta

	if position.x <= 30:
		direction = 1.0
		position.x = 31
	elif position.x >= screen_width - 30:
		direction = -1.0
		position.x = screen_width - 31

func _on_shoot_timer_timeout():
	if not is_inside_tree():
		return  # Safety check — don't shoot if already freed
	var bullet = enemy_bullet_scene.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = global_position + Vector2(0, 40)

func take_hit():
	health -= 1
	modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	if not is_inside_tree():
		return  # Guard against being freed mid-flash
	modulate = Color(1, 1, 1)
	if health <= 0:
		var arena = get_tree().get_first_node_in_group("arena")
		if arena:
			arena.register_kill()
		queue_free()
