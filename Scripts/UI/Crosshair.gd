extends Control
class_name Crosshair

@export var dot_radius: float = 3.0
@export var dot_color: Color = Color.WHITE

func _draw():
	# Draws a simple dot in the center of the control node
	draw_circle(Vector2.ZERO, dot_radius, dot_color)
	
	# Draw horizontal and vertical lines for a larger crosshair
	var length: float = 15.0
	var thickness: float = 2.0
	draw_rect(Rect2(Vector2(-length, -thickness/2), Vector2(length * 2, thickness)), dot_color)
	draw_rect(Rect2(Vector2(-thickness/2, -length), Vector2(thickness, length * 2)), dot_color)

func _process(_delta: float):
	queue_redraw()