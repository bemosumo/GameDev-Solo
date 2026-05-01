extends CharacterBody2D

signal defeated

# INI PENTING: Nanti muncul kolom "Bullet Scene" di Inspector Boss
# Lu HARUS tarik file BossBullet.tscn (peluru baru lu) ke kolom itu!
@export var bullet_scene: PackedScene
@export var tentacle_scene: PackedScene # BUAT PELURU TENTAKEL

# Variabel buat ngatur sudut ayunan
var sudut_tentakel: float = 0.0
var hp: float = 500.0 # Darah Bos

@onready var health_bar = $CanvasLayer/HealthBar

func _ready():
	add_to_group("enemy")
	health_bar.max_value = hp
	health_bar.value = hp
	
	# TIMER KHUSUS TENTAKEL (Ngebut banget biar rapet)
	var timer_tentakel = Timer.new()
	timer_tentakel.wait_time = 0.06 # Keluarin peluru tiap 0.06 detik
	timer_tentakel.autostart = true
	timer_tentakel.timeout.connect(keluarin_tentakel)
	add_child(timer_tentakel)

func take_damage(amount: float):
	hp -= amount
	# Update visual bar
	health_bar.value = hp
	
	print(name, " kena hit! Sisa HP: ", hp)
	
	if hp <= 0:
		defeated.emit()
		queue_free()

# ==========================================================
# FUNGSI TEMBAK BULLET HELL (Pola Lingkaran Penuh 360 Derajat)
# Dipanggil otomatis sama node Timer di Boss lu
# ==========================================================
func _on_timer_timeout():
	# Jaga-jaga kalau lu lupa masukin scene peluru di Inspector
	if bullet_scene == null:
		print("LAPOR KOMANDAN! Kolom 'Bullet Scene' di Inspector Boss belum diisi!")
		return
		
	var jumlah_peluru = 64 # Silakan diganti! Makin gede angkanya, makin rapet pelurunya
	var radius = PI * 2.0 / jumlah_peluru # Hitungan matematika buat 360 derajat
	
	for i in range(jumlah_peluru):
		var b = bullet_scene.instantiate()
		
		# Masukin pelurunya ke arena pertempuran
		get_parent().add_child(b)
		
		# Posisi awal peluru persis di tengah badan boss
		b.global_position = self.global_position
		
		# Hitung sudut buat peluru ke-i
		var angle = i * radius
		var final_direction = Vector2(cos(angle), sin(angle)).normalized()
		
		# Arahkan pelurunya (Pastiin script BossBullet lu punya variabel 'direction')
		b.direction = final_direction
		
		# Puter gambar pelurunya biar moncongnya ngadep ke depan (keluar)
		b.rotation = final_direction.angle()

# ===============================================
# FUNGSI TENTAKEL AYUN (Curved Whip)
# ===============================================
func keluarin_tentakel():
	if tentacle_scene == null: return
	
	var jumlah_lengan = 4 # Ada 4 tentakel yang muter barengan
	var jarak_sudut = (PI * 2.0) / jumlah_lengan
	
	# BIKIN MONCONGNYA NGAYUN BOLAK-BALIK
	# Time.get_ticks_msec() bikin waktunya jalan terus. 
	# sin() bikin nilainya ngayun dari -1 ke 1.
	var waktu = Time.get_ticks_msec() / 1000.0
	
	# Angka 1.5 = kecepatan ngayun. Angka PI = selebar apa dia nyapu.
	sudut_tentakel = sin(waktu * 1.5) * PI 
	
	for i in range(jumlah_lengan):
		var b = tentacle_scene.instantiate()
		get_parent().add_child(b)
		
		# Keluar dari tengah badan boss
		b.global_position = self.global_position
		
		# Tembakin sesuai sudut yang lagi ngayun
		var angle = sudut_tentakel + (i * jarak_sudut)
		var final_direction = Vector2(cos(angle), sin(angle)).normalized()
		
		b.direction = final_direction
		b.rotation = final_direction.angle()
