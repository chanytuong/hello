extends "res://tests/test_motion_swap_chaos.gd"
## Same legacy scenarios, with extra diagnostics for real-time / RigidBody reads.
func check(ok: bool,title: String,values: Dictionary={}) -> void:
	if title=="Iven / movable crate exchanges full actual world velocity":
		values=values.duplicate()
		values["received"]=str(player.swap_target.received_velocity)
		values["exchange"]=controller.last_exchange
		var crate:=lab.get_node("World/ZoneA/Crate") as LabCrate
		values["crate_velocity"]=str(crate.linear_velocity)
	super.check(ok,title,values)
