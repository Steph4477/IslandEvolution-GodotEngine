extends Node
class_name GameBalance

# ============================================================================
#                           PLAYER - PV / SOINS
# ============================================================================
const PLAYER_MAX_PV = 500
const PLAYER_COOLDOWN_POTION = 10
const PLAYER_HEAL_AMOUNT = 50

# ============================================================================
#                           PLAYER - MOUVEMENT
# ============================================================================
const PLAYER_SPEED = 400
const PLAYER_JUMP_FORCE = -800
const PLAYER_GRAVITY = 1200
const PLAYER_CLIMB_SPEED = 100

# ============================================================================
#                          PLAYER - DÉGÂTS
# ============================================================================
const PLAYER_DAMAGE = {
	"clac": 20,
	"kick": 30,
	"headbutt": 35,
	"coco": 40,
	"bone": 45,
	"lance": 50,
	"coco_fire": 80,
	"bone_fire": 90,
	"lance_fire": 100
}

# ============================================================================
#                          PLAYER - SOINS
# ============================================================================
const PLAYER_HEAL = {
	"banana": 400,
	"honey": 500
}

# ============================================================================
#                     PLAYER - DÉGÂTS DE CHUTE
# ============================================================================
const PLAYER_FALL_DAMAGE_ENABLED = true
const PLAYER_FALL_SAFE_LIMIT = 1200
const PLAYER_FALL_SPEED_MAX = 1800
const PLAYER_FALL_DAMAGE_MAX = 200
const PLAYER_FALL_DAMAGE_MIN = 10

# ============================================================================
#                       PLAYER - RESPIRATION
# ============================================================================
const PLAYER_MAX_BREATH = 30
const PLAYER_PANIC_START = 15
const PLAYER_DROWN_DAMAGE_PER_SECOND = 50
const PLAYER_BUBBLE_INTERVAL_NORMAL = 1
const PLAYER_BUBBLE_INTERVAL_MIN = 0.06
const PLAYER_MOUTH_SHOW_TIME = 0.2

# ============================================================================
#                        PLAYER - NAGE
# ============================================================================
const PLAYER_SWIM_SPEED_X = 150
const PLAYER_SWIM_SPEED_Y = 110


# ============================================================================
#                       PLAYER - HEADBUTT
# ============================================================================
const PLAYER_HEADBUTT_SPEED = 300
const PLAYER_HEADBUTT_DURATION = 0.4
const PLAYER_HEADBUTT_COOLDOWN = 1.5

# ============================================================================
#                    PLAYER - TIRS / COMBAT
# ============================================================================
const PLAYER_RATE_OF_FIRE = 0.4
const PLAYER_HIT_LOCK_TIME = 0.2

# ============================================================================
#                    PLAYER - BUFFS / CAMOUFLAGE
# ============================================================================
const PLAYER_FIRE_BUFF_DURATION = 8.0
const PLAYER_AIR_BUFF_DURATION = 8.0
const PLAYER_CAMOUFLAGE_DURATION = 5.0
const PLAYER_SPRINT_DURATION = 3.0
# ============================================================================
#                              ENEMIES
# ============================================================================

const ENEMY_HP = {
	"bee": 20,
	"mosquito": 20,
	"rat": 60,
	"snake": 90,
	"pyg": 120,
	"swim_croco": 600,
	"croco": 200,
	"cannibal": 160,
	"boss_cannibal": 400,
	"boss_tarantula": 600,
	"add_tarantula": 1
	
}

const ENEMY_DAMAGE = {
	"bee": 5,
	"mosquito": 20,
	"rat": 10,
	"snake": 12,
	"pyg": 20,
	"croco": 18,
	"cannibal": 22,
	"boss": 30,
	"add_tarantula":10
}

const ENEMY_PROJECTILE = {
	"gaz": 20,
	"lance": 70,
	"bone": 90,
	"web": 80,
	"harpoon": 150
}

const ENEMY_SPEED = {
	"bee": 300,
	"mosquito" : 400,
	"rat": 500,
	"snake": 450,
	"pyg": 300,
	"swim_croco": 500,
	"croco": 400,
	"cannibal": 500,
	"boss_cannibal": 300,
	"boss_tarantula": 600,
	"add_tarantula":500
}

const ENEMY_RANGE = {
	"bee": 800,
	"mosquito": 1000,
	"rat": 600,
	"swim_croco": 1000,
	"croco": 500,
	"snake": 1000,
	"pyg": 1000,
	"cannibal": 1000,
	"boss_cannibal": 2500,
	"boss_tarantula": 5000,
	"add_tarantula": 5000
}

const ENEMY_MELEE_DISTANCE = {
	"rat": 50,
	"snake": 100,
	"pyg": 70,
	"croco": 100,
	"cannibal": 100,
	"boss_cannibal": 120,
	"boss_tarantula": 80,
	"add_tarantula": 40
}

const ENEMY_MIN_SHOOT_DISTANCE = {
	"snake": 80,
	"pyg": 200,
	"cannibal": 200,
	"boss_cannibal": 200,
	"boss_tarantula": 100
}

const ENEMY_MAX_SHOOT_DISTANCE = {
	"snake": 360,
	"pyg": 1000,
	"cannibal": 1000,
	"boss_cannibal": 1000,
	"boss_tarantula": 1000,
}
const ENEMY_COOLDOWN = {
	"bee": 0.5,
	"mosquito": 0.6,
	"rat": 1.0,
	"snake": 2.0,
	"pyg": 1.5,
	"croco": 1.5,
	"cannibal": 2.0,
	"boss_cannibal": 2.0,
	"boss_tarantula": 2.0,
	"add_tarantula": 0.6
}
