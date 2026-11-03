extends SceneTree
## Compares one brush stroke through the SubViewport bake path vs LayerSurface.
## Run with a renderer (not --headless):
##   godot --path . -s test/bench/bench_drawable_texture.gd

const SIZES := [Vector2i(256, 192), Vector2i(1024, 768)]
const STAMPS := 200
const RUNS := 5


func _init() -> void:
	await process_frame
	var canvas: Canvas = load("res://system/canvas/canvas.tscn").instantiate()
	root.add_child(canvas)
	var stamp: Texture2D = load("res://assets/brush_templates/big_circle.png")

	for size in SIZES:
		var project := Project.new()
		project.new_project(size.x, size.y)
		canvas.attach_project(project)
		canvas.render_page(project.get_current_page())

		var bake_ms := 0.0
		var surface_ms := 0.0
		for run in RUNS:
			var t0 := Time.get_ticks_usec()
			for i in STAMPS:
				var s := Sprite2D.new()
				s.texture = stamp
				s.position = _pos(i, size)
				s.scale = Vector2.ONE * 8.0 / stamp.get_width()
				s.modulate = Color.RED
				canvas.dynamic_node.add_child(s)
			await canvas.bake_page()
			bake_ms += (Time.get_ticks_usec() - t0) / 1000.0

			t0 = Time.get_ticks_usec()
			var surface := canvas.begin_surface()
			for i in STAMPS:
				surface.stamp(stamp, _pos(i, size), Vector2(8, 8), Color.BLUE)
			canvas.end_surface()
			surface_ms += (Time.get_ticks_usec() - t0) / 1000.0

		print(
			"%dx%d, %d stamps: bake %.1f ms, LayerSurface %.1f ms (avg of %d)"
			% [size.x, size.y, STAMPS, bake_ms / RUNS, surface_ms / RUNS, RUNS]
		)
	quit()


func _pos(i: int, size: Vector2i) -> Vector2:
	return Vector2(float(i * 37 % size.x), float(i * 53 % size.y))
