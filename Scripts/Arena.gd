extends Node2D

@onready var spawn_timer: Timer = $SpawnTimer
@onready var score_label: Label = $UI/ScoreLabel
@onready var game_over_label: Label = $UI/GameOverLabel
@onready var phase_label: Label = $UI/PhaseLabel
@onready var player = $Player
@onready var background: ColorRect = $ColorRect
@onready var bgm: AudioStreamPlayer2D = $BGM
@onready var sfx_enemy_hit: AudioStreamPlayer2D = $SFX_EnemyHit
@onready var sfx_player_hit: AudioStreamPlayer2D = $SFX_PlayerHit
@onready var kill_label: Label = $UI/KillLabel

var obstacle_scene = preload("res://Scenes/Obstacle.tscn")
var enemy_scene = preload("res://Scenes/Enemy.tscn")

var score: float = 0.0
var game_active: bool = true
var elapsed_time: float = 0.0
var current_speed: float = 150.0
var enemy_spawn_interval: float = 8.0
var time_since_last_enemy: float = 0.0
var kill_count: int = 0

func _ready():
	spawn_timer.connect("timeout", _on_spawn_timer_timeout)
	score_label.text = "Score: 0"
	game_over_label.visible = false
	kill_label.text = "Kills: 0"


func _process(delta):
	if not game_active:
		return

	elapsed_time += delta
	score += delta * 10
	score_label.text = "Score: %d" % int(score)

	# --- Difficulty Scaling (stretched to ~20 min) ---
	if elapsed_time < 60:
		# Phase 1: Calm (0 - 60s)
		current_speed = 150 + (elapsed_time * 1.0)
		spawn_timer.wait_time = clamp(1.2 - (elapsed_time * 0.002), 0.8, 1.2)
		background.color = Color(0.05, 0.05, 0.15, 1.0)
		phase_label.text = "Phase: CALM"
		phase_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))

	elif elapsed_time < 120:
		# Phase 2: Tense (60s - 120s)
		current_speed = 210 + ((elapsed_time - 60) * 2.0)
		spawn_timer.wait_time = clamp(0.8 - ((elapsed_time - 60) * 0.003), 0.55, 0.8)
		background.color = Color(0.2, 0.05, 0.3, 1.0)
		phase_label.text = "Phase: TENSE"
		phase_label.add_theme_color_override("font_color", Color(0.8, 0.4, 1.0))

	elif elapsed_time < 300:
		# Phase 3: Frantic (120s - 300s / 2min - 5min)
		current_speed = 330 + ((elapsed_time - 120) * 0.8)
		spawn_timer.wait_time = clamp(0.55 - ((elapsed_time - 120) * 0.001), 0.4, 0.55)
		background.color = Color(0.3, 0.03, 0.03, 1.0)
		phase_label.text = "Phase: FRANTIC"
		phase_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))

	else:
		# Phase 4: Endurance (300s+ / 5min+) — hard but survivable for skilled players
		current_speed = clamp(510 + ((elapsed_time - 300) * 0.3), 510, 650)
		spawn_timer.wait_time = 0.4
		background.color = Color(0.15, 0.0, 0.0, 1.0)
		phase_label.text = "Phase: ENDURANCE"
		phase_label.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1))
		
		
	# Enemy spawning — starts at Phase 2 (60s)
	if elapsed_time >= 60:
		time_since_last_enemy += delta
		if elapsed_time < 120:
			enemy_spawn_interval = 8.0
		elif elapsed_time < 300:
			enemy_spawn_interval = 5.0
		else:
			enemy_spawn_interval = 3.5
		
		if time_since_last_enemy >= enemy_spawn_interval:
			spawn_enemy()
			time_since_last_enemy = 0.0


func _on_spawn_timer_timeout():
	if not game_active:
		return

	var obstacle = obstacle_scene.instantiate()
	add_child(obstacle)

	var screen_w = get_viewport_rect().size.x
	obstacle.position.x = randf_range(30, screen_w - 30)
	obstacle.position.y = -30
	obstacle.speed = current_speed

	# Connect collision — body_entered for CharacterBody2D player
	obstacle.connect("body_entered", _on_obstacle_body_hit)


func _on_obstacle_body_hit(body):
	if body == player or body.name == "Player":
		sfx_player_hit.play()
		trigger_game_over()


func trigger_game_over():
	if not game_active:
		return

	game_active = false
	
	kill_label.text = "Enemies Destroyed: %d" % kill_count   # UPDATE label text
	kill_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))

	# Stop BGM and play hit sound if nodes exist
	if has_node("BGM"):
		bgm.stop()

	game_over_label.visible = true
	score_label.text = "Final Score: %d" % int(score)

	save_high_score(int(score))
	
	for child in get_children():
		if child is CharacterBody2D and child.name != "Player":
			child.queue_free()

	await get_tree().create_timer(2.0).timeout
	score_label.text = "\n[Press Enter to Restart]"


func _input(event):
	if not game_active and event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()


func save_high_score(new_score: int):
	var save = FileAccess.open("user://highscore.dat", FileAccess.WRITE)
	if save:
		save.store_var(new_score)
		save.close()

func spawn_enemy():
	if not game_active:
		return
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	var screen_w = get_viewport_rect().size.x
	enemy.position.x = randf_range(40, screen_w - 40)
	enemy.position.y = 60

	if elapsed_time < 120:
		enemy.speed = 100.0
		enemy.get_node("ShootTimer").wait_time = 2.5
	elif elapsed_time < 300:
		enemy.speed = 150.0
		enemy.get_node("ShootTimer").wait_time = 1.8
	else:
		enemy.speed = 200.0
		enemy.get_node("ShootTimer").wait_time = 1.2

func play_hit_sfx(type: String):
	if type == "enemy":
		sfx_enemy_hit.play()
	elif type == "player":
		sfx_player_hit.play()
		
func register_kill():
	kill_count += 1
	kill_label.text = "Kills: %d" % kill_count
