extends Node

@export var end_of_game_screen : CanvasLayer

@onready var end_of_game_message: Label = $EndOfGameScreen/Control/VBoxContainer/EndOfGameMessage


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Engine.time_scale = 1
	get_tree().paused = false
	Globals.player_died.connect(handle_game_over)
	Globals.victory.connect(handle_victory)
	end_of_game_screen.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func handle_game_over():
	print("Received signal 'player_died'.")
	get_tree().paused = true
	end_of_game_message.text = "You died."
	end_of_game_screen.show()


func handle_victory():
	print("Received signal 'victory'.")
	get_tree().paused = true
	end_of_game_message.text = "You won."
	end_of_game_screen.show()


func _on_replay_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()
