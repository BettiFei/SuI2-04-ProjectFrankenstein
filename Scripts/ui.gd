extends CanvasLayer


@onready var coins_total: Label = $Control/HBoxContainer/VBoxContainer2/CoinsTotal
@onready var coins_collected: Label = $Control/HBoxContainer/VBoxContainer2/CoinsCollected


var total := 20
var collected := 0


func _ready() -> void:
	Globals.connect("coin_collected", add_coin)
	total = get_tree().get_nodes_in_group("coin").size()
	collected = 16
	coins_total.text = str(total)
	coins_collected.text = str(collected)


func add_coin():
	collected += 1
	coins_collected.text = str(collected)
	if collected == total:
		Globals.victory.emit()
