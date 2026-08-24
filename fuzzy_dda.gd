extends RefCounted

# ============================================
# FUZZY LOGIC MAMDANI - Dynamic Difficulty Adjustment
# ============================================
# Metode Mamdani dengan 27 rules (kombinasi lengkap 3 input x 3 himpunan = 3^3)
# Fuzzification → Inferensi (MIN-MAX) → Defuzzification (Centroid)
#
# Input: health_ratio, kill_rate, damage_rate
# Output: difficulty_multiplier (0.5 – 1.5)

# ============================================
# INPUT MEMBERSHIP FUNCTIONS (Triangular/Trapezoidal)
# ============================================

# --- Health Ratio (0.0 – 1.0) ---
func _health_low(x: float) -> float:
	return _trapezoid(x, 0.0, 0.0, 0.2, 0.4)

func _health_medium(x: float) -> float:
	return _triangle(x, 0.25, 0.5, 0.75)

func _health_high(x: float) -> float:
	return _trapezoid(x, 0.6, 0.8, 999.0, 999.0)

# --- Kill Rate (kills per 30 detik, 0 – 20+) ---
func _kill_low(x: float) -> float:
	return _trapezoid(x, 0.0, 0.0, 2.0, 5.0)

func _kill_medium(x: float) -> float:
	return _triangle(x, 3.0, 7.0, 13.0)  # extend ke 13 untuk overlap dengan kill_high

func _kill_high(x: float) -> float:
	return _trapezoid(x, 11.0, 17.0, 999.0, 999.0)  # overlap dengan medium untuk hilangkan dead zone

# --- Damage Rate (damage per 30 detik, 0 – 100+) ---
func _damage_low(x: float) -> float:
	return _trapezoid(x, 0.0, 0.0, 10.0, 30.0)

func _damage_medium(x: float) -> float:
	return _triangle(x, 15.0, 40.0, 65.0)

func _damage_high(x: float) -> float:
	return _trapezoid(x, 60.0, 90.0, 999.0, 999.0)  # naik dari 50/70

# ============================================
# OUTPUT MEMBERSHIP FUNCTIONS (Difficulty: 0.5 – 1.5)
# ============================================
func _diff_very_easy(x: float) -> float:
	return _triangle(x, 0.5, 0.5, 0.75)

func _diff_easy(x: float) -> float:
	return _triangle(x, 0.55, 0.75, 0.95)

func _diff_normal(x: float) -> float:
	return _triangle(x, 0.8, 1.0, 1.2)

func _diff_hard(x: float) -> float:
	return _triangle(x, 1.05, 1.25, 1.45)

func _diff_very_hard(x: float) -> float:
	return _triangle(x, 1.25, 1.5, 1.5)

# ============================================
# SHAPE FUNCTIONS
# ============================================
func _triangle(x: float, a: float, b: float, c: float) -> float:
	if x < a or x > c:
		return 0.0
	elif x <= b:
		if b == a:
			return 1.0
		return (x - a) / (b - a)
	else:
		if c == b:
			return 1.0
		return (c - x) / (c - b)

func _trapezoid(x: float, a: float, b: float, c: float, d: float) -> float:
	if x < a or x > d:
		return 0.0
	elif x >= b and x <= c:
		return 1.0
	elif x < b:
		if b == a:
			return 1.0
		return (x - a) / (b - a)
	else:
		if d == c:
			return 1.0
		return (d - x) / (d - c)

