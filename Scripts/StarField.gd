extends Node2D

var stars = []
var star_count = 80

func _ready():
	var vp = get_viewport_rect().size
	for i in star_count:
		stars.append({
			"pos": Vector2(randf() * vp.x, randf() * vp.y),
			"speed": randf_range(20, 80),
			"size": randf_range(1, 3)
		})

func _process(delta):
	var vp = get_viewport_rect().size
	for star in stars:
		star["pos"].y += star["speed"] * delta
		if star["pos"].y > vp.y:
			star["pos"].y = 0
			star["pos"].x = randf() * vp.x
	queue_redraw()

func _draw():
	for star in stars:
		draw_circle(star["pos"], star["size"], Color(1, 1, 1, 0.6))
