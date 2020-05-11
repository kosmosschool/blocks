extends BaseController


class_name AmmeterController


signal ampere_measured
signal ammeter_selected
signal ammeter_unselected

var ammeter_selected = false

onready var body_label = $BodyLabel
onready var measure_amp_sound = $AudioStreamPlayer3DMeasureAmpere


func _on_right_ARVRController_button_pressed(button_number):
	if !selected:
		return
	
	# check for trigger press
	if button_number != vr.CONTROLLER_BUTTON.INDEX_TRIGGER:
		return
	
	# check if is overlapping with a measurepoint
	var areas = grab_area_right.get_overlapping_areas()
	for area in areas:
		var area_parent = area.get_parent()
		if !(area_parent is MeasurePoint) or area_parent.measure_point_type != MeasurePoint.MeasurePointType.BLOCK:
			continue
		
		body_label.set_label_text("%.1f A" % area_parent.get_current())
		if measure_amp_sound:
			measure_amp_sound.play()
		emit_signal("ampere_measured", area_parent)


# override parent
func _on_Base_Controller_controller_selected():
	._on_Base_Controller_controller_selected()
	body_label.set_label_text("Touch an A-Box and press Trigger")
	ammeter_selected = true
	emit_signal("ammeter_selected")


# override parent
func _on_Base_Controller_controller_unselected():
	._on_Base_Controller_controller_selected()
	ammeter_selected = false
	emit_signal("ammeter_unselected")
	
