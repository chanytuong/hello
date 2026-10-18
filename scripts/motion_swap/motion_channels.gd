extends RefCounted
class_name NLBMotionChannels
## The ONE place that decides which motions may be exchanged.
##
## A swap is only coherent when both sides speak the same kind of quantity:
##
##   LINEAR   — a world-space velocity vector (enemies, crates, projectiles).
##              Exchanged as the full Vector2: direction AND magnitude.
##   SURFACE  — a conveyor's persistent operating speed: a signed scalar along
##              the belt's own axis. NOT the belt body's velocity (a belt never
##              moves); it is the speed it drives things at.
##   PLATFORM — a moving platform's persistent travel command: a signed scalar
##              along the platform's own path axis, inside its authored bounds.
##
## Compatibility table (declared, not guessed):
##   LINEAR   <-> LINEAR                       full Vector2 exchange
##   SURFACE  <-> SURFACE                      signed scalar exchange
##   PLATFORM <-> PLATFORM                     signed scalar exchange
##   SURFACE  <-> PLATFORM                     signed scalar exchange
## Everything else is REFUSED with a readable reason. A belt's operating speed
## and a crate's falling velocity are different quantities; quietly bending one
## into the other is exactly the "secretly changing the exchanged velocity"
## failure this table exists to prevent.

enum Channel { LINEAR, SURFACE, PLATFORM }

static func label(channel: int) -> String:
	match channel:
		Channel.LINEAR:
			return "LINEAR"
		Channel.SURFACE:
			return "SURFACE"
		Channel.PLATFORM:
			return "PLATFORM"
	return "UNKNOWN"

## What the exchange means on screen, for the debug overlay and feedback line.
static func description(channel: int) -> String:
	match channel:
		Channel.LINEAR:
			return "world velocity (full Vector2)"
		Channel.SURFACE:
			return "persistent belt speed along its own axis"
		Channel.PLATFORM:
			return "persistent travel speed along its own path"
	return "?"

static func compatible(a: int, b: int) -> bool:
	if a < Channel.LINEAR or a > Channel.PLATFORM or b < Channel.LINEAR or b > Channel.PLATFORM:
		return false
	if a == Channel.LINEAR or b == Channel.LINEAR:
		return a == b
	# SURFACE and PLATFORM both carry a signed scalar travel command.
	return true

## Human-readable refusal. Never silent.
static func refusal(a: int, b: int) -> String:
	return "INCOMPATIBLE: %s <-> %s cannot be exchanged (%s vs %s)" % [
		label(a), label(b), description(a), description(b)]
