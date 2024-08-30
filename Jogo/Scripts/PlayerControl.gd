extends Node2D

@onready var body : CharacterBody2D = get_parent()

func _ready():
	if body.is_multiplayer_authority():
		body.sorteNextBlock()

func _process(delta):
	#if body.is_local_authoraty(multiplayer.get_unique_id()):
	if body.is_multiplayer_authority():
		body.get_node("Camera2D").make_current()
		if Input.is_action_just_pressed("pickBlock"):
			#body.rpc("pickBlock")
			body.pickBlock()

func _physics_process(delta):
	#if body.is_local_authoraty(multiplayer.get_unique_id()):
	if body.is_multiplayer_authority():
		body.move(Vector2(Input.get_axis("ui_left","ui_right"),Input.get_axis("ui_up","ui_down")))
		#body.rpc("move",Vector2(Input.get_axis("ui_left","ui_right"),Input.get_axis("ui_up","ui_down")))
