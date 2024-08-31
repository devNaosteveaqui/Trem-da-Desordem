extends Node

const MAP_SIZE : Vector2i = Vector2(50,50)
const MAP_POS : Vector2i = Vector2(-MAP_SIZE.x/2,-MAP_SIZE.y/2)
const GROUP_PLAYER : String = "Player"
const GROUP_BLOCK : String = "Bloco"
const GROUP_ENEMY : String = "Enemy"
enum MODE {NOMODE,SINGLE_PLAYER, MULTI_PLAYER}

var RUNNING : bool = false
var MODE_SELECTED : MODE = MODE.NOMODE

func isOutOfLimit(pos : Vector2):
	var limit = {
		'xi' = MAP_POS.x*64,
		'yi' = MAP_POS.y*64,
		'xf' = (MAP_POS.x + MAP_SIZE.x)*64,
		'yf' = (MAP_POS.y + MAP_SIZE.y)*64
	}
	return !((limit.xi+48 < pos.x and limit.xf-48 > pos.x) and (limit.yi+48 < pos.y and limit.yf-48 > pos.y))

func getDirFree(pos_ref:Vector2,tolerance:float,old_dir:Vector2):
	var limit = {
		'xi' = MAP_POS.x*64,
		'yi' = MAP_POS.y*64,
		'xf' = (MAP_POS.x + MAP_SIZE.x)*64,
		'yf' = (MAP_POS.y + MAP_SIZE.y)*64
	}
	var newDir : Vector2 = Vector2(old_dir.x,old_dir.y)
	var distL = pos_ref.x - limit.xi
	if distL < tolerance:
		newDir.x = old_dir.x*(-1)
	
	var distT = pos_ref.y - limit.yi 
	if distT < tolerance:
		newDir.y = old_dir.y*(-1)
	
	return newDir
