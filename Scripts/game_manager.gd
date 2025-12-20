extends Node

@onready var game_over_screen: Control = $"../CanvasLayer/GameOverScreen"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().paused = false
	Globals.player_died.connect(game_over)
	game_over_screen.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func game_over():
	print("Received signal 'player_died'.")
	get_tree().paused = true
	game_over_screen.show()


func _on_replay_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()
