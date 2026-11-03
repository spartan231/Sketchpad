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
			"Brush  %dx%d, %d stamps: bake %.1f ms, LayerSurface %.1f ms (avg of %d)"
			% [size.x, size.y, STAMPS, bake_ms / RUNS, surface_ms / RUNS, RUNS]
		)
		_bench_eraser(canvas, stamp, size)
	quit()


func _bench_eraser(canvas: Canvas, stamp: Texture2D, size: Vector2i) -> void:
	var eraser := Eraser.new()
	eraser.original_stamp = stamp
	eraser.width = 8
	eraser.filter = eraser.generate_filter()
	var cpu_ms := 0.0
	var surface_ms := 0.0
	for run in RUNS:
		for use_surface in [false, true]:
			canvas.use_surface = use_surface
			var t0 := Time.get_ticks_usec()
			eraser.on_pointer_down(_pos(0, size), canvas)
			for i in range(1, STAMPS):
				eraser._place_stamp(_pos(i, size), canvas)
			eraser.on_pointer_up(_pos(STAMPS - 1, size), canvas)
			var ms := (Time.get_ticks_usec() - t0) / 1000.0
			if use_surface:
				surface_ms += ms
			else:
				cpu_ms += ms
	canvas.use_surface = true
	print(
		"Eraser %dx%d, %d stamps: CPU %.1f ms, LayerSurface %.1f ms (avg of %d)"
		% [size.x, size.y, STAMPS, cpu_ms / RUNS, surface_ms / RUNS, RUNS]
	)


func _pos(i: int, size: Vector2i) -> Vector2:
	return Vector2(float(i * 37 % size.x), float(i * 53 % size.y))
