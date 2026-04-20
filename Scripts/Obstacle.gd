extends Area2D

var speed: float = 200.0  # Will be set by the spawner

func _process(delta):
	position.y += speed * delta

	# Self-destroy when off screen (no memory leak)
	if position.y > get_viewport_rect().size.y + 60:
		queue_free()
