extends Node

class_name AccountAPI

signal login_complete
signal characters_received
signal character_created
signal account_info_received
signal account_info_updated

@onready var update_character_request: HTTPRequest = HTTPRequest.new()
@onready var account_info_update_request: HTTPRequest = HTTPRequest.new()
@onready var friend_request: HTTPRequest = HTTPRequest.new()
@onready var accept_friend_req_request: HTTPRequest = HTTPRequest.new()



var server_url: String = "http://" + Local.server_ip + ":" + Local.server_port + "/"
# var server_url: String = "http://209.38.77.226:8000/"
# var server_url: String = "http://192.168.1.238:8000/"

func _ready():
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
		
		Local.set_state("player_id", response["accountId"])
		Local.set_state("session_token", response["sessionToken"])
		Local.set_state("friend_code", response["friendCode"])

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
		var previous_selected: CharacterDef = Local.get_state("selected_character_def")
		var previous_selected_id: String = ""
		if previous_selected != null:
			previous_selected_id = String(previous_selected.ID)

		Local.get_state("characters").characters.clear()
		
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
			char_def.XP = character["xp"]
			char_def.Devotion = character["devotion"]
			
			Local.get_state("characters").characters[char_def.ID] = char_def

		if len(Local.get_state("characters").characters) > 0:
			var selected_id: String = Local.get_state("characters").characters.keys()[0]
			if previous_selected_id != "" and Local.get_state("characters").characters.has(previous_selected_id):
				selected_id = previous_selected_id
			Local.set_state("char_id", selected_id)
			Local.set_state("selected_character_def", Local.get_state("characters").characters[selected_id])
		else:
			Local.set_state("char_id", "")
			Local.set_state("selected_character_def", null)
		
		print("Characters received: ", Local.get_state("characters").characters)
		emit_signal("characters_received")
	else:
		print("Characters request failed with code: ", response_code)


func create_character(token: String, character_def: CharacterDef):
	var url = server_url + "player/character/new"
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
	var request = HTTPRequest.new()
	add_child(request)
	var err = request.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		print("Error making create_character request: ", err)
	else:
		Local.get_state("characters").characters[character_def.Name] = character_def
	request.request_completed.connect(
		func(_result, response_code, _headers, response_body):
			if response_code == 200:
				var response = JSON.parse_string(response_body.get_string_from_utf8())
				character_def.ID = response["characterId"]
				Local.get_state("characters").characters.erase(character_def.Name)
				Local.get_state("characters").characters[character_def.ID] = character_def
				print("Character created with ID: ", character_def.ID)
				emit_signal("character_created")
				set_active_character(character_def)
			else:
				print("Create character request failed with code: ", response_code)
			request.queue_free()
	)
		

func update_character(token: String, character: CharacterDef):
	var url = server_url + "player/character/update"
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

	var url = server_url + "player/account/info"
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
		Local.set_state("player_level", response["accountLevel"])
		Local.set_state("friends", response["friends"])
		Local.set_state("friend_requests", response["friendRequests"])
		Local.set_state("pending_friend_requests", response["pendingFriendRequests"])

		# print account info
		print("Account Level: ", Local.get_state("player_level"))
		print("Player XP: ", Local.get_state("player_xp"))
		print("Friends: ", Local.get_state("friends"))
		print("Friend Requests: ", Local.get_state("friend_requests"))
		print("Pending Friend Requests: ", Local.get_state("pending_friend_requests"))

		emit_signal("account_info_received")
		print("Account info received")
	else:
		print("Account info request failed with code: ", response_code)

func get_account_info_update():
	var url = server_url + "player/account/info"
	var body = {"sessionToken": Local.get_state("session_token"), "playerId": Local.get_state("player_id")}
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
		Local.set_state("friends", response["friends"])
		Local.set_state("friend_requests", response["friendRequests"])
		Local.set_state("pending_friend_requests", response["pendingFriendRequests"])

		# print account info
		print("[Account Info Update]")
		print("Friends: ", Local.get_state("friends"))
		print("Friend Requests: ", Local.get_state("friend_requests"))
		print("Pending Friend Requests: ", Local.get_state("pending_friend_requests"))
		emit_signal("account_info_updated")

	else:
		print("Account info update request failed with code: ", response_code)


func send_friend_request(friend_id: String):
	var url = server_url + "player/friend/request"
	var body = {"sessionToken": Local.get_state("session_token"), "friendCode": friend_id}
	var json_body = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]
	var err = friend_request.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		print("Error sending friend request: ", err)

func _on_send_friend_request_complete(_result, response_code, _headers, _body):
	if response_code == 200:
		print("Friend request sent successfully")
	else:
		print("Friend request failed with code: ", response_code)

func accept_friend_request(friend_id: String):
	var url = server_url + "player/friend/respond"
	var body = {"sessionToken": Local.get_state("session_token"), "playerId": friend_id, "accept": true}
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

func set_active_character(char_def: CharacterDef) -> void:
	if char_def == null:
		Local.set_state("selected_character_def", null)
		return
	var url = server_url + "player/character/set"
	var body = {"sessionToken": Local.get_state("session_token"), "characterId": char_def.ID}
	var json_body = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]
	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(_result, response_code, _headers, _body):
		if response_code >= 200 and response_code < 300:
			print("Active character successfully updated")
			Local.set_state("selected_character_def", char_def)
		else:
			print("Updating active character failed with code: ", response_code)
		req.queue_free()
	)
	var err = req.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		print("Error updating active character")
		req.queue_free()

func delete_character(token: String, character_id: String):
	var url = server_url + "player/character/delete"
	var body = {"sessionToken": token, "characterId": character_id}
	var json_body = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]
	var request = HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(
		func(_result, response_code, _headers, _body):
			if response_code == 200:
				print("Character deleted successfully")
				Local.get_state("characters").characters.erase(character_id)
				if Local.get_state("selected_character_def") and Local.get_state("selected_character_def").ID == character_id:
					Local.set_state("selected_character_def", null)
			else:
				print("Delete character request failed with code: ", response_code)
			request.queue_free()
	)
	var err = request.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		print("Error making delete_character request: ", err)
