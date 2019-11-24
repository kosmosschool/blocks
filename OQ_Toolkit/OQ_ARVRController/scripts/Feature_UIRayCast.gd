extends Spatial

export var ui_raycast_length := 3;
export var ui_mesh_length := 1;
export(vr.CONTROLLER_BUTTON) var ui_raycast_visible_button := vr.CONTROLLER_BUTTON.TOUCH_INDEX_TRIGGER;
export(vr.CONTROLLER_BUTTON) var ui_raycast_click_button := vr.CONTROLLER_BUTTON.INDEX_TRIGGER;

var controller : ARVRController = null;
onready var ui_raycast : RayCast = $RayCastPosition/RayCast;
onready var ui_raycast_mesh : MeshInstance = $RayCastPosition/RayCastMesh;
onready var ui_raycast_hitmarker : MeshInstance = $RayCastPosition/RayCastHitMarker;


func _update_raycasts():
	ui_raycast_hitmarker.visible = false;
	
	# show only when trigger is touched
	if (ui_raycast_visible_button == vr.CONTROLLER_BUTTON.None ||
		controller._button_pressed(ui_raycast_visible_button) ||
		controller._button_pressed(ui_raycast_click_button)): 
		ui_raycast_mesh.visible = true;
	else:
		ui_raycast_mesh.visible = false;
		
	ui_raycast.force_raycast_update(); # need to update here to get the current position; else the marker laggs behind
	
	if ui_raycast.is_colliding():
		var c = ui_raycast.get_collider();
		if (!c.has_method("ui_raycast_hit_event")): return;
		var click = controller._button_just_pressed(ui_raycast_click_button);
		var release = controller._button_just_released(ui_raycast_click_button);
		var position = ui_raycast.get_collision_point();
		ui_raycast_hitmarker.visible = true;
		ui_raycast_hitmarker.global_transform.origin = position;
		c.ui_raycast_hit_event(position, click, release);

func _ready():
	controller = get_parent();
	if (not controller is ARVRController):
		vr.log_error(" in Feature_UIRayCast: parent not ARVRController.");
	else:
		$RayCastPosition.translation.y = -0.005;
		$RayCastPosition.translation.z = -0.01;
		# center the ray cast better to the actual controller position
		if (controller.controller_id == 1):
			$RayCastPosition.translation.x = -0.01;
		if (controller.controller_id == 2):
			$RayCastPosition.translation.x =  0.01;
	
	ui_raycast.set_cast_to(Vector3(0, 0, -ui_raycast_length));
	
	#setup the mesh
	ui_raycast_mesh.mesh.size.z = ui_mesh_length;
	ui_raycast_mesh.translation.z = -ui_mesh_length * 0.5;
	
	ui_raycast_hitmarker.visible = false;
	ui_raycast_mesh.visible = false;

func _process(dt):
	_update_raycasts();
