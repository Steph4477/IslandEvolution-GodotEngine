extends Node
class_name GameBalance

# ============================================================================
#                           PLAYER - PV / SOINS
# ============================================================================
const PLAYER_MAX_PV = 100
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
	"clac": 10,
	"kick": 20,
	"headbutt": 15,
	"coco": 20,
	"bone": 25,
	"lance": 30,
	"coco_fire": 40,
	"bone_fire": 50,
	"lance_fire": 60
}

# ============================================================================
#                          PLAYER - SOINS
# ============================================================================
const PLAYER_HEAL = {
	"banana": 500,
	"honey": 600
}

# ============================================================================
#                     PLAYER - DÉGÂTS DE CHUTE
# ============================================================================
const PLAYER_FALL_DAMAGE_ENABLED = true
const PLAYER_FALL_SAFE_LIMIT = 1200
const PLAYER_FALL_SPEED_MAX = 1800
const PLAYER_FALL_DAMAGE_MAX = 600
const PLAYER_FALL_DAMAGE_MIN = 50

# ============================================================================
#                       PLAYER - RESPIRATION
# ============================================================================
const PLAYER_MAX_BREATH = 30
const PLAYER_PANIC_START = 15
const PLAYER_DROWN_DAMAGE_PER_SECOND = 500
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
const PLAYER_HIT_LOCK_TIME = 0.6

# ============================================================================
#                    PLAYER - BUFFS / CAMOUFLAGE
# ============================================================================
const PLAYER_FIRE_BUFF_DURATION = 8.0
const PLAYER_AIR_BUFF_DURATION = 8.0
const PLAYER_CAMOUFLAGE_DURATION = 5.0
