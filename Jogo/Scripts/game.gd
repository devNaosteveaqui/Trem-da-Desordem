extends Control

class_name GameNode

@export var tilemap : TileMapLayer
@export var menu_create_name : LineEdit
@export var nextLabel : Label
@export var ranking_view : VBoxContainer
@export var server_ip : LineEdit
@export var lista_jogadores : ItemList
@export var log : RichTextLabel

@export var ranking_score : Array

const enemy_n : int = 5
const blocks_n : int = 10

var player_info : Dictionary

func _ready():
	ranking_score = []
	player_info = {'name' : "",'number' : null}
	if Network.lista_alterada.is_connected(self.lista_alterada):
		Network.lista_alterada.disconnect(self.lista_alterada)
	Network.lista_alterada.connect(self.lista_alterada)
	
	if !Network.conexao_resetada.is_connected(self.conexao_resetada):
		Network.conexao_resetada.connect(self.conexao_resetada)
	generateFloor()
	$MultiplayerSpawner.set_spawn_function(spawn_entity)

func lista_alterada():
	var lista = Network.get_lista()
	lista_jogadores.clear()
	for i in range(lista.size()):
		if lista[i][0] == Network.id:
			lista_jogadores.add_item(lista[i][1] + str("(você)"))
		else:
			lista_jogadores.add_item(lista[i][1])

func log_message(msg:String):
	log.text += msg + "\n"

func initSPGame():
	Game.RUNNING = true
	
	for i in blocks_n:
		tilemap.add_child(spawnBlock(randi()%99,sortBlockPos()))
	
	player_info.number = randi()%99
	tilemap.add_child(spawnPlayer(player_info.name,player_info.number,sortBlockPos()))
	
	for i in enemy_n:
		tilemap.add_child(spawnEnemy(randi()%99,sortBlockPos()))
	
	close_menu()

func initMPGame(block_list:Array,enemys:Array,players:Array):
	log_message("<"+player_info.name+"> initMPGame")
	rpc("start_game_time")
	
	for i in block_list.size():
		var r = $MultiplayerSpawner.spawn([block_list[i].block_n,block_list[i].pos,Game.GROUP_BLOCK])
	
	var jogadores = Network.get_lista()
	for i in range(jogadores.size()):
		var r = $MultiplayerSpawner.spawn([players[i].block_n,players[i].pos,Game.GROUP_PLAYER,jogadores[i][1],jogadores[i][0]])
	
	for i in enemys.size():
		var r = $MultiplayerSpawner.spawn([enemys[i].block_n,enemys[i].pos,Game.GROUP_ENEMY])
	rpc("close_menu")
	#$CanvasLayer/Menu.hide()

func spawn_entity(vars:Array):
	var e_number : int = vars[0]
	var e_pos : Vector2 = vars[1]
	var e_group : String = vars[2]
	log_message("<"+player_info.name+"> spawn_entity")
	if e_group == Game.GROUP_PLAYER:
		return spawnPlayer(vars[3],e_number,e_pos,vars[4])
	elif e_group == Game.GROUP_ENEMY:
		return spawnEnemy(e_number,e_pos)
	elif e_group == Game.GROUP_BLOCK:
		return spawnBlock(e_number,e_pos)
	return null
	
func spawnPlayer(p_name:String,p_number:int,p_pos:Vector2,id:int = -1):
	log_message("<"+player_info.name+"> spawnPlayer")
	var block = load("res://Scenes/entity.tscn").instantiate()
	block.setName(p_name)
	block.setNumber(p_number)
	block.position = p_pos
	block.connect("block_colected",block_picked)
	
	if multiplayer.get_unique_id() == id:
		var cam : Camera2D = load("res://Scenes/PlayerNodes/camera_2d.tscn").instantiate()
		cam.limit_bottom = (Game.MAP_SIZE.y + Game.MAP_POS.y - 1)*64
		cam.limit_top = Game.MAP_POS.y*64
		cam.limit_right = (Game.MAP_SIZE.y + Game.MAP_POS.y - 1)*64
		cam.limit_left = Game.MAP_POS.y*64
		block.add_child(cam)
		block.add_child(load("res://Scenes/PlayerNodes/player_control.tscn").instantiate())
	
	block.setSprite("player.png")
	block.add_to_group(Game.GROUP_PLAYER)
	#tilemap.add_child(block)
	if id != -1:
		block.setAuthoridadeId(id)
		#block.set_multiplayer_authority(id)
	return block

@rpc("any_peer","call_local")
func spawnBlock(number:int,pos:Vector2):
	log_message("<"+player_info.name+"> spawnBlock")
	var block = load("res://Scenes/entity.tscn").instantiate()
	block.position = pos
	block.setNumber(number)
	block.setSprite("block.png")
	block.add_to_group(Game.GROUP_BLOCK)
	#tilemap.add_child(block)
	return block

