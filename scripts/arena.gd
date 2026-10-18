extends Node2D
class_name NLBArena
## Owns the single-room combat prototype geometry.
##
## The old Blink A/B authored states (platform present/gone, hazard on/off,
## B-blockers, enemy perches, spawn-eject rules) are REMOVED with the mechanic.
## What remains is one authored state: the upper platform is present, the hazard
## strip is live and the ranged enemy holds the high ground.

const RANGED_PERCH_A := Vector2(950, 440)

@onready var platform: StaticBody2D = $PlatformA
@onready var hazard: NLBHazard = $Hazard
@onready var player_spawn: Marker2D = $SpawnPlayer
@onready var melee_spawn: Marker2D = $SpawnMelee

func _ready() -> void:
	# Never rely on tscn defaults for the authored layout.
	platform.visible = true
	(platform.get_child(0) as CollisionShape2D).set_deferred("disabled", false)
	hazard.set_active(true)