# ============================================
# MAMDANI INFERENCE + CENTROID DEFUZZIFICATION
# ============================================
func evaluate(health_ratio: float, kill_rate: float, damage_rate: float) -> float:
	# Clamp inputs
	health_ratio = clampf(health_ratio, 0.0, 1.0)
	kill_rate = maxf(kill_rate, 0.0)
	damage_rate = maxf(damage_rate, 0.0)
	
	# --- FUZZIFICATION ---
	var h_low = _health_low(health_ratio)
	var h_med = _health_medium(health_ratio)
	var h_high = _health_high(health_ratio)
	
	var k_low = _kill_low(kill_rate)
	var k_med = _kill_medium(kill_rate)
	var k_high = _kill_high(kill_rate)
	
	var d_low = _damage_low(damage_rate)
	var d_med = _damage_medium(damage_rate)
	var d_high = _damage_high(damage_rate)
	
	# --- 27 FUZZY RULES (Mamdani) ---
	# Format: [firing_strength, output_function_name]
	# Operator AND = MIN, Operator OR = MAX (untuk aggregation)
	# Urutan rule R1-R27 sesuai tabel Basis Aturan pada GDD (3 input x 3 himpunan = 27)
	
	var rules: Array = []
	
	# === HEALTH = LOW ===
	# R1: IF health=low AND kill=low AND damage=high → very_easy
	rules.append([minf(h_low, minf(k_low, d_high)), "very_easy"])
	# R2: IF health=low AND kill=low AND damage=medium → very_easy
	rules.append([minf(h_low, minf(k_low, d_med)), "very_easy"])
	# R3: IF health=low AND kill=low AND damage=low → easy
	rules.append([minf(h_low, minf(k_low, d_low)), "easy"])
	# R4: IF health=low AND kill=medium AND damage=high → very_easy
	rules.append([minf(h_low, minf(k_med, d_high)), "very_easy"])
	# R5: IF health=low AND kill=medium AND damage=medium → easy
	rules.append([minf(h_low, minf(k_med, d_med)), "easy"])
	# R6: IF health=low AND kill=medium AND damage=low → normal
	rules.append([minf(h_low, minf(k_med, d_low)), "normal"])
	# R7: IF health=low AND kill=high AND damage=high → easy
	rules.append([minf(h_low, minf(k_high, d_high)), "easy"])
	# R8: IF health=low AND kill=high AND damage=medium → normal
	rules.append([minf(h_low, minf(k_high, d_med)), "normal"])
	# R9: IF health=low AND kill=high AND damage=low → hard
	rules.append([minf(h_low, minf(k_high, d_low)), "hard"])
	
	# === HEALTH = MEDIUM ===
	# R10: IF health=medium AND kill=low AND damage=high → easy
	rules.append([minf(h_med, minf(k_low, d_high)), "easy"])
	# R11: IF health=medium AND kill=low AND damage=medium → easy
	rules.append([minf(h_med, minf(k_low, d_med)), "easy"])
	# R12: IF health=medium AND kill=low AND damage=low → normal
	rules.append([minf(h_med, minf(k_low, d_low)), "normal"])
	# R13: IF health=medium AND kill=medium AND damage=high → easy
	rules.append([minf(h_med, minf(k_med, d_high)), "easy"])
	# R14: IF health=medium AND kill=medium AND damage=medium → normal
	rules.append([minf(h_med, minf(k_med, d_med)), "normal"])
	# R15: IF health=medium AND kill=medium AND damage=low → hard
	rules.append([minf(h_med, minf(k_med, d_low)), "hard"])
	# R16: IF health=medium AND kill=high AND damage=high → normal
	rules.append([minf(h_med, minf(k_high, d_high)), "normal"])
	# R17: IF health=medium AND kill=high AND damage=medium → hard
	rules.append([minf(h_med, minf(k_high, d_med)), "hard"])
	# R18: IF health=medium AND kill=high AND damage=low → very_hard
	rules.append([minf(h_med, minf(k_high, d_low)), "very_hard"])
	
	# === HEALTH = HIGH ===
	# R19: IF health=high AND kill=low AND damage=high → normal
	rules.append([minf(h_high, minf(k_low, d_high)), "normal"])
	# R20: IF health=high AND kill=low AND damage=medium → normal
	rules.append([minf(h_high, minf(k_low, d_med)), "normal"])
	# R21: IF health=high AND kill=low AND damage=low → hard
	rules.append([minf(h_high, minf(k_low, d_low)), "hard"])
	# R22: IF health=high AND kill=medium AND damage=high → normal
	rules.append([minf(h_high, minf(k_med, d_high)), "normal"])
	# R23: IF health=high AND kill=medium AND damage=medium → normal
	rules.append([minf(h_high, minf(k_med, d_med)), "normal"])
	# R24: IF health=high AND kill=medium AND damage=low → hard
	rules.append([minf(h_high, minf(k_med, d_low)), "hard"])
	# R25: IF health=high AND kill=high AND damage=high → normal
	rules.append([minf(h_high, minf(k_high, d_high)), "normal"])
	# R26: IF health=high AND kill=high AND damage=medium → hard
	rules.append([minf(h_high, minf(k_high, d_med)), "hard"])
	# R27: IF health=high AND kill=high AND damage=low → very_hard
	rules.append([minf(h_high, minf(k_high, d_low)), "very_hard"])
	
	# --- AGGREGATION & CENTROID DEFUZZIFICATION ---
	return _centroid_defuzzify(rules)

func _centroid_defuzzify(rules: Array) -> float:
	# Centroid method: sample output universe, aggregate, find center of area
	const SAMPLES = 100
	const OUT_MIN = 0.5
	const OUT_MAX = 1.5
	var step = (OUT_MAX - OUT_MIN) / float(SAMPLES)
	
	var numerator: float = 0.0
	var denominator: float = 0.0
	
	for i in range(SAMPLES + 1):
		var x = OUT_MIN + i * step
		
		# Evaluate aggregated membership at this point (MAX aggregation)
		var aggregated: float = 0.0
		
		for rule in rules:
			var strength: float = rule[0]
			if strength <= 0.0:
				continue
			
			var output_name: String = rule[1]
			var membership: float = 0.0
			
			# Evaluate output membership function
			match output_name:
				"very_easy":
					membership = _diff_very_easy(x)
				"easy":
					membership = _diff_easy(x)
				"normal":
					membership = _diff_normal(x)
				"hard":
					membership = _diff_hard(x)
				"very_hard":
					membership = _diff_very_hard(x)
			
			# Clipping (Mamdani): MIN of rule strength and membership
			var clipped = minf(strength, membership)
			
			# Aggregation: MAX
			aggregated = maxf(aggregated, clipped)
		
		numerator += x * aggregated
		denominator += aggregated
	
	if denominator <= 0.0:
		return 1.0  # Default: normal difficulty
	
	return clampf(numerator / denominator, 0.5, 1.5)
