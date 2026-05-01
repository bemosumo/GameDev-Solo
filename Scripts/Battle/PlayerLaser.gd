extends Area2D

var dps = 20.0
var tick_timer = 0.0
var target_enemy: Node2D = null 

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

func _ready():
	# Duplikat bentuk collision biar gak nge-bug
	collision.shape = collision.shape.duplicate()
	
	# 1. PAKSA POSISI TENGAH BIAR PRESISI
	sprite.position = Vector2(0, 0)
	collision.position = Vector2(0, 0)
	
	# 2. PAKSA LASER TIDURAN (Nghadap Kanan) DARI SCRIPT
	sprite.rotation_degrees = 90 
	
	# 3. KETEBALAN LASER
	sprite.scale.x = 2.5 
	
	# 4. TAMPILKAN DI PALING ATAS (Gak bakal ketimpa laut)
	z_index = 10 
	
	# Hancur setelah 3 detik
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _process(delta):
	if is_instance_valid(target_enemy):
		# Kunci bidikan ke arah musuh
		look_at(target_enemy.global_position)
		var jarak = global_position.distance_to(target_enemy.global_position)
		
		# Pake get_rect() lebih aman dari region_rect (Anti Lenyap)
		var panjang_asli = sprite.get_rect().size.y
		
		# Cegah error bagi 0
		if panjang_asli > 0:
			sprite.scale.y = jarak / panjang_asli
		
		# Dorong laser ke depan moncong kapal
		sprite.position.x = jarak / 2.0 
		sprite.position.y = 0
		
		# Atur Hitbox Collision biar lurus ngikutin gambar
		collision.rotation_degrees = 0 
		collision.shape.size = Vector2(jarak, 50) # Angka 50 = tebel area damage
		collision.position.x = jarak / 2.0
		collision.position.y = 0

	# --- SISTEM DAMAGE TICK ---
	tick_timer += delta
	if tick_timer >= 1.0:
		tick_timer = 0.0
		var musuh_kena = get_overlapping_bodies()
		for musuh in musuh_kena:
			if musuh.is_in_group("enemy") and musuh.has_method("take_damage"):
				musuh.take_damage(dps)
