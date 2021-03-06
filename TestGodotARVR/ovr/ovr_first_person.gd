extends ARVROrigin

# to combat motion sickness we'll 'step' our left/right turning
var turn_step = 0.0
export var turn_delay = 0.2
export var turn_angle = 20.0

var left_hand_controller = null
var right_hand_controller = null

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _on_controller_activated( controller ):
	if controller.get_hand()  == ARVRPositionalTracker.TRACKER_LEFT_HAND:
		left_hand_controller = controller
	else:
		right_hand_controller = controller


func _handle_teleport(on_controller):
	pass

func _apply_direct_motion(delta, left_right, forwards_backwards):
	if (abs(left_right) > 0.1):
		if left_right > 0.0:
			if turn_step < 0.0:
				# reset step
				turn_step = 0
			
			turn_step += left_right * delta
		else:
			if turn_step > 0.0:
				# reset step
				turn_step = 0
			
			turn_step += left_right * delta
		
		if abs(turn_step) > turn_delay:
			# we rotate around our Camera, but we adjust our origin, so we need a little bit of trickery
			var t1 = Transform()
			var t2 = Transform()
			var rot = Transform()
			
			t1.origin = -$ARVRCamera.transform.origin
			t2.origin = $ARVRCamera.transform.origin
			
			# Rotating
			while abs(turn_step) > turn_delay:
				if (turn_step > 0.0):
					rot = rot.rotated(Vector3(0.0,-1.0,0.0),turn_angle * PI / 180.0)
					turn_step -= turn_delay
				else:
					rot = rot.rotated(Vector3(0.0,1.0,0.0),turn_angle * PI / 180.0)
					turn_step += turn_delay
			
			transform = transform * t2 * rot * t1
	else:
		turn_step = 0.0

	if (abs(forwards_backwards) > 0.1):
		var t = $ARVRCamera.global_transform
		var dir = t.basis.z
		dir.y = 0.0
		
		# We can't use move and collide here because we're moving our world center and thus our kinematic body indirectly.
		# Need to improve on that...
		translation -= dir.normalized() * delta * forwards_backwards;

func _physics_process(delta):
	var left_right = 0.0
	var forwards_backwards = 0.0

	if left_hand_controller:
		if left_hand_controller.get_is_active():
			# implement teleport on left hand..
			_handle_teleport(left_hand_controller)
		else:
			left_hand_controller = null
			_handle_teleport(null)
			
	if right_hand_controller:
		if right_hand_controller.get_is_active():
			left_right = right_hand_controller.get_joystick_axis(0)
			forwards_backwards = right_hand_controller.get_joystick_axis(1)
		else:
			right_hand_controller = null
	else:
		# add check for gamepad and set left_right/forwards_backwards accordingly
		pass
		
	# apply direct motion
	_apply_direct_motion(delta, left_right, forwards_backwards)
