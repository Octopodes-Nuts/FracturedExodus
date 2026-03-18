extends Node

class_name AccountAPI

signal login_complete
signal characters_received
signal character_created
signal account_info_received
signal account_info_updated

@onready var newCharacterRequest: HTTPRequest = HTTPRequest.new()
@onready var update_character_request: HTTPRequest = HTTPRequest.new()
@onready var account_info_update_request: HTTPRequest = HTTPRequest.new()
@onready var friend_request: HTTPRequest = HTTPRequest.new()
@onready var accept_friend_req_request: HTTPRequest = HTTPRequest.new()

var server_url: String = "http://209.38.77.226:8000/"

func _ready():
	add_child(newCharacterRequest)
	newCharacterRequest.request_completed.connect(_on_create_character_request_complete)
	add_child(update_character_request)
	update_character_request.request_completed.connect(_on_update_character_request_completed)
	add_child(account_info_update_request)
	account_info_update_request.request_completed.connect(_on_get_account_info_update_request_complete)
	add_child(friend_request)
	friend_request.request_completed.connect(_on_send_friend_request_complete)
	add_child(accept_friend_req_request)
	accept_friend_req_request.request_completed.connect(_on_accept_friend_request_complete)

func login(username: String, password: String):

	var request = HTTPRequest.new()
	add_child(request)

	request.request_completed.connect(_on_login_request_completed)

	var url = server_url + "player/login"
	var body = {"username": username, "password": password}
	var json_body = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]
	var err = request.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		print("Error making login request: ", err)



func _on_login_request_completed(_result, response_code, _headers, body):
	if response_code == 200:
		var response = JSON.parse_string(body.get_string_from_utf8())

		print("Login response: ", response)
		
		Local.player_id = response["accountId"]
		Local.session_token = response["sessionToken"]

		if "error" in response.keys():
			print("Login failed: ", response["error"])
		else:
			print("Login successful! Token: ", response["sessionToken"])
		emit_signal("login_complete")
	else:
		print("Login request failed with code: ", response_code)



func get_characters(token: String):
	var request = HTTPRequest.new()
	add_child(request)
	
	request.request_completed.connect(_on_get_characters_request_complete)

	var url = server_url + "player/characters"
	var body = {"sessionToken": token}
	var json_body = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]
	var err = request.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		print("Error making get_characters request: ", err)

func _on_get_characters_request_complete(_result, response_code, _headers, body):
	if response_code == 200:
		var response = JSON.parse_string(body.get_string_from_utf8())
		
		for character in response["characters"]:
			var char_def = CharacterDef.new()
			char_def.ID = character["id"]
			char_def.Name = character["name"]
			char_def.Weapon1 = character["weapon1"]
			char_def.Weapon2 = character["weapon2"]
			char_def.Weapon3 = character["weapon3"]
			char_def.Equipment1 = character["equipment1"]
			char_def.Equipment2 = character["equipment2"]
			char_def.ClassType = character["classType"]
			char_def.Faction = character["faction"]
			
			Local.characters.characters[char_def.Name] = char_def

		if len(Local.characters.characters) > 0:
			Local.char_id = Local.characters.characters.keys()[0]
			Local.selected_character_def = Local.characters.characters[Local.char_id]
		
		print("Characters received: ", Local.characters.characters)
		emit_signal("characters_received")
	else:
		print("Characters request failed with code: ", response_code)


func create_character(token: String, character_def: CharacterDef):

	var url = server_url + "player/newCharacter"
	var body = {
		"sessionToken": token,
		"name": character_def.Name,
		"weapon1": character_def.Weapon1,
		"weapon2": character_def.Weapon2,
		"weapon3": character_def.Weapon3,
		"equipment1": character_def.Equipment1,
		"equipment2": character_def.Equipment2,
		"classType": character_def.ClassType,
		"faction": character_def.Faction,
	}
	var json_body = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]
	var err = newCharacterRequest.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		print("Error making create_character request: ", err)
	else:
		Local.characters.characters[character_def.Name] = character_def
		Local.selected_character_def = character_def