@rpc("any_peer","call_local")
func spawnEnemy(number:int,pos:Vector2):
	log_message("<"+player_info.name+"> spawnEnemy")
	var block_pos : Vector2 = Vector2(64,64)
	block_pos.x = (randi()%Game.MAP_SIZE.x + Game.MAP_POS.x)*block_pos.x
	block_pos.y = (randi()%Game.MAP_SIZE.y + Game.MAP_POS.y)*block_pos.y
	var block = load("res://Scenes/entity.tscn").instantiate()
	block.position = block_pos
	block.setNumber(number)
	
	block.add_child(load("res://Scenes/NpcNodes/enemyControl.tscn").instantiate())
	block.setSprite("enemy.png")
	block.add_to_group(Game.GROUP_ENEMY)
	#tilemap.add_child(block)
	return block

@rpc("any_peer","call_local")
func start_game_time():
	log_message("<"+player_info.name+"> start_game_time")
	Game.RUNNING = true

func game_time_end():
	rpc("endGame")
	rpc("showRanking",ranking_score)

@rpc("any_peer","call_local")
func endGame():
	log_message("<"+player_info.name+"> endGame")
	Game.RUNNING = false
	reset_Ranking()
	var ns : Array= get_tree().get_nodes_in_group(Game.GROUP_PLAYER)
	for id in ns.size():
		var n = ns[id]
		insert_on_ranking({'id':n.get_multiplayer_authority(),'player':n.getName(),'score':n.countScore()})
		#rpc_id(1,"insert_on_ranking",{'id':n.get_multiplayer_authority(),'player':n.getName(),'score':n.countScore()})

func reset_Ranking():
	log_message("<"+player_info.name+"> reset_Ranking")
	ranking_score.clear()

#@rpc("any_peer","call_local")
func insert_on_ranking(ref):
	log_message("<"+player_info.name+"> insert_on_ranking - ")
	print(ref)
	if ranking_score.size() == 0:
		ranking_score.append(ref)
	elif hasThisId(ref.id,ranking_score):
		var p = findThisId(ref.id,ranking_score)
		if ranking_score[p].score < ref.score:
			ranking_score[p] = ref
	else:
		for p in ranking_score.size():
			if ranking_score[p].score <= ref.score:
				ranking_score.insert(p,ref)
				return
		ranking_score.append(ref)

func findThisId(id,list):
	for p in list.size():
		if id == list[p].id:
			return p
	return null

func hasThisId(id, list):
	for p in list.size():
		if id == list[p].id:
			return true
	return false

@rpc("any_peer","call_local")
func showRanking(ranking):
	log_message("<"+player_info.name+"> showRanking")
	$CanvasLayer/GameResult.show()
	var pos = 1
	for colocacao in ranking_score:
		var label : Label = Label.new()
		label.text = str(pos) + "º"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.text += colocacao.player + " ( " +str(colocacao.score)+" ) "
		label.label_settings = load("res://labelTextGame_f32o4s4.tres")
		ranking_view.add_child(label)
		pos += 1

func selectMPMode():
	if verifyName():
		Game.MODE_SELECTED = Game.MODE.MULTI_PLAYER
		$CanvasLayer/Menu/VBoxContainer.hide()
		$CanvasLayer/Menu/LAN.show()
		clear_message()

func selectSPMode():
	if verifyName():
		Game.MODE_SELECTED = Game.MODE.SINGLE_PLAYER
		clear_message()
		initSPGame()

@rpc("any_peer","call_local")
func spawnNextBlock(nextBlock):
	$MultiplayerSpawner.spawn([nextBlock,sortBlockPos(),Game.GROUP_BLOCK])
	#rpc("spawnBlock",nextBlock,sortBlockPos())
	updateLabel(nextBlock)

func updateLabel(newNumber):
	nextLabel.text = str(newNumber)

func block_picked(player_auth,next_block):
	rpc_id(player_auth,"spawnNextBlock",next_block)

#Multiplayer

func _on_host_pressed():
	disableButton()
	clear_message()
	Network.atualizar_nome(player_info.name)
	Network.criar_servidor()
	$CanvasLayer/Menu/LAN/VBoxContainer/IPConnected.text = Network.get_ip()

func _on_connect_pressed():
	disableButton(true)
	clear_message()
	Network.atualizar_ip(server_ip.text.dedent())
	Network.atualizar_nome(player_info.name)
	Network.entrar_servidor()

func _on_desconectar_pressed():
	ableButton()
	$CanvasLayer/Menu/LAN/VBoxContainer/IPConnected.text = ""
	Network.interrupt_connection()

func _on_retur_menu_pressed() -> void:
	if multiplayer.is_server():
		#rpc("resetar_jogo")
		Network.rpc("resetar_conexao","")
	else:
		#resetar_jogo()
		Network.resetar_conexao("")

