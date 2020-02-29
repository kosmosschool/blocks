extends ButtonPressable


# button used to start and stop challenges
class_name ButtonChallenge


enum ActionType {START, STOP}

export(ActionType) var action_type
export var challenge_index : int

onready var challenge_system = get_node(global_vars.CHALLENGE_SYSTEM_PATH)


# overriding the parent function
func button_press(other_area: Area):
	.button_press(other_area)
	
	if action_type == ActionType.START:
		challenge_system.start_challenge(challenge_index)
	else:
		challenge_system.stop_challenge(challenge_index)
	
	toggle_button_status()
	

func toggle_button_status():
	if action_type == ActionType.START:
		action_type = ActionType.STOP
	else:
		action_type = ActionType.START
