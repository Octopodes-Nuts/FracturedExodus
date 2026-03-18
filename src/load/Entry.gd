extends Node

@onready var AccountAPI = $AccountApi
@onready var Userfield = $Control/Panel/UserField
@onready var Passfield = $Control/Panel/PassField
@onready var ViewPanel = $Control/Panel
@onready var LoginButton = $Control/Panel/SubmitButton
@onready var MatchmakingAPI = $MatchmakingApi

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	if OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless":
		Local.server_name = OS.get_environment("MM_SERVER_NAME")
		Local.registration_token = OS.get_environment("MM_SERVER_REGISTRATION_KEY")
		Local.host = true
			# If no registration token is provided, we assume this is a local dedicated server for testing
		if Local.registration_token == "":
			print("No registration token provided, assuming local dedicated server for testing")
			_enter_dedicated_server_map()
			return
		else:
			print("Registration token provided, attempting to register server with matchmaking service")
			MatchmakingAPI.register_server(Local.server_name, Local.registration_token)
				# If registration fails, we fall back to local dedicated server mode
		MatchmakingAPI.server_registered.connect(func(): call_deferred("_enter_dedicated_server_map"))
		return
	else:
	# set up pipeline
		Local.selected_faction = Factions.ENTENTE
		AccountAPI.connect("login_complete", get_characters)
		AccountAPI.connect("characters_received", get_account_info)
		AccountAPI.characters_received.connect(Local.sort_characters)
		AccountAPI.account_info_received.connect(enter_main_menu)
		AccountAPI.login_complete.connect(MatchmakingAPI.party_leave)

		LoginButton.pressed.connect(_on_SubmitButton_pressed)

		var cli_credentials = _get_cli_credentials()
		if not cli_credentials.is_empty():
			AccountAPI.login(cli_credentials.user, cli_credentials.password)
			print(cli_credentials.user, cli_credentials.password)
			return

		if not ResourceLoader.exists("res://load/AccountInfo.res"):
			ViewPanel.show()
		else:
			var account_info = ResourceLoader.load("res://load/AccountInfo.res")
			AccountAPI.login(account_info.AccountName, account_info.Password)
	
	
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

func _get_cli_credentials() -> Dictionary:
	var args = OS.get_cmdline_args()
	var user = ""
	var password = ""

	for i in range(args.size()):
		var arg = args[i]

		if arg.begins_with("--user="):
			user = _strip_surrounding_quotes(arg.substr("--user=".length()))
		elif arg == "--user" and i + 1 < args.size():
			user = _strip_surrounding_quotes(args[i + 1])
		elif arg.begins_with("--password="):
			password = _strip_surrounding_quotes(arg.substr("--password=".length()))
		elif arg == "--password" and i + 1 < args.size():
			password = _strip_surrounding_quotes(args[i + 1])

	if user.is_empty() or password.is_empty():
		return {}

	return {
		"user": user,
		"password": password,
	}

func _strip_surrounding_quotes(value: String) -> String:
	if value.length() < 2:
		return value

	var first = value[0]
	var last = value[value.length() - 1]
	var has_matching_double_quotes = first == '"' and last == '"'
	var has_matching_single_quotes = first == "'" and last == "'"

	if has_matching_double_quotes or has_matching_single_quotes:
		return value.substr(1, value.length() - 2)

	return value

func _on_SubmitButton_pressed():
	var account_info = AccountInfo.new()
	account_info.AccountName = Userfield.text
	account_info.Password = Passfield.text
	
	ResourceSaver.save(account_info, "res://load/AccountInfo.res")
	AccountAPI.login(account_info.AccountName, account_info.Password)

func _enter_dedicated_server_map() -> void:
	var err = get_tree().change_scene_to_file("res://environment/maps/test_map_2/test_map_2.tscn")
	if err != OK:
		push_error("[Entry] Failed to enter dedicated server map (error=%d)" % [err])
