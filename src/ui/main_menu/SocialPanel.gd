extends Panel

@onready var FriendCodeLabel = $FriendCode
@onready var FriendVBox = $FriendsContainer/VBoxContainer
@onready var RequestsVBox = $RequestsContainer/VBoxContainer
@onready var AddFriendButton = $FriendsContainer/VBoxContainer/AddFriendButton

var account_api: AccountAPI

@onready var FriendChitScene = preload("res://ui/main_menu/FriendChit.tscn")
@onready var RequestChitScene = preload("res://ui/main_menu/RequestChit.tscn")
var FriendChits: Dictionary = {}
var RequestChits: Dictionary = {}

signal add_friend_button_pressed

func _ready():
	FriendCodeLabel.text = Local.player_id
	AddFriendButton.pressed.connect(_add_friend_button_pressed)

func set_friend_chits():

	var new_friends = {}
	for friend in Local.friends:
		new_friends[friend] = true
		if not friend in FriendChits.keys():
			var chit = FriendChitScene.instantiate()
			chit.set_id(friend)
			chit.set_api(account_api)
			FriendVBox.add_child(chit)
			FriendChits[friend] = chit

	var chits_to_remove = []
	for friend in FriendChits.keys():
		if not friend in new_friends.keys():
			chits_to_remove.append(friend)

	for friend in chits_to_remove:
		FriendVBox.remove_child(FriendChits[friend])
		FriendChits[friend].queue_free()
		FriendChits.erase(friend)
		

func set_request_chits():
	var new_requests = {}

	for request in Local.friend_requests:
		new_requests[request] = true
		print("[Request]: ", request)
		if not request in RequestChits.keys():
			var chit = RequestChitScene.instantiate()
			chit.set_id(request)
			chit.set_api(account_api)
			RequestsVBox.add_child(chit)
			RequestChits[request] = chit
	
	var chits_to_remove = []
	for request in RequestChits.keys():
		if not request in new_requests.keys():
			chits_to_remove.append(request)
	
	for request in chits_to_remove:
		RequestsVBox.remove_child(RequestChits[request])
		RequestChits[request].queue_free()
		RequestChits.erase(request)


func _add_friend_button_pressed():
	emit_signal("add_friend_button_pressed")
