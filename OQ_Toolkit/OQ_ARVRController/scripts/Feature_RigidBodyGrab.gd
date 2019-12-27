extends Spatial

class_name RigidBodyGrab

var controller : ARVRController = null;
var grab_area : Area = null;
var held_object = null;
var held_object_data = {};
var grab_mesh : MeshInstance = null;

enum {
	GRABTYPE_VELOCITY,
	GRABTYPE_PINJOINT, #!!TODO: not yet working; I first need to figure out how joints work
}
var grab_type = GRABTYPE_VELOCITY;

onready var main_node = get_node("/root/Main")

export var reparent_mesh = false;

func _ready():
	controller = get_parent();
	if (not controller is ARVRController):
		vr.log_error(" in Feature_RigidBodyGrab: parent not ARVRController.");
	grab_area = $GrabArea;
	
	controller.connect("button_pressed", self, "_on_ARVRController_button_pressed")
	controller.connect("button_release", self, "_on_ARVRController_button_release")


func start_grab_velocity(grabbable_rigid_body: GrabbableRigidBody):
	if grabbable_rigid_body.is_grabbed:
		return
	
	var temp_global_pos = grabbable_rigid_body.global_transform.origin
	var temp_rotation = grabbable_rigid_body.global_transform.basis
	
	grabbable_rigid_body.global_transform.origin = temp_global_pos
	grabbable_rigid_body.global_transform.basis = temp_rotation
	
	held_object = grabbable_rigid_body
	held_object.grab_init(self)


func release_grab_velocity():
	held_object.grab_release(self)
	held_object = null


func start_grab_pinjoint(rigid_body):
	held_object = rigid_body;
	$PinJoint.set_node_a($GrabArea.get_path());
	$PinJoint.set_node_b(held_object.get_path());
	print("Grab PinJoint");
	pass;

func release_grab_pinjoint():
	pass;


func grab():
	if (held_object):
		return
	
	# find the right rigid body to grab
	var grabbable_rigid_body = null;
	var bodies = grab_area.get_overlapping_bodies();
	if len(bodies) > 0:
		for body in bodies:
			if body is GrabbableRigidBody:
					if body.is_grabbable:
						grabbable_rigid_body = body

	if grabbable_rigid_body:
		if (grab_type == GRABTYPE_VELOCITY): start_grab_velocity(grabbable_rigid_body)
		#elif (grab_type == GRABTYPE_PINJOINT): start_grab_pinjoint(rigid_body);	


func release():
	if !held_object:
		return
		
	if (grab_type == GRABTYPE_VELOCITY): release_grab_velocity();
	elif (grab_type == GRABTYPE_PINJOINT): release_grab_pinjoint();


func _on_ARVRController_button_pressed(button_number):
	if button_number != vr.CONTROLLER_BUTTON.GRIP_TRIGGER:
		return
	
	# if grab button, grab
	grab()

func _on_ARVRController_button_release(button_number):
	if button_number != vr.CONTROLLER_BUTTON.GRIP_TRIGGER:
		return
	
	# if grab button, grab
	release()
