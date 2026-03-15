extends Button

class_name InviteChit

var matchmaking_api: MatchmakingAPI
var invite_id: String

func init(api: MatchmakingAPI, id: String):
	matchmaking_api = api
	invite_id = id

func accept():
	matchmaking_api.party_response(invite_id, true)

func reject():
	matchmaking_api.party_response(invite_id, false)
	
func _pressed():
	accept()
	
