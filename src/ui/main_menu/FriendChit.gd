extends Button

class_name FriendChit

var account_api: AccountAPI
var matchmaking_api: MatchmakingAPI

var friend_id: String

const MAX_PARTY_SIZE := 4

func _ready() -> void:
	Local.state_changed.connect(_on_state_changed)
	_update_disabled()

func _on_state_changed(state: StringName, _value: Variant) -> void:
	if state == "party_members" or state == "in_party":
		_update_disabled()

func _update_disabled() -> void:
	disabled = Local.party_members.size() >= MAX_PARTY_SIZE

func set_friend(id: String, username: String):
	text = username
	friend_id = id

func set_api(acc_api: AccountAPI):
	account_api = acc_api

func _pressed():
	matchmaking_api.party_invite(friend_id)
