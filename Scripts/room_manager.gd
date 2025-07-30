extends Node

@export var player: Node2D  # Referência ao Player
@export var camera: Camera2D  # Referência à câmera

var sala_atual: Node2D = null  # Sala onde o Player está
var salas: Dictionary = {}  # Armazena todas as salas

func _ready():
	var world = get_parent().get_node("World")  # Pega o nó "World"
	
	if world == null:
		print("⚠️ ERRO: Nó 'World' não encontrado!")
		return
	
	# Guarda todas as salas dentro de "World"
	for child in world.get_children():
		if child.name.begins_with("Sala_"):
			salas[child.name] = child
			child.visible = false  # Esconde todas as salas no início
			if child != salas.get("Sala_1"):  # Não desativa colisões para a sala inicial
				desabilitar_colisoes(child)  # Desabilita as colisões de todas as outras salas

	# Define a sala inicial e corrige a referência de sala_atual
	definir_sala_inicial()

func definir_sala_inicial():
	if salas.size() == 0:
		print("⚠️ Nenhuma sala encontrada dentro de 'World'!")
		return  # Sai da função se não houver salas

	# Ordena os nomes das salas para pegar a primeira
	var nomes_salas = salas.keys()
	nomes_salas.sort()  # Garante que Sala_1 seja a primeira

	var primeira_sala = nomes_salas[0]
	print("✅ Sala inicial:", primeira_sala)
	
	# Garante que sala_atual seja válida
	sala_atual = salas[primeira_sala]

	# Ativa apenas a sala inicial
	mudar_sala(primeira_sala)

func mudar_sala(nova_sala: String):
	print("🔄 Mudando para:", nova_sala)

	if sala_atual:
		sala_atual.visible = false  # Esconde a sala anterior
		ativar_colisoes(sala_atual)  # Ativa as colisões da sala anterior
		print("👁️ Escondendo sala:", sala_atual.name)

	sala_atual = salas.get(nova_sala, null)

	if sala_atual:
		sala_atual.visible = true  # Mostra a nova sala
		camera.position = sala_atual.position  # Move a câmera para a nova sala
		desabilitar_colisoes(sala_atual)  # Desabilita as colisões da nova sala
		print("✅ Nova sala ativa:", sala_atual.name)
	else:
		print("⚠️ ERRO: Sala inválida!", nova_sala)

# Função para desabilitar as colisões das camadas TileMapLayer
func desabilitar_colisoes(sala: Node2D):
	for tilemap in sala.get_children():
		if tilemap is TileMap:
			# Itera por todas as camadas TileMapLayer dentro do TileMap
			for layer in tilemap.get_children():
				if layer is TileMapLayer:  # Verifica se o nó é do tipo TileMapLayer
					layer.collision_enabled = false  # Desabilita a colisão da camada

# Função para ativar as colisões das camadas TileMapLayer
func ativar_colisoes(sala: Node2D):
	for tilemap in sala.get_children():
		if tilemap is TileMap:
			# Itera por todas as camadas TileMapLayer dentro do TileMap
			for layer in tilemap.get_children():
				if layer is TileMapLayer:  # Verifica se o nó é do tipo TileMapLayer
					layer.collision_enabled = true  # Ativa a colisão da camada
