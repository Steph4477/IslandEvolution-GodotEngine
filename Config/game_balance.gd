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
const PLAYER_SWIM_SPEED_X = 450
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
	"snake_melee": 90,
	"snake_distance": 90,
	"snake_heal": 90,
	"pyg": 120,
	"pyg_melee": 120,
	"pyg_distance": 120,
	"pyg_heal": 120,
	"swim_croco": 600,
	"croco": 200,
	"pyranha": 50,
	"cannibal": 160,
	"cannibal_melee": 160,
	"cannibal_distance": 160,
	"cannibal_heal": 160,
	"boss_cannibal": 400,
	"boss_tarantula": 600,
	"add_tarantula": 1
}

const ENEMY_DAMAGE = {
	"bee": 5,
	"mosquito": 20,
	"rat": 10,
	"snake": 12,
	"snake_melee": 12,
	"snake_distance": 12,
	"snake_heal": 12,
	"pyg": 20,
	"pyg_melee": 20,
	"pyg_distance": 20,
	"pyg_heal": 20,
	"croco": 18,
	"pyranha": 10,
	"cannibal": 22,
	"cannibal_melee": 22,
	"cannibal_distance": 22,
	"cannibal_heal": 22,
	"boss_cannibal": 30,
	"boss_tarantula": 30,
	"add_tarantula": 10
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
	"mosquito": 400,
	"rat": 500,
	"snake": 450,
	"snake_melee": 450,
	"snake_distance": 450,
	"snake_heal": 450,
	"pyg": 300,
	"pyg_melee": 300,
	"pyg_distance": 300,
	"pyg_heal": 300,
	"swim_croco": 500,
	"cannibal": 300,
	"cannibal_melee": 300,
	"cannibal_distance": 300,
	"cannibal_heal": 300,
	"croco": 400,
	"pyranha": 300,
	"boss_cannibal": 300,
	"boss_tarantula": 600,
	"add_tarantula": 500
}

const ENEMY_RANGE = {
	"bee": 800,
	"mosquito": 1000,
	"rat": 600,
	"swim_croco": 1000,
	"croco": 500,
	"pyranha": 1000,
	"snake": 1000,
	"snake_melee": 1000,
	"snake_distance": 1500,
	"snake_heal": 1000,
	"pyg": 1000,
	"pyg_melee": 1000,
	"pyg_distance": 1000,
	"pyg_heal": 1000,
	"cannibal": 1000,
	"cannibal_melee": 1000,
	"cannibal_distance": 1000,
	"cannibal_heal": 1000,
	"boss_cannibal": 2500,
	"boss_tarantula": 5000,
	"add_tarantula": 5000
}

const ENEMY_MELEE_DISTANCE = {
	"rat": 50,
	"snake": 100,
	"snake_melee": 100,
	"snake_distance": 100,
	"snake_heal": 100,
	"pyg": 70,
	"pyg_melee": 70,
	"pyg_distance": 70,
	"pyg_heal": 70,
	"croco": 100,
	"cannibal": 100,
	"cannibal_melee": 100,
	"cannibal_distance": 100,
	"cannibal_heal": 100,
	"boss_cannibal": 120,
	"boss_tarantula": 80,
	"add_tarantula": 40
}

const ENEMY_MIN_SHOOT_DISTANCE = {
	"snake": 80,
	"snake_distance": 80,
	"pyg": 200,
	"pyg_distance": 200,
	"cannibal": 200,
	"cannibal_distance": 200,
	"boss_cannibal": 200,
	"boss_tarantula": 100
}

const ENEMY_MAX_SHOOT_DISTANCE = {
	"snake": 360,
	"snake_distance": 1000,
	"pyg": 1000,
	"pyg_distance": 1000,
	"cannibal": 1000,
	"cannibal_distance": 1000,
	"boss_cannibal": 1000,
	"boss_tarantula": 1000
}

const ENEMY_COOLDOWN = {
	"bee": 0.5,
	"mosquito": 0.6,
	"rat": 1.0,
	"snake": 2.0,
	"snake_melee": 0.5,
	"snake_distance": 0.8,
	"snake_heal": 1.0,
	"pyg": 1.5,
	"pyg_melee": 0.2,
	"pyg_distance": 1.5,
	"pyg_heal": 1.3,
	"croco": 1.5,
	"pyranha": 1.0,
	"cannibal": 2.0,
	"cannibal_melee": 1.4,
	"cannibal_distance": 2.0,
	"cannibal_heal": 1.4,
	"boss_cannibal": 2.0,
	"boss_tarantula": 2.0,
	"add_tarantula": 0.6
}

const ENEMY_ANIMATION_ATTACK = {
	"snake_melee": "attack",
	"snake_distance": "attack",
	"snake_heal": "attack",
	"pyg_melee": "cac",
	"pyg_distance": "attack",
	"pyg_heal": "attack",
	"cannibal_melee": "attack",
	"cannibal_distance": "attack",
	"cannibal_heal": "cac",
}

const ENEMY_ANIMATION_WALK = {
	"snake_melee": "walk",
	"snake_distance": "walk",
	"snake_heal": "walk",
	"pyg_melee": "walk",
	"pyg_distance": "walk",
	"pyg_heal": "walk",
	"cannibal_melee": "walk",
	"cannibal_distance": "walk",
	"cannibal_heal": "walk"
}

const ENEMY_PROJECTILE_DAMAGE = {
	"snake_distance": 20,
	"pyg_distance": 70,
	"cannibal_distance": 90,
}

const ENEMY_FIRE_INTERVAL = {
	"snake_distance": 2.0,
	"snake_heal": 3.0,
	"pyg_distance": 1.5,
	"pyg_heal": 3.0,
	"cannibal_distance": 2.0,
	"cannibal_heal": 3.0
}

const ENEMY_PROJECTILE_SCENE = {
	"snake_distance": "res://Shoot/Enemies/Gaz/gaz.tscn",
	"snake_heal": "res://Enemies/Cannibal/heal_projectile/heal_projectile.tscn",
	"pyg_heal": "res://Enemies/Cannibal/heal_projectile/heal_projectile.tscn",
	"pyg_distance": "res://Shoot/Enemies/Spear/spear.tscn",
	"cannibal_distance": "res://Shoot/Enemies/Bone/bone.tscn",
	"cannibal_heal": "res://Enemies/Cannibal/heal_projectile/heal_projectile.tscn"
}

const ENEMY_ANIMATION_SHOOT = {
	"snake_distance": "attack",
	"snake_heal": "attack",
	"pyg_distance": "attack",
	"pyg_heal": "attack",
	"cannibal_distance": "attack",
	"cannibal_heal": "attack"
}

const ENEMY_CAN_JUMP = {
	"snake_heal": false,
	"pyg_heal": true,
	"cannibal_heal": true
}
