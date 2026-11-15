extends RigidBody3D

@export var max_thrust: float = 240000.0
@export var reverse_thrust: float = 80000.0
@export var rcs_force: float = 18000.0
@export var torque_strength: float = 52000.0
@export var fuel_capacity: float = 8200.0
@export var fuel: float = 8200.0
@export var exhaust_velocity: float = 3200.0
@export var earth_mu: float = 3.986004e14
@export var atmosphere_height: float = 8500.0
@export var atmosphere_limit: float = 120000.0
@export var drag_coefficient: float = 0.45
@export var reference_area: float = 18.0

var throttle := 0.0
var steering := Vector2.ZERO
var roll_input := 0.0
var lateral_input := Vector2.ZERO
var acceleration := Vector3.ZERO
var last_velocity := Vector3.ZERO
var delta_v := 0.0
var engine_on := false

func _ready() -> void:
	mass = 12000.0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	last_velocity = Vector3.ZERO
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	continuous_cd = true
	can_sleep = false

func _physics_process(delta: float) -> void:
	var forward_cmd := Input.get_action_strength("thrust_forward") - Input.get_action_strength("thrust_back")
	var pitch_cmd := Input.get_action_strength("pitch_down") - Input.get_action_strength("pitch_up")
	var yaw_cmd := Input.get_action_strength("yaw_left") - Input.get_action_strength("yaw_right")
	var roll_cmd := Input.get_action_strength("roll_left") - Input.get_action_strength("roll_right")
	var thrust_cmd := forward_cmd + throttle
	var steer := steering + Vector2(yaw_cmd, pitch_cmd)
	var roll := roll_input + roll_cmd
	var side := lateral_input.x + Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var vertical := lateral_input.y + Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	if freeze and (absf(thrust_cmd) > 0.001 or absf(steer.x) + absf(steer.y) + absf(roll) + absf(side) + absf(vertical) > 0.001):
		freeze = false
	var basis_now := global_basis
	var earth_center := Vector3(0, 0, -7000)
	var distance_km: float = maxf(100.0, global_position.distance_to(earth_center))
	var radius_m: float = distance_km * 1000.0
	var gravity: Vector3 = -((global_position - earth_center).normalized()) * earth_mu / (radius_m * radius_m)
	apply_central_force(gravity * mass)
	if fuel > 0.0 and abs(thrust_cmd) > 0.001:
		var thrust: float = max_thrust if thrust_cmd > 0.0 else reverse_thrust
		apply_central_force(-basis_now.z * thrust * abs(thrust_cmd))
		var used: float = thrust * absf(thrust_cmd) / (exhaust_velocity * 9.81) * delta
		fuel = max(0.0, fuel - used)
		mass = max(3800.0, mass - used)
		delta_v += thrust * abs(thrust_cmd) / mass * delta
		engine_on = true
	else:
		engine_on = false
	if abs(side) + abs(vertical) > 0.001:
		apply_central_force((basis_now.x * side + basis_now.y * vertical) * rcs_force)
	if abs(steer.x) + abs(steer.y) + abs(roll) > 0.001:
		apply_torque(basis_now * Vector3(steer.y, steer.x, roll) * torque_strength)
	var altitude_m: float = maxf(0.0, (distance_km - 6371.0) * 1000.0)
	var density: float = 1.225 * exp(-altitude_m / atmosphere_height) if altitude_m < atmosphere_limit else 0.0
	if density > 0.00001:
		var drag: Vector3 = -0.5 * density * linear_velocity.length() * linear_velocity * drag_coefficient * reference_area
		apply_central_force(drag)
	acceleration = (linear_velocity - last_velocity) / max(delta, 0.00001)
	last_velocity = linear_velocity

func altitude_km() -> float:
	var earth_center := Vector3(0, 0, -7000)
	return max(0.0, global_position.distance_to(earth_center) - 6371.75)

func speed_kms() -> float:
	return linear_velocity.length() / 1000.0

func gravity_value() -> float:
	var r: float = maxf(100000.0, global_position.distance_to(Vector3(0, 0, -7000)) * 1000.0)
	return earth_mu / (r * r)

func air_density() -> float:
	var h := altitude_km() * 1000.0
	return 1.225 * exp(-h / atmosphere_height) if h < atmosphere_limit else 0.0
