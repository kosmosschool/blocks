extends Area

# this area snaps the building block (which needs to be its parent) to another snap area
class_name SnapArea


signal area_snapped
signal area_unsnapped

var snap_area_other_area : Area
var other_area_parent_block
var z_difference := 1
var x_difference := 1
var connection_id : String
var is_master := false
var snapping := false
var snap_speed := 10.0
var snap_timer := 0.0
var snap_start_transform : Transform
var snap_end_transform : Transform
var interpolation_progress : float
var moving_connection_added := false

var snapped := false setget , get_snapped
var initial_grab := false setget set_initial_grab, get_initial_grab
var move_to_snap := false setget , get_move_to_snap

onready var parent_block := get_parent()
onready var schematic  := get_node("/root/Main/Schematic")

enum Polarity {UNDEFINED, POSITIVE, NEGATIVE}
export (Polarity) var polarity
enum ConnectionSide {A, B}
export (ConnectionSide) var connection_side
enum LocationOnBlock {LENGTH, WIDTH}
export (LocationOnBlock) var location_on_block


func get_snapped():
	return snapped


func set_initial_grab(new_value):
	initial_grab = new_value


func get_initial_grab():
	return initial_grab


func get_move_to_snap():
	return move_to_snap


# this is a hacky workaround because of this issue: https://github.com/godotengine/godot/issues/25252
func is_class(type):
	return type == "SnapArea" or .is_class(type)


func _ready():
	connect("area_entered", self, "_on_Snap_Area_area_entered")
	connect("area_exited", self, "_on_Snap_Area_area_exited")


func _process(delta):
	check_for_removal()
	
	if move_to_snap:
		update_pos_to_snap(delta)
	
	if !snap_area_other_area:
		return
	
	# we have to do this check because it's possible the other area was deleted in the meantime
	if !is_instance_valid(snap_area_other_area):
		return
	
	if parent_block.get_moving_to_snap() and !move_to_snap and !moving_connection_added:
		# this happens when the area overlaps with another while being moved to snap
		# but the movement has originated from another area from the same block
		# therefore, don't move but just create connection in schematic
		#print(parent_block.name + " " + self.name + " other area " + other_area_parent_block.name + " " + snap_area_other_area.name )
		connection_id = schematic_add_blocks(parent_block, polarity, connection_side, other_area_parent_block, snap_area_other_area.polarity, snap_area_other_area.connection_side)
		snap_area_other_area.connection_id = connection_id
		moving_connection_added = true
	
	
	# only the master snap area executes the following
	if !is_master:
		return
	
	# decide which block is grabbed
	if !snapping and !initial_grab and !snap_area_other_area.get_initial_grab():
		# if both are grabbed or ungrabbed, return
		if parent_block.is_grabbed == other_area_parent_block.is_grabbed:
			return
		
		if parent_block.is_grabbed and !other_area_parent_block.is_grabbed:
			initial_grab = true
		elif !parent_block.is_grabbed and other_area_parent_block.is_grabbed:
			snap_area_other_area.set_initial_grab(true)
	
	# start snapping process if one of the blocks has been grabbed initially but was now let go
	if (initial_grab and !parent_block.is_grabbed) or (snap_area_other_area.get_initial_grab() and !other_area_parent_block.is_grabbed):
		snapping = true
	
	# snapping has started
	if snapping:
		# either this or the other block must be ungrabbed
		# snap
		if initial_grab:
			snap_to_block(snap_area_other_area)
		elif snap_area_other_area.get_initial_grab():
			snap_area_other_area.snap_to_block(self)
		
		
		snapping = false
		initial_grab = false
		snap_area_other_area.set_initial_grab(false)
		
		# set up connection in schematic
		setup_connection(snap_area_other_area)


func _on_Snap_Area_area_entered(area):
	if snapped:
		return
	
	if snapping:
		return
	
	if !area.is_class("SnapArea"):
		return
	
	# don't allow adding length to length
	if area.location_on_block == LocationOnBlock.LENGTH and location_on_block == LocationOnBlock.LENGTH :
		return
	
	if area.snapped:
		return
	
	# assign master area
	if (!area.is_master):
		is_master = true
	
	snap_area_other_area = area
	other_area_parent_block = snap_area_other_area.get_parent()


func _on_Snap_Area_area_exited(area):
	pass
#	if !area.is_class("SnapArea"):
#		return
#
##	if snap_area_other_area and !snapped:
##		# only reset if snap_area_other_area is far enough
##		# we need to do this because with the small collisionshapes we use
##		# the area keeps entering and exiting all the time (probably a bug in Godot)
##		if other_area_distance() > 0.04:
##			snap_area_other_area = null
##			other_area_parent_block = null
#
#	# can only unsnap if being grabbed away
#	if is_master and snapped:
#		if parent_block.is_grabbed or other_area_parent_block.is_grabbed:
#			schematic_remove_connection()
#			snap_area_other_area.unsnap()
#			unsnap()

