extends RefCounted
class_name RunFlowController

signal state_changed(previous: State, current: State)

enum State {
	BOOT,
	MAIN_MENU,
	MAP_SELECT,
	CHARACTER_SELECT,
	STARTING_FAMILY_SELECT,
	RUN_MAP,
	ENCOUNTER,
	REWARD,
	DECK_EDIT,
	SHOP,
	REST,
	EVENT,
	RESULT,
}

const ALLOWED: Dictionary = {
	State.BOOT: [State.MAIN_MENU],
	State.MAIN_MENU: [State.CHARACTER_SELECT],
	State.CHARACTER_SELECT: [State.STARTING_FAMILY_SELECT, State.MAIN_MENU],
	State.STARTING_FAMILY_SELECT: [State.MAP_SELECT, State.CHARACTER_SELECT],
	State.MAP_SELECT: [State.RUN_MAP, State.STARTING_FAMILY_SELECT],
	State.RUN_MAP: [State.DECK_EDIT, State.ENCOUNTER, State.SHOP, State.REST, State.EVENT, State.RESULT],
	State.ENCOUNTER: [State.REWARD, State.RESULT],
	State.REWARD: [State.DECK_EDIT, State.RUN_MAP, State.RESULT],
	State.DECK_EDIT: [State.RUN_MAP, State.ENCOUNTER, State.SHOP, State.REST, State.EVENT],
	State.SHOP: [State.DECK_EDIT, State.RUN_MAP],
	State.REST: [State.DECK_EDIT, State.RUN_MAP],
	State.EVENT: [State.REWARD, State.DECK_EDIT, State.RUN_MAP, State.RESULT],
	State.RESULT: [State.MAIN_MENU],
}
var state: State = State.BOOT
var session: RunSession


func transition(next: State) -> bool:
	if next == state:
		return true
	if not (next in ALLOWED.get(state, [])):
		return false
	var previous := state
	state = next
	state_changed.emit(previous, state)
	return true


func attach_session(new_session: RunSession) -> void:
	session = new_session


func end_run(run_success: bool) -> bool:
	if session == null:
		return false
	session.success = run_success
	session.ended = true
	return transition(State.RESULT)
