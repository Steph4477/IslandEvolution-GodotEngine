extends Node2D

func _on_area_2d_body_entered(body):

	# --- PLAYER ---
	if body.is_in_group("Player"):

		if body.damage_mod.has_method("on_hit") and not body.is_dead:
			body.damage_mod.on_hit(body.max_pv)

		return


	# --- ENEMies ---
	if body.is_in_group("Enemies"):

		if body.has_method("on_hit") and not body.is_dead:
			body.on_hit(999999)
