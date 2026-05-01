extends Area2D

var dps = 20.0
var tick_timer = 0.0
var target_enemy: Node2D = null 

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

func _ready():
	# Duplikat bentuk collision biar gak nge-bug numpuk
	collision.shape = collision.shape.duplicate()
	
	# BIKIN LASER LEBIH TEBEL (Sekarang pakai X karena udah diputar)
	sprite.scale.x = 2.0 # Ganti angka ini kalo pengen lebih tebel/tipis
	
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _process(delta):
	if is_instance_valid(target_enemy):
		# 1. Kunci bidikan ke arah musuh
		look_at(target_enemy.global_position)
		
		# 2. Ngukur Jarak Akurat
		var jarak = global_position.distance_to(target_enemy.global_position)
		
		# 3. MELARIN GAMBAR PANJANGNYA (Sekarang pakai Y!)
		var panjang_asli = sprite.region_rect.size.y
		sprite.scale.y = jarak / panjang_asli
		
		# 4. DORONG KE DEPAN BIAR KELUAR DARI KAPAL PLAYER
		sprite.position.x = jarak / 2.0 
		sprite.position.y = 0
		
		# 5. PAKSA HITBOX COLLISION BIAR PAS SAMA LASER
		collision.rotation = 0 # Gak usah diputar, murni manjang ke kanan
		collision.shape.size = Vector2(jarak, 50) # Angka 50 ini ketebalan area damage
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
