extends Area2D

var speed: float = 600.0

func _ready():
	connect("body_entered", _on_body_entered)

func _process(delta):
	position.y -= speed * delta
	if position.y < -30:
		queue_free()

func _on_body_entered(body):
	if body.has_method("take_hit") and body.name != "Player":
		#play hit sound via Arena
		var arena = get_tree().get_first_node_in_group("arena")
		if arena:
			arena.play_hit_sfx("enemy")
		body.take_hit()
		queue_free()
