extends Panel

@onready var FriendCodeLabel = $FriendCode
@onready var FriendVBox = $FriendsContainer/VBoxContainer
@onready var RequestsVBox = $RequestsContainer/VBoxContainer

func _ready():
	FriendCodeLabel.text = Local.player_id