func _on_iniciar_pressed():
	#var peers = Network.get_lista()
	var blocks = generate_blocks(blocks_n)
	var enemys = generate_enemys(enemy_n)
	var players = generate_players_location(Network.get_lista().size())
	#print(players)
	rpc("clear_message")
	initMPGame(blocks,enemys,players)
	#rpc("comecar_jogo",blocks,enemys,players)
	#for id in peers.size():
		#rpc_id(peers[id][0],"comecar_jogo",peers[id][0],blocks,enemys,players)
	#rpc_id(1,"comecar_jogo",blocks,enemys,players)

#@rpc("any_peer","call_local")
#func comecar_jogo(block_list:Array,enemys:Array,players:Array):
	#print("recebi")
	#clear_message()
	#initMPGame(block_list,enemys,players)

func generate_players_location(qtd:int):
	var list = []
	for i in qtd:
		list.append({'block_n':randi()%99,'pos':sortBlockPos()})
	return list

func generate_enemys(qtd:int):
	var list = []
	for i in qtd:
		list.append({'block_n':randi()%99,'pos':sortBlockPos()})
	return list

func generate_blocks(qtd:int):
	var list = []
	for i in qtd:
		list.append({'block_n':randi()%99,'pos':sortBlockPos()})
	return list

@rpc("any_peer","call_local")
func close_menu():
	$CanvasLayer/Menu.hide()

func disableButton(as_client:bool = false):
	$CanvasLayer/Menu/LAN/VBoxContainer/Connect.disabled = true
	$CanvasLayer/Menu/LAN/VBoxContainer/Host.disabled = true
	if as_client:
		$CanvasLayer/Menu/LAN/VBoxContainer/Iniciar.disabled = true

func ableButton():
	$CanvasLayer/Menu/LAN/VBoxContainer/Connect.disabled = false
	$CanvasLayer/Menu/LAN/VBoxContainer/Host.disabled = false
	$CanvasLayer/Menu/LAN/VBoxContainer/Iniciar.disabled = false

func conexao_resetada(msg):
	resetar_jogo()
	lista_alterada()
	if !$CanvasLayer/Menu.visible:
		$CanvasLayer/GameResult.hide()
		$CanvasLayer/Menu.show()
	if Game.MODE_SELECTED == Game.MODE.MULTI_PLAYER:
		$CanvasLayer/Menu/VBoxContainer.hide()
		$CanvasLayer/Menu/LAN.show()
	else:
		$CanvasLayer/Menu/VBoxContainer.show()
		$CanvasLayer/Menu/LAN.hide()

func _on_lan_visibility_changed():
	if $CanvasLayer/Menu/LAN.visible:
		$CanvasLayer/Menu/LAN/VBoxContainer/IPConnected.text = ""
		clear_message()
		ableButton()

@rpc("any_peer","call_local")
func clear_message():
	$CanvasLayer/Menu/LAN/VBoxContainer/Message.text = ""
	$CanvasLayer/Menu/VBoxContainer/Message.text = ""

@rpc("any_peer","call_local")
func resetar_jogo():
	if Game.RUNNING:
		Game.RUNNING = false
	for c in ranking_view.get_children():
		c.queue_free()
	$CanvasLayer/UI/GameTimer.reset_time()
	for n in tilemap.get_children():
		n.queue_free()
	ableButton()

func verifyName():
	menu_create_name.text = menu_create_name.text.dedent()
	if menu_create_name.text.length() <= 32 and menu_create_name.text.length()>0:
		player_info.name = menu_create_name.text
		return true
	$CanvasLayer/Menu/VBoxContainer/Message.text = "Nome não pode estar em branco!"
	return false

func sortBlockPos():
	var block_pos : Vector2 = Vector2(64,64)
	block_pos.x = (randi()%Game.MAP_SIZE.x + Game.MAP_POS.x)*block_pos.x
	block_pos.y = (randi()%Game.MAP_SIZE.y + Game.MAP_POS.y)*block_pos.y
	return block_pos

func generateFloor():
	for i in Game.MAP_SIZE.x+2:
		for j in Game.MAP_SIZE.y+2:
			var tile_pos = Vector2i(i + Game.MAP_POS.x-1, j + Game.MAP_POS.y-1)
			if (i > 0 and i < Game.MAP_SIZE.x) and (j > 0 and j < Game.MAP_SIZE.y):
				#tilemap.set_cell(0,tile_pos,0,Vector2i(0,0),0)
				tilemap.set_cell(tile_pos,0,Vector2i(0,0),0)
			else:
				#tilemap.set_cell(0,tile_pos,1,Vector2i(0,0),0)
				tilemap.set_cell(tile_pos,1,Vector2i(0,0),0)