#	if !snapped and !move_to_snap and !snapping:
#		snap_area_other_area = null
#		other_area_parent_block = null


# we use this custom method instead of the area_exited or get_overlapping_areas
# we need to do this because with the small collisionshapes we use
# the area keeps entering and exiting all the time (probably a bug in Godot)
func check_for_removal():
	if !snap_area_other_area:
		return
	
	# we have to do this check because it's possible the other area was deleted in the meantime
	if !is_instance_valid(snap_area_other_area):
		return
	
	if move_to_snap or snapping:
		return
		
	if other_area_distance() < 0.04:
		return
	
	# if distance is greater, remove
	if is_master and snapped:
		schematic_remove_connection()
		snap_area_other_area.unsnap()
		unsnap()
	else:
		snap_area_other_area = null
		other_area_parent_block = null


# snaps this block to another block
func snap_to_block(other_snap_area: Area):
	snap_start_transform = parent_block.global_transform
	
	var current_other_area_parent_block = other_snap_area.get_parent()
	# move to far position but in right direction
	parent_block.global_transform.origin += other_snap_area.global_transform.basis.z.normalized() * 1000
	
	# rotate it so that this z-vector is aligned with other areas
	# z-vector, but in the opposite direction
	parent_block.global_transform = global_transform.looking_at(other_snap_area.global_transform.origin, Vector3(0, 1, 0))
	
	# rotate by 180° degrees
	parent_block.rotate_y(PI)
	
	# rotate by local y transform also
	parent_block.rotate_y(-rotation.y)
	
	# move to close pos
	# assuming other area's has a CollisionShape child and parent has CollisionShape child
	var this_block_extents = parent_block.get_node("CollisionShape").shape.extents
	var other_snap_area_extents = other_snap_area.get_node("CollisionShape").shape.extents
	var other_block_extents = current_other_area_parent_block.get_node("CollisionShape").shape.extents
	
	var move_by_vec = other_snap_area.global_transform.origin - global_transform.origin
	move_by_vec -= other_snap_area.global_transform.basis.z.normalized() * (other_snap_area_extents.x - 0.001) * 2
	parent_block.global_transform.origin += move_by_vec
	
	# assign back
	snap_end_transform = parent_block.global_transform
	parent_block.global_transform = snap_start_transform
	
	move_to_snap = true
	parent_block.set_moving_to_snap(true)


func unsnap():
	snapped = false
	is_master = false
	snap_area_other_area = null
	other_area_parent_block = null
	connection_id = ""
	moving_connection_added = false
	emit_signal("area_unsnapped")


# snaps to the other block over time, updating position and rotation
func update_pos_to_snap(delta: float) -> void:
	snap_timer += delta
	interpolation_progress = snap_timer * snap_speed
	
	if interpolation_progress > 1.0:
		parent_block.set_moving_to_snap(false)
		move_to_snap = false
		snap_timer = 0.0
		snapped = true
		snap_area_other_area.snapped = true
		other_area_parent_block.set_snapped(true)
		emit_signal("area_snapped")
		
		return
	
	parent_block.global_transform = snap_start_transform.interpolate_with(snap_end_transform, interpolation_progress)


func setup_connection(_other_area):
	connection_id = schematic_add_blocks(
		parent_block,
		polarity,
		connection_side,
		_other_area.get_parent(),
		_other_area.polarity,
		_other_area.connection_side
	)
	snap_area_other_area.connection_id = connection_id

# double checks if really not overlapping an area
# called from parent after every succesful snap
func doublecheck_snap() -> void:
	var overlapping_areas = get_overlapping_areas()
	for overlapping_area in overlapping_areas:
		if !overlapping_area.get_snapped() or !overlapping_area.get_move_to_snap():
			setup_connection(overlapping_area)


func other_area_distance() -> float:
	return get_global_transform().origin.distance_to(snap_area_other_area.get_global_transform().origin)
	
	
# update the schematic with this new connection
func schematic_add_blocks(
	_building_block1: BuildingBlock,
	_polarity1: int,
	_connection_side1: int,
	_building_block2: BuildingBlock,
	_polarity2: int,
	_connection_side2: int
) -> String:
	
	var return_connection_id = schematic.add_blocks(
		_building_block1,
		_polarity1,
		_connection_side1,
		_building_block2,
		_polarity2,
		_connection_side2
	)
	schematic.loop_current_method()
	
	return return_connection_id


func schematic_remove_connection():
	schematic.remove_connection(connection_id)
	schematic.loop_current_method()
