extends Node3D

const SHIP_SCRIPT = preload("res://scripts/ship.gd")
const UI_SCRIPT = preload("res://scripts/hud.gd")

var ship: RigidBody3D
var earth: Node3D
var camera: Camera3D

func _ready() -> void:
	_build_stars()
	_build_earth()
	_build_ship()
	_build_lighting()
	_build_camera()
	var hud := CanvasLayer.new()
	hud.set_script(UI_SCRIPT)
	add_child(hud)
	hud.ship = ship

func _build_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-24, -35, 0)
	sun.light_energy = 2.0
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.002, 0.004, 0.02)
	sky_mat.sky_horizon_color = Color(0.008, 0.015, 0.045)
	sky_mat.ground_bottom_color = Color(0.001, 0.002, 0.008)
	sky_mat.ground_horizon_color = Color(0.004, 0.008, 0.02)
	sky.sky_material = sky_mat
	env.sky = sky
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	world.environment = env
	add_child(world)

func _build_earth() -> void:
	earth = Node3D.new()
	earth.position = Vector3(0, 0, -7000)
	add_child(earth)
	var planet := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 6371.0
	sphere.height = 12742.0
	sphere.radial_segments = 96
	sphere.rings = 48
	planet.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.28, 0.62)
	mat.roughness = 0.82
	mat.metallic = 0.05
	mat.emission_enabled = true
	mat.emission = Color(0.005, 0.025, 0.08)
	mat.emission_energy_multiplier = 0.22
	planet.material_override = mat
	earth.add_child(planet)
	var cloud := MeshInstance3D.new()
	var cloud_mesh := SphereMesh.new()
	cloud_mesh.radius = 6410.0
	cloud_mesh.height = 12820.0
	cloud_mesh.radial_segments = 96
	cloud_mesh.rings = 48
	cloud.mesh = cloud_mesh
	var cloud_mat := StandardMaterial3D.new()
	cloud_mat.albedo_color = Color(0.72, 0.82, 0.92, 0.10)
	cloud_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cloud_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cloud_mat.cull_mode = BaseMaterial3D.CULL_FRONT
	cloud.material_override = cloud_mat
	earth.add_child(cloud)
	var atmo := MeshInstance3D.new()
	var atmo_mesh := SphereMesh.new()
	atmo_mesh.radius = 6500.0
	atmo_mesh.height = 13000.0
	atmo_mesh.radial_segments = 96
	atmo_mesh.rings = 48
	atmo.mesh = atmo_mesh
	var atmo_mat := StandardMaterial3D.new()
	atmo_mat.albedo_color = Color(0.12, 0.48, 1.0, 0.12)
	atmo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	atmo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	atmo_mat.cull_mode = BaseMaterial3D.CULL_FRONT
	atmo.material_override = atmo_mat
	earth.add_child(atmo)

func _build_ship() -> void:
	ship = RigidBody3D.new()
	ship.name = "Spacecraft"
	ship.set_script(SHIP_SCRIPT)
	ship.position = Vector3(0, 0, 0)
	ship.mass = 12000.0
	ship.gravity_scale = 0.0
	ship.linear_damp = 0.0
	ship.angular_damp = 0.0
	add_child(ship)
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.8, 1.5, 8.0)
	body.mesh = mesh
	var hull := StandardMaterial3D.new()
	hull.albedo_color = Color(0.72, 0.78, 0.86)
	hull.metallic = 0.72
	hull.roughness = 0.28
	body.material_override = hull
	ship.add_child(body)
	var nose := MeshInstance3D.new()
	var nose_mesh := PrismMesh.new()
	nose_mesh.size = Vector3(2.8, 1.5, 3.2)
	nose.mesh = nose_mesh
	nose.position.z = -5.2
	nose.material_override = hull
	ship.add_child(nose)
	for side in [-1.0, 1.0]:
		var wing := MeshInstance3D.new()
		var wm := BoxMesh.new()
		wm.size = Vector3(4.0, 0.16, 2.8)
		wing.mesh = wm
		wing.position = Vector3(side * 3.0, 0, 1.0)
		wing.material_override = hull
		ship.add_child(wing)
		var engine := MeshInstance3D.new()
		var em := CylinderMesh.new()
		em.top_radius = 0.38
		em.bottom_radius = 0.55
		em.height = 1.0
		engine.mesh = em
		engine.position = Vector3(side * 0.75, 0, 4.4)
		engine.rotation_degrees.x = 90
		var glow := StandardMaterial3D.new()
		glow.albedo_color = Color(0.1, 0.45, 1.0)
		glow.emission_enabled = true
		glow.emission = Color(0.05, 0.35, 1.0)
		glow.emission_energy_multiplier = 4.0
		engine.material_override = glow
		ship.add_child(engine)

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 72.0
	add_child(camera)

func _build_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 712367
	var mesh := SphereMesh.new()
	mesh.radius = 0.8
	mesh.height = 1.6
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.8, 0.88, 1.0)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = 900
	for i in range(mm.instance_count):
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
		var tr := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * rng.randf_range(0.5, 2.2)), dir * 24000.0)
		mm.set_instance_transform(i, tr)
	var stars := MultiMeshInstance3D.new()
	stars.multimesh = mm
	stars.material_override = mat
	add_child(stars)

func _process(delta: float) -> void:
	if is_instance_valid(ship) and is_instance_valid(camera):
		var target := ship.global_position + ship.global_basis * Vector3(0, 5.0, 18.0)
		camera.global_position = camera.global_position.lerp(target, 1.0 - exp(-4.0 * delta))
		camera.look_at(ship.global_position, ship.global_basis.y)
	if is_instance_valid(earth):
		earth.rotate_y(0.0007)
