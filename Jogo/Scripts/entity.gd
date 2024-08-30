extends CharacterBody2D

class_name Entity

signal block_colected(auth,nextblock)
signal block_stolen(msg,block_path)
signal next_block_to_player(auth)
signal update_label(auth,newNumber)

@export var faceRay : RayCast2D
@export var sequence_blocks : Array = []
@export var nextBlock : int
@export var numberV : int

@export var target_pos : Vector2
@export var headQueue : NodePath
@export var tailQueue : NodePath

var authoridade_id

const speed : int = 300
const target_dist = 50

var message_cooldown : int = 100
var flag_message : bool = false

func _enter_tree() -> void:
	if authoridade_id != null:
		set_multiplayer_authority(authoridade_id)

func _process(delta):
	if flag_message:
		message_cooldown-=1
		if message_cooldown < 1:
			flag_message = false
			printTalkMessage("")
	if Game.RUNNING:
		if (!isHeadQueueNull()) and is_in_group(Game.GROUP_BLOCK):
			var hQ : Entity = get_node(headQueue)
			faceRay.target_position = position.direction_to(hQ.position + hQ.faceRay.target_position*(-1))*target_dist
			var next_pos : Vector2 = hQ.position + hQ.faceRay.target_position*(-1)
			if position.distance_to(next_pos) > target_dist:
				velocity = lerp(position.direction_to(next_pos)*speed, hQ.velocity, 0.1)
		elif isHeadQueueNull() and is_in_group(Game.GROUP_BLOCK):
			velocity = Vector2(0,0)
		move_and_slide()

func setAuthoridadeId(newID):
	authoridade_id = newID

func setName(named:String):
	$Nickname.text = named

func setNumber(number:int):
	numberV = number
	$Number.text = str(number)

func setSprite(path):
	$Sprite2D.texture = load("res://"+path)

@rpc("any_peer", "call_local")
func setTailQueue(newTail:NodePath):
	tailQueue = newTail

@rpc("any_peer", "call_local")
func setHeadQueue(newHead:NodePath):
	if !get_node(newHead).is_in_group(Game.GROUP_ENEMY):
		print(newHead)
	headQueue = newHead

func move(new_vel:Vector2):
	if not new_vel.is_equal_approx(Vector2.ZERO):
		faceRay.target_position = new_vel*target_dist
	self.velocity = new_vel*speed

@rpc("any_peer", "call_local")
func setNextBlock(nextNumber:int):
	self.nextBlock = nextNumber

func sorteNextBlock():
	#if is_local_authoraty(multiplayer.get_unique_id()):
	if is_multiplayer_authority():
		nextBlock = randi()%99
		sequence_blocks.append(nextBlock)
		emit_signal("block_colected",multiplayer.get_unique_id(),nextBlock)

func releaseBlock():
	get_node(self.tailQueue).setHeadQueue(NodePath(""))
	self.setTailQueue(NodePath(""))

func pickBlock():
	var colliders = faceRay.get_collider()
	if colliders != null:
		if colliders.is_in_group(Game.GROUP_BLOCK) and not has_this_block(colliders):
			if !colliders.isHeadQueueNull():
				colliders.stealingBlock()
				#colliders.rpc("stealingBlock")
				rpc("printTalkMessage","Perdeu playboy!")
			addToQueue(colliders.get_path())
			#rpc("addToQueue",colliders.get_path())
			sorteNextBlock()

func isHeadQueueNull():
	return headQueue == NodePath("")

func isTailQueueNull():
	return tailQueue == NodePath("")

func has_this_block(block:Entity):
	if !isTailQueueNull():
		if get_node(tailQueue) == block:
			return true
		else:
			return get_node(tailQueue).has_this_block(block)
	else:
		return false

#@rpc("any_peer","call_local")
func addToQueue(block_path:NodePath):
	if !isTailQueueNull():
		get_node(tailQueue).addToQueue(block_path)
	else:
		#setTailQueue(block_path)
		rpc("setTailQueue",block_path)
		var block : Entity = get_node(block_path)
		block.rpc("setHeadQueue",self.get_path())
		#block.setHeadQueue(self.get_path())
		block.block_stolen.connect(block_stolen_alert)
		var pos_behind : Vector2 = position + (faceRay.target_position)*(-1)
		block.faceRay.target_position = block.position.direction_to(pos_behind)*target_dist#self.position.direction_to(block.position)*50
		block.position = pos_behind

@rpc("any_peer","call_local")
func stealingBlock():
	emit_signal("block_stolen","Oh lazarento, volta com meu bloco!",self.get_path())
	if !isTailQueueNull():
		#get_node(tailQueue).setHeadQueue(headQueue)
		get_node(tailQueue).rpc("setHeadQueue",headQueue)
		get_node(headQueue).rpc("setTailQueue",tailQueue)
	else:
		get_node(headQueue).rpc("setTailQueue",NodePath(""))
	setTailQueue("")

func block_stolen_alert(msg,block_path):
	get_node(block_path).disconnect("block_stolen",block_stolen_alert)
	printTalkMessage(msg)

@rpc("any_peer","call_local")
func printTalkMessage(msg):
	if msg != "":
		flag_message = true
	$TalkMessagess.text = msg

func getName():
	return $Nickname.text

func getNumber():
	return numberV

func getNumberList(oldlist):
	oldlist.append(getNumber())
	if !isTailQueueNull():
		return get_node(tailQueue).getNumberList(oldlist)
	return oldlist

func countScore():
	if isTailQueueNull():
		return 0
	var list : Array = get_node(tailQueue).getNumberList([])
	var score = 0
	var id_offset = 0
	
	print($Nickname.text,list)
	print($Nickname.text,sequence_blocks)
	
	for id in list.size():
		var value = list[id]
		var finded = sequence_blocks.find(list[id],id_offset)
		if finded > -1:
			score = score + 1
			sequence_blocks.remove_at(finded)
		
		if finded == id:
			score = score + 1
			id_offset = finded + 1
	return score

func is_local_authoraty(peer_id):
	return get_multiplayer_authority() == peer_id
