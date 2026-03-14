extends Button

class_name RequestChit

var account_api: AccountAPI

var friend_id: String

func set_id(id: String):
	friend_id = id
	text = id
	
func set_api(acc_api: AccountAPI):
	account_api = acc_api

func _pressed() -> void:
	account_api.accept_friend_request(friend_id)
