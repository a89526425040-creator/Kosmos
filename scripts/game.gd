extends Node3D

const SHIP_SCRIPT = preload("res://scripts/ship.gd")
const UI_SCRIPT = preload("res://scripts/hud.gd")

var ship: RigidBody3D
var earth: Node3D
var camera: Camera3D
var sky_material: ProceduralSkyMaterial
var stars: MultiMeshInstance3D

func _ready() -> void:
	_build_stars()
	_build_earth()
	_build_ship()
	_build_lighting()
	_build_camera()
	var hud: Variant = CanvasLayer.new()
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
	sky_material = ProceduralSkyMaterial.new()
	var sky_mat := sky_material
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
	_build_local_terrain()
	var ground_body := StaticBody3D.new()
	ground_body.name = "EarthGroundCollision"
	var ground_shape := CollisionShape3D.new()
	var ground_sphere := SphereShape3D.new()
	ground_sphere.radius = 6371.0
	ground_shape.shape = ground_sphere
	ground_body.add_child(ground_shape)
	earth.add_child(ground_body)
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


func _terrain_height(x: float, z: float) -> float:
	var distance := Vector2(x, z).length()
	var blend := smoothstep(34.0, 95.0, distance)
	var rolling := sin(x * 0.021) * 2.8 + sin(z * 0.017 + x * 0.008) * 3.6 + sin((x + z) * 0.043) * 1.1
	var hills := maxf(0.0, sin(x * 0.009 + 1.4) * cos(z * 0.011 - 0.7)) * 9.0
	return (rolling + hills) * blend

func _terrain_surface_y(x: float, z: float) -> float:
	return sqrt(maxf(0.0, 6371.0 * 6371.0 - x * x - z * z)) + _terrain_height(x, z)

func _build_local_terrain() -> void:
	var terrain := MeshInstance3D.new()
	terrain.name = "ProceduralHeightmapTerrain"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := 80
	var extent := 720.0
	var step := extent * 2.0 / float(segments)
	for iz in range(segments):
		for ix in range(segments):
			var x0 := -extent + float(ix) * step
			var x1 := x0 + step
			var z0 := -extent + float(iz) * step
			var z1 := z0 + step
			var a := Vector3(x0, _terrain_surface_y(x0, z0), z0)
			var b := Vector3(x1, _terrain_surface_y(x1, z0), z0)
			var cc := Vector3(x0, _terrain_surface_y(x0, z1), z1)
			var d := Vector3(x1, _terrain_surface_y(x1, z1), z1)
			st.set_uv(Vector2(0, 0)); st.add_vertex(a)
			st.set_uv(Vector2(1, 0)); st.add_vertex(b)
			st.set_uv(Vector2(0, 1)); st.add_vertex(cc)
			st.set_uv(Vector2(1, 0)); st.add_vertex(b)
			st.set_uv(Vector2(1, 1)); st.add_vertex(d)
			st.set_uv(Vector2(0, 1)); st.add_vertex(cc)
	st.generate_normals()
	terrain.mesh = st.commit()
	var terrain_mat := StandardMaterial3D.new()
	terrain_mat.albedo_color = Color(0.16, 0.34, 0.12)
	terrain_mat.roughness = 1.0
	terrain.material_override = terrain_mat
	earth.add_child(terrain)
	terrain.create_trimesh_collision()
	_build_vegetation()