func _on_create_character_request_complete(_result, response_code, _headers, body):
	if response_code == 200:
		var response = JSON.parse_string(body.get_string_from_utf8())
		
		for character in Local.characters.characters.keys():
			if Local.characters.characters[character].ID == "":
				Local.characters.characters[character].ID = response["characterId"]
				Local.sort_characters()
		
		emit_signal("character_created")
	else:
		print("Create character request failed with code: ", response_code)
		

func update_character(token: String, character: CharacterDef):
	var url = server_url + "player/updateCharacter"
	var body = {
		"sessionToken": token,
		"characterId": character.ID,
		"name": character.Name,
		"skinKey": "",
		"weapon1": character.Weapon1,
		"weapon2": character.Weapon2,
		"weapon3": character.Weapon3,
		"equipment1": character.Equipment1,
		"equipment2": character.Equipment2,
		"classType": character.ClassType,
		"faction": character.Faction
	}
	var json_body = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]
	var err = update_character_request.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		print("Error submitting character update request")

func _on_update_character_request_completed(_result, response_code, _headers, _body):
	if response_code == 200:
		print("Character Updated")
	else:
		print(response_code, "character could not be updated")

func get_account_info(token: String, player_id: String):
	var http_request = HTTPRequest.new()
	add_child(http_request)

	print("Getting account info with token: ", token)

	var url = server_url + "player/accountInfo"
	var body = {"sessionToken": token, "playerId": player_id}
	var json_body = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]
	http_request.request_completed.connect(_on_get_account_info_request_complete)
	var err = http_request.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		print("Error making get_account_info request: ", err)

func _on_get_account_info_request_complete(_result, response_code, _headers, body):
	print("Account info response code: ", response_code)
	if response_code == 200:
		var response = JSON.parse_string(body.get_string_from_utf8())
		Local.player_level = response["accountLevel"]
		Local.player_xp = response["experience"]
		Local.friends = response["friends"]
		Local.friend_requests = response["friendRequests"]
		Local.pending_friend_requests = response["pendingFriendRequests"]

		# print account info
		print("Account Level: ", Local.player_level)
		print("Player XP: ", Local.player_xp)
		print("Friends: ", Local.friends)
		print("Friend Requests: ", Local.friend_requests)
		print("Pending Friend Requests: ", Local.pending_friend_requests)

		emit_signal("account_info_received")
		print("Account info received")
	else:
		print("Account info request failed with code: ", response_code)

func get_account_info_update():
	var url = server_url + "player/accountInfo"
	var body = {"sessionToken": Local.session_token, "playerId": Local.player_id}
	var json_body = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]
	var err = account_info_update_request.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		print("Error making account info update request: ", err)

func _on_get_account_info_update_request_complete(_result, response_code, _headers, body):
	print("Account info update response code: ", response_code)
	if response_code == 200:
		var response = JSON.parse_string(body.get_string_from_utf8())
		# ignore level and xp, this will be tracked locally and updated after each match
		Local.friends = response["friends"]
		Local.friend_requests = response["friendRequests"]
		Local.pending_friend_requests = response["pendingFriendRequests"]

		# print account info
		print("[Account Info Update]")
		print("Friends: ", Local.friends)
		print("Friend Requests: ", Local.friend_requests)
		print("Pending Friend Requests: ", Local.pending_friend_requests)
		emit_signal("account_info_updated")

	else:
		print("Account info update request failed with code: ", response_code)


func send_friend_request(friend_id: String):
	var url = server_url + "player/friendRequest"
	var body = {"sessionToken": Local.session_token, "playerId": friend_id}
	var json_body = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]
	friend_request.request_completed.connect(_on_send_friend_request_complete)
	var err = friend_request.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		print("Error sending friend request: ", err)

func _on_send_friend_request_complete(_result, response_code, _headers, _body):
	if response_code == 200:
		print("Friend request sent successfully")
	else:
		print("Friend request failed with code: ", response_code)

func accept_friend_request(friend_id: String):
	var url = server_url + "player/acceptRejectFriendRequest"
	var body = {"sessionToken": Local.session_token, "playerId": friend_id, "accept": true}
	var json_body = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]
	var request = HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(_on_accept_friend_request_complete)
	var err = request.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		print("Error accepting friend request: ", err)

func _on_accept_friend_request_complete(_result, response_code, _headers, _body):
	if response_code == 200:
		print("Friend request accepted successfully")
	else:
		print("Accepting friend request failed with code: ", response_code)
