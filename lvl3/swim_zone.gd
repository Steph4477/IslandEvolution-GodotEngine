extends Node2D

func _on_area_2d_body_entered(body):
	print("[SwimZone] body_entered:", body.name)
	if body.is_in_group("Player"):
		print("[SwimZone] → Player détecté, passage en mode nage")
		body.is_swimming = true
	else:
		print("[SwimZone] → Ce n'est pas le Player")

func _on_area_2d_body_exited(body):
	print("[SwimZone] body_exited:", body.name)
	if body.is_in_group("Player"):
		print("[SwimZone] → Player sorti, retour normal")
		body.is_swimming = false
	else:
		print("[SwimZone] → Ce n'est pas le Player")
