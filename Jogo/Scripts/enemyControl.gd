extends Node2D

@onready var body : Entity = get_parent()

var target : NodePath
var next_pos : Vector2
var next_dir : Vector2
var origin_pos : Vector2
var last_pos : Vector2
var count = 100
var walk_capacity = randf_range(300,(Game.MAP_SIZE.x*64 if Game.MAP_SIZE.x < Game.MAP_SIZE.y else Game.MAP_SIZE.y))

func _process(delta):
	if body.tailQueue == target:
		target = scan_for_target()
	if body.isTailQueueNull():
		if !isTargetNull():
			if get_node(target).position.distance_to(body.position)/2 < body.target_dist:
				body.pickBlock()
	else:
		if !isTargetNull():
			setTarget(NodePath(""))
		if count > 0:
			count -= 1
		else:
			count = 100
			body.releaseBlock()

func _physics_process(delta):
	if isTargetNull():
		if next_dir == Vector2(0,0):
			next_pos = body.position
		if next_pos.distance_to(body.position) > 64:
			# Segue o caminho
			next_dir = body.position.direction_to(next_pos)
		else:
			next_dir = sortNewDirection()
	else:
		# Persegue o alvo
		next_dir = body.position.direction_to(get_node(target).position)
	
	body.move(next_dir)
	last_pos = body.position

func sortNewDirection(change_orientation:bool = false):
	origin_pos = body.position
	var newdir : Vector2 = Vector2(0,0)
	if change_orientation:
		newdir = body.position.direction_to(next_pos)*(-1)
	else:
		newdir = Vector2(randf_range(-1,1),randf_range(-1,1))
		next_pos = calculate_next_pos(newdir)
		if Game.isOutOfLimit(next_pos):
			newdir = Game.getDirFree(body.position,body.position.distance_to(next_pos),newdir)
			next_pos = calculate_next_pos(newdir)
	return newdir

func setTarget(newTarget:NodePath):
	target = newTarget

func isTargetNull():
	return target == NodePath("")

func calculate_next_pos(dir:Vector2):
	return dir*walk_capacity + body.position

func _on_area_2d_body_entered(bodyFind):
	if bodyFind is CharacterBody2D:
		if isTargetNull() and body.isTailQueueNull():
			if bodyFind.is_in_group(Game.GROUP_BLOCK) and (!bodyFind.isHeadQueueNull):
				if get_node(bodyFind.headQueue).is_in_group(Game.GROUP_PLAYER):
					setTarget(bodyFind.get_path())

func _on_area_2d_body_exited(bodyFind):
	if bodyFind is CharacterBody2D:
		if bodyFind.get_path() == target and body.isTailQueueNull():
			target = scan_for_target()

func scan_for_target():
	var bodys : Array = $Area2D.get_overlapping_bodies()
	for id in bodys.size():
		if bodys[id] is Entity:
			if bodys.size() > 0 and bodys[id].is_in_group(Game.GROUP_BLOCK) and (!bodys[id].isTailQueueNull()) :
				if get_node(bodys[id].headQueue).is_in_group(Game.GROUP_PLAYER):
					return bodys[0].get_path()
	return NodePath("")