func _build_vegetation() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 90421
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.18
	trunk_mesh.bottom_radius = 0.30
	trunk_mesh.height = 2.6
	var leaf_mesh := ConeMesh.new()
	leaf_mesh.bottom_radius = 1.15
	leaf_mesh.height = 3.8
	var grass_mesh := PrismMesh.new()
	grass_mesh.size = Vector3(0.18, 0.55, 0.12)
	var trunk_mm := MultiMesh.new()
	trunk_mm.transform_format = MultiMesh.TRANSFORM_3D
	trunk_mm.mesh = trunk_mesh
	var leaf_mm := MultiMesh.new()
	leaf_mm.transform_format = MultiMesh.TRANSFORM_3D
	leaf_mm.mesh = leaf_mesh
	var grass_mm := MultiMesh.new()
	grass_mm.transform_format = MultiMesh.TRANSFORM_3D
	grass_mm.mesh = grass_mesh
	var trunks: Array[Transform3D] = []
	var leaves: Array[Transform3D] = []
	var grass: Array[Transform3D] = []
	for i in range(105):
		var angle := rng.randf_range(0.0, TAU)
		var radius := rng.randf_range(65.0, 680.0)
		var x := cos(angle) * radius
		var z := sin(angle) * radius
		var y := _terrain_surface_y(x, z)
		var scale := rng.randf_range(0.8, 1.8)
		trunks.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale), Vector3(x, y + 1.3 * scale, z)))
		leaves.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale), Vector3(x, y + 3.95 * scale, z)))
	for i in range(1250):
		var x := rng.randf_range(-700.0, 700.0)
		var z := rng.randf_range(-700.0, 700.0)
		if Vector2(x, z).length() < 38.0:
			continue
		var scale := rng.randf_range(0.7, 1.5)
		grass.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale), Vector3(x, _terrain_surface_y(x, z) + 0.22, z)))
	trunk_mm.instance_count = trunks.size()
	leaf_mm.instance_count = leaves.size()
	grass_mm.instance_count = grass.size()
	for i in range(trunks.size()):
		trunk_mm.set_instance_transform(i, trunks[i])
		leaf_mm.set_instance_transform(i, leaves[i])
	for i in range(grass.size()):
		grass_mm.set_instance_transform(i, grass[i])
	var trunk_node := MultiMeshInstance3D.new()
	trunk_node.multimesh = trunk_mm
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.24, 0.12, 0.055)
	trunk_node.material_override = trunk_mat
	earth.add_child(trunk_node)
	var leaf_node := MultiMeshInstance3D.new()
	leaf_node.multimesh = leaf_mm
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.075, 0.25, 0.075)
	leaf_mat.roughness = 1.0
	leaf_node.material_override = leaf_mat
	earth.add_child(leaf_node)
	var grass_node := MultiMeshInstance3D.new()
	grass_node.multimesh = grass_mm
	var grass_mat := StandardMaterial3D.new()
	grass_mat.albedo_color = Color(0.22, 0.43, 0.12)
	grass_mat.roughness = 1.0
	grass_node.material_override = grass_mat
	earth.add_child(grass_node)

func _update_atmosphere() -> void:
	if not is_instance_valid(ship) or sky_material == null:
		return
	var altitude := ship.altitude_km()
	var fade := clampf(altitude / 95.0, 0.0, 1.0)
	sky_material.sky_top_color = Color(0.10, 0.39, 0.78).lerp(Color(0.001, 0.003, 0.012), fade)
	sky_material.sky_horizon_color = Color(0.48, 0.72, 0.92).lerp(Color(0.002, 0.004, 0.018), fade)
	sky_material.ground_bottom_color = Color(0.20, 0.32, 0.42).lerp(Color(0.001, 0.002, 0.008), fade)
	sky_material.ground_horizon_color = Color(0.48, 0.68, 0.82).lerp(Color(0.002, 0.004, 0.015), fade)
	if is_instance_valid(stars):
		stars.visible = altitude > 55.0

func _build_ship() -> void:
	ship = RigidBody3D.new()
	ship.name = "Spacecraft"
	ship.set_script(SHIP_SCRIPT)
	ship.position = Vector3(0, 6371.8, -7000.0)
	ship.mass = 12000.0
	ship.gravity_scale = 0.0
	ship.linear_damp = 0.0
	ship.angular_damp = 0.0
	add_child(ship)
	var collision := CollisionShape3D.new()
	var collision_box := BoxShape3D.new()
	collision_box.size = Vector3(2.8, 1.5, 8.0)
	collision.shape = collision_box
	ship.add_child(collision)
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
	stars = MultiMeshInstance3D.new()
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
	_update_atmosphere()
