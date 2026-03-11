extends Node

@onready var AccountAPI = $AccountApi
@onready var Userfield = $Control/Panel/UserField
@onready var Passfield = $Control/Panel/PassField
@onready var ViewPanel = $Control/Panel
@onready var LoginButton = $Control/Panel/SubmitButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	if OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless":
		if not get_tree().change_scene_to_file("res://environment/maps/test_map_2/test_map_2.tscn") == OK:
			print("Error getting to file")
		return

	LoginButton.pressed.connect(_on_SubmitButton_pressed)

	if not ResourceLoader.exists("res://load/AccountInfo.res"):
		ViewPanel.show()
	else:
		var account_info = ResourceLoader.load("res://load/AccountInfo.res")
		AccountAPI.login(account_info.AccountName, account_info.Password)


	# set up pipeline
	AccountAPI.connect("login_complete", get_characters)
	AccountAPI.connect("characters_received", get_account_info)
	AccountAPI.account_info_received.connect(enter_main_menu)
	
	# load settings
	
	# setup render environment
	
	# log in to account
	
	# load and enter main menu

func get_characters():
	AccountAPI.get_characters(Local.session_token)

func get_account_info():
	AccountAPI.get_account_info(Local.session_token, Local.player_id)

func enter_main_menu():
	get_tree().change_scene_to_file("res://ui/main_menu/MainMenu.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_SubmitButton_pressed():
	var account_info = AccountInfo.new()
	account_info.AccountName = Userfield.text
	account_info.Password = Passfield.text
	
	ResourceSaver.save(account_info, "res://load/AccountInfo.res")
	AccountAPI.login(account_info.AccountName, account_info.Password)
