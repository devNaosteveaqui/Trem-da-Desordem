extends Node2D

func _physics_process(delta):
	for i in get_child_count():
		var prev_block_pos
		if i == 0:
			prev_block_pos = get_parent().position
		else:
			prev_block_pos = get_child(i-1).position
		get_child(i).position = lerp(get_child(i).position, prev_block_pos, 0.1)


func adicionaNaFila(bloco):
	add_child(bloco)
	var nextB
	if get_child_count() > 1:
		nextB = get_child(get_child_count()-2)
	else:
		nextB = get_parent()
	var nextBFace = nextB.faceRay.target_position*(-1)
	bloco.position = nextB.position + position.direction_to(nextB.position)*(-64)
