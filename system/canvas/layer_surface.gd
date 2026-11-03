class_name LayerSurface
extends RefCounted
## GPU drawing surface for a single layer, backed by [DrawableTexture2D]. [br]
## Contents are kept in premultiplied alpha so the default blit blend
## ([code]blend_mix[/code]) is a correct "over" operation even on transparent
## pixels. Display it with a premultiplied [CanvasItemMaterial] and read it back
## with [method to_image]. [br]
## [b]Note:[/b] DrawableTexture2D is experimental in Godot 4.7.

const PREMULTIPLY_SHADER: Shader = preload("res://system/canvas/shaders/blit_premultiply.gdshader")
const UNPREMULTIPLY_SHADER: Shader = preload(
	"res://system/canvas/shaders/blit_unpremultiply.gdshader"
)

## Half-float storage avoids banding from premultiplying low-alpha colors.
const WORK_FORMAT := DrawableTexture2D.DRAWABLE_FORMAT_RGBAH

static var _premultiply: ShaderMaterial
static var _unpremultiply: ShaderMaterial

var texture: DrawableTexture2D
var width: int
var height: int


## [param image] - Straight-alpha layer image to start from.
func _init(image: Image) -> void:
	width = image.get_width()
	height = image.get_height()
	texture = DrawableTexture2D.new()
	texture.setup(width, height, WORK_FORMAT, Color.TRANSPARENT)
	texture.blit_rect(
		Rect2i(0, 0, width, height),
		ImageTexture.create_from_image(image),
		Color.WHITE,
		0,
		_material(true)
	)


## Returns false when no real renderer is available (e.g. headless runs),
## where blits are no-ops.
static func is_supported() -> bool:
	return DisplayServer.get_name() != "headless"


## Blends [param stamp] tinted by [param color] over the surface. [br]
## [param center] - Center of the stamp in layer pixels. [br]
## [param size] - Size the stamp is drawn at, in pixels.
func stamp(stamp_tex: Texture2D, center: Vector2, size: Vector2, color: Color) -> void:
	var rect_size := Vector2i(maxi(1, roundi(size.x)), maxi(1, roundi(size.y)))
	var origin := Vector2i((center - Vector2(rect_size) / 2.0).round())
	texture.blit_rect(Rect2i(origin, rect_size), stamp_tex, color)


## Reads the surface back as a straight-alpha [constant Image.FORMAT_RGBA8] image.
func to_image() -> Image:
	var out := DrawableTexture2D.new()
	out.setup(width, height, DrawableTexture2D.DRAWABLE_FORMAT_RGBA8, Color.TRANSPARENT)
	out.blit_rect(Rect2i(0, 0, width, height), texture, Color.WHITE, 0, _material(false))
	var img := out.get_image()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	return img


## Material for displaying the surface on a [CanvasItem].
static func display_material() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	return mat


static func _material(premultiply: bool) -> ShaderMaterial:
	if premultiply:
		if _premultiply == null:
			_premultiply = ShaderMaterial.new()
			_premultiply.shader = PREMULTIPLY_SHADER
		return _premultiply
	if _unpremultiply == null:
		_unpremultiply = ShaderMaterial.new()
		_unpremultiply.shader = UNPREMULTIPLY_SHADER
	return _unpremultiply
