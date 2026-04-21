extends Panel

@onready var PartyMemberContainer =  $VBoxContainer
var matchmaking_api: MatchmakingAPI

func _ready() -> void:
	Local.state_changed.connect(_on_party_members_updated)
	
@onready var PartyMemberButton = preload("res://ui/main_menu/PartyMemberButton.tscn")
var PartyMemberButtons: Array[PartyMemberButton] = []

	
func _clear_members() -> void:
	for member in PartyMemberButtons:
		member.queue_free()
	PartyMemberButtons.clear()

func _on_party_members_updated(state: String, value: Variant):
	if state == "in_party" and not value:
		_clear_members()
	elif state == "party_members":
		_clear_members()
		for member in value:
			var chit = PartyMemberButton.instantiate()
			chit.init(member["playerId"], member["username"])
			PartyMemberButtons.append(chit)
			PartyMemberContainer.add_child(chit)


func _on_leave_party_btn_pressed() -> void:
	matchmaking_api.party_leave()
