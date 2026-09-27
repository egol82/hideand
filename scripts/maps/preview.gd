extends Control
## Miniature tactical preview is derived from the public plan, never from actor positions.
const Plans = preload("res://scripts/maps/plans.gd")
const Catalog = preload("res://scripts/maps/catalog.gd")
var map_id := "sugar_market"
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var spec := Catalog.spec(map_id)
	var plan := Plans.layout(map_id)
	var scale2: float = minf((size.x-12)/spec.size.x,(size.y-12)/spec.size.y)
	var rect := Rect2((size-spec.size*scale2)*0.5,spec.size*scale2)
	draw_rect(rect,Color("e8e0c9"))
	for z in plan.zones:
		draw_rect(Rect2(rect.position+(z.rect.position+spec.size*0.5)*scale2,z.rect.size*scale2),Color("dca866") if z.loud else Color("94bbae"))
	for p in plan.props:
		draw_rect(Rect2(rect.position+(p.at-p.size*0.5+spec.size*0.5)*scale2,p.size*scale2),p.color.darkened(0.2))
	for h in plan.hideouts:
		var point: Vector2 = rect.position+(h.at+spec.size*0.5)*scale2
		draw_circle(point,2.2,Color("57746f"))
	draw_rect(rect,Color("6a8781"),false,1.2)
