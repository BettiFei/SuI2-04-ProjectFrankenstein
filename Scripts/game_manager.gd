extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Globals.player_died.connect(game_over)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func game_over():
	print("Received signal 'player_died'.")
