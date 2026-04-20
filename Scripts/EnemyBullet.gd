extends Area2D

var speed: float = 350.0

func _ready():
	connect("body_entered", _on_body_entered)

func _process(delta):
	position.y += speed * delta
	if position.y > get_viewport_rect().size.y + 30:
		queue_free()

func _on_body_entered(body):
	if body.name == "Player":
		var arena = get_tree().get_first_node_in_group("arena")
		if arena:
			arena.play_hit_sfx("player")
		body.take_hit()
		queue_free()
