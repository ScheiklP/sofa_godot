tool
extends ImmediateGeometry
##
## @author: Pit Henrich
## @desc: A class for enabling in-editor debug drawing.
##


var material = SpatialMaterial.new()
var lines = []

class Line:
	func _init(p0, p1, color):
		self.p0 = p0
		self.p1 = p1
		self.color = color
	var p0
	var p1
	var color

func draw_line(p0, p1, color : Color = Color(1,0,0,1)):
	lines.push_back(Line.new(p0, p1, color))
func draw_line_world_space(object, p0, p1, color : Color = Color(1,0,0,1)):
	lines.push_back(Line.new(p0 - object.get_global_transform().origin, p1 - object.get_global_transform().origin, color))

func _enter_tree():
	if Engine.is_editor_hint():
		set_process(true)
		material.flags_use_point_size = true
		material.vertex_color_use_as_albedo = true
		material.flags_unshaded = true
		material.flags_transparent = true
		
		
func _process(delta):
	if Engine.is_editor_hint():
		
		clear()
		for l in lines:
			if l.p0 == null or l.p1 == null:
				continue
			set_material_override(material)
			# Draw points
			#begin(Mesh.PRIMITIVE_POINTS, null)
			#add_vertex(l.p0)
			#add_vertex(l.p1)
			#end()
			# Draw lines
			begin(Mesh.PRIMITIVE_LINE_STRIP, null)
			set_color(l.color)
			add_vertex(l.p0)
			add_vertex(l.p1)
			end()
	lines.clear()
