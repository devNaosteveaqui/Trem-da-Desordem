extends Node

@warning_ignore("unused_signal")
signal lista_alterada
@warning_ignore("unused_signal")
signal conexao_resetada(msg)

const IPPADRAO = "127.0.0.1"
const PORTA = 6007
const MAX_JOGADORES = 10

var ip = IPPADRAO
var id = 0
var nome_jogador = ""
var par = null

var jogadores = []

func _ready():
	multiplayer.connected_to_server.connect(self.conectado_ao_servidor)
	multiplayer.connection_failed.connect(self.falha_na_conexao)
	multiplayer.server_disconnected.connect(self.queda_do_servidor)

func criar_servidor():
	par = ENetMultiplayerPeer.new()
	var create_succes = par.create_server(PORTA,MAX_JOGADORES)
	if create_succes == OK:
		var ip_verify = get_ip()
		multiplayer.set_multiplayer_peer(par)
		par.peer_disconnected.connect(self.par_disconectado)
		id = multiplayer.multiplayer_peer.get_unique_id()
		registrar_jogador(id,nome_jogador)
	else:
		resetar_conexao("Falha ao criar o servidor!")

func entrar_servidor():
	par = ENetMultiplayerPeer.new()
	if !ip.is_empty():
		par.create_client(ip,PORTA)
		multiplayer.set_multiplayer_peer(par)
	else:
		resetar_conexao("O ip está vazio!")

func conectado_ao_servidor():
	id = multiplayer.multiplayer_peer.get_unique_id()
	rpc("registrar_jogador",id,nome_jogador)

func falha_na_conexao():
	resetar_conexao("Parece que o servidor não retribuiu seus sentimentos!")

func par_disconectado(par_id):
	rpc("remover_jogador",par_id)

func queda_do_servidor():
	# reload provoca sentimentos estranhos no lado do client!
	#if !get_tree().current_scene.get_node("CanvasLayer/Menu").visible:
		#if Game.RUNNING:
			#get_tree().reload_current_scene()
	resetar_conexao("Parece que o servidor caiu, alguém ajuda ele!")

@rpc("any_peer","call_local")
func resetar_conexao(msg:String):
	par = null
	multiplayer.set_multiplayer_peer(null)
	jogadores.clear()
	emit_signal("conexao_resetada",msg)

@rpc("any_peer")
func registrar_jogador(par_id,nome):
	if multiplayer.is_server():
		for i in range(jogadores.size()):
			rpc_id(par_id,"registrar_jogador",jogadores[i][0],jogadores[i][1])
		rpc("registrar_jogador",par_id,nome)
	jogadores.append([par_id,nome])
	emit_signal("lista_alterada")

@rpc("any_peer","call_local")
func remover_jogador(par_id):
	for i in range(jogadores.size()):
		if jogadores[i][0] == par_id:
			jogadores.remove_at(i)
			emit_signal("lista_alterada")

func interrupt_connection():
	resetar_conexao("Tentativa de conexão cancelada!")

func atualizar_ip(novo_ip):
	ip = novo_ip

func atualizar_nome(novo_nome):
	nome_jogador=novo_nome

func get_lista():
	return jogadores

func get_ip():
	var lista_ip = IP.get_local_addresses()
	for i in range(lista_ip.size()):
		if lista_ip[i].begins_with("192"):
			return lista_ip[i]
	return IPPADRAO

@rpc("any_peer","call_local")
func debugHost(msg:String):
	print(msg)
