extends Button

class_name FriendChit

var account_api: AccountAPI
var matchmaking_api: MatchmakingAPI

var friend_id: String

func _init():
	pass
	
func set_friend(id: String, username: String):
	text = username
	friend_id = id

func set_api(acc_api: AccountAPI):
	account_api = acc_api
	
func _pressed():
	matchmaking_api.party_invite(friend_id)
