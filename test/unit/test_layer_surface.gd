extends GutTest
## Pixel checks need a real renderer; under --headless they are marked pending.

var canvas_scene: PackedScene = load("res://system/canvas/canvas.tscn")


func _solid(w: int, h: int, c: Color) -> ImageTexture:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(c)
	return ImageTexture.create_from_image(img)


func _blank(w: int, h: int, c: Color = Color.TRANSPARENT) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(c)
	return img


func _skip_headless() -> bool:
	if not LayerSurface.is_supported():
		pending("DrawableTexture2D needs a renderer; run without --headless")
		return true
	return false


func test_round_trip_preserves_straight_alpha():
	if _skip_headless():
		return
	var src := _blank(4, 4)
	src.set_pixel(1, 1, Color(1, 0, 0, 0.5))
	src.set_pixel(2, 2, Color(0.2, 0.4, 0.6, 1))
	var out := LayerSurface.new(src).to_image()
	assert_eq(out.get_format(), Image.FORMAT_RGBA8, "Output is RGBA8")
	assert_true(out.get_pixel(1, 1).is_equal_approx(src.get_pixel(1, 1)), "Half alpha kept")
	assert_true(out.get_pixel(2, 2).is_equal_approx(src.get_pixel(2, 2)), "Opaque kept")
	assert_eq(out.get_pixel(0, 0).a, 0.0, "Transparent kept")


func test_stamp_on_transparent_has_no_white_fringe():
	if _skip_headless():
		return
	var surface := LayerSurface.new(_blank(8, 8))
	surface.stamp(_solid(1, 1, Color(1, 1, 1, 0.5)), Vector2(4, 4), Vector2(2, 2), Color.RED)
	var px := surface.to_image().get_pixel(4, 4)
	assert_almost_eq(px.r, 1.0, 0.01, "Color is pure red")
	assert_almost_eq(px.g, 0.0, 0.01, "No white bleed in green")
	assert_almost_eq(px.a, 0.5, 0.01, "Stamp alpha kept")


func test_overlapping_stamps_blend_over():
	if _skip_headless():
		return
	var surface := LayerSurface.new(_blank(8, 8))
	var half := _solid(1, 1, Color(1, 1, 1, 0.5))
	surface.stamp(half, Vector2(4, 4), Vector2(8, 8), Color.RED)
	surface.stamp(half, Vector2(4, 4), Vector2(8, 8), Color.BLUE)
	var px := surface.to_image().get_pixel(4, 4)
	# Blue at 0.5 over red at 0.5: a = 0.75, rgb = (1/3, 0, 2/3).
	assert_almost_eq(px.a, 0.75, 0.01, "Alpha composites")
	assert_almost_eq(px.r, 1.0 / 3.0, 0.01, "Red share")
	assert_almost_eq(px.b, 2.0 / 3.0, 0.01, "Blue share")


func test_stamp_rect_is_centered_and_clipped():
	if _skip_headless():
		return
	var surface := LayerSurface.new(_blank(8, 8))
	surface.stamp(_solid(1, 1, Color.WHITE), Vector2(0, 0), Vector2(4, 4), Color.GREEN)
	var out := surface.to_image()
	assert_eq(out.get_pixel(1, 1), Color.GREEN, "Inside stamp")
	assert_eq(out.get_pixel(2, 2).a, 0.0, "Outside stamp")


func test_canvas_surface_commits_with_undo():
	if _skip_headless():
		return
	var canvas: Canvas = canvas_scene.instantiate()
	add_child_autofree(canvas)
	var project := Project.new()
	project.new_project(16, 16)
	canvas.attach_project(project)

	var surface := canvas.begin_surface()
	assert_not_null(surface, "Surface created")
	surface.stamp(_solid(1, 1, Color.WHITE), Vector2(8, 8), Vector2(4, 4), Color.BLUE)
	canvas.end_surface()

	var layer: Image = project.get_current_page().layers[project.current_layer]
	assert_eq(layer.get_pixel(8, 8), Color.BLUE, "Stroke committed to layer")
	project.undo_redo.undo()
	layer = project.get_current_page().layers[project.current_layer]
	assert_eq(layer.get_pixel(8, 8).a, 0.0, "Undo restores the layer")


func test_canvas_surface_unavailable_headless():
	if LayerSurface.is_supported():
		pass_test("Renderer present; headless fallback not exercised")
		return
	var canvas: Canvas = canvas_scene.instantiate()
	add_child_autofree(canvas)
	var project := Project.new()
	project.new_project(16, 16)
	canvas.attach_project(project)
	assert_null(canvas.begin_surface(), "Headless falls back to the bake path")
