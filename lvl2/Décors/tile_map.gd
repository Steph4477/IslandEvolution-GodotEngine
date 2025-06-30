extends Node2D

#@onready var tilemap := $TileMapLayer
#@onready var player := get_node("/root/GameState/player")  # adapte ce chemin si besoin
#
#func _ready():
	#tilemap.scale = Vector2(1.0 / 3.0, 1.0 / 3.0)
#
	## Repositionner le TileMap sous les pieds du joueur
	#tilemap.global_position = player.global_position
