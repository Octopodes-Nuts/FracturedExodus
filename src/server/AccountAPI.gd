extends Node

class_name AccountAPI

signal login_complete
signal characters_received
signal character_created
signal account_info_received
signal account_info_updated

# reqId -> CharacterDef, for requests whose response needs context that
# isn't in the reply payload itself.
var _pending_create_character: Dictionary = {}
var _pending_delete_character: Dictionary = {}
var _pending_set_active_character: Dictionary = {}


func _ready() -> void:
	ServerConnection.response_received.connect(_on_ws_response)
	ServerConnection.push_received.connect(_on_ws_push)


func _on_ws_response(reqId: String, type: String, ok: bool, payload: Variant, error: String) -> void:
	match type:
		"account.login":
			_handle_login_response(ok, payload, error)
		"account.getCharacters":
			_handle_get_characters_response(ok, payload, error)
		"account.createCharacter":
			_handle_create_character_response(reqId, ok, payload, error)
		"account.updateCharacter":
			_handle_update_character_response(ok, error)
		"account.getInfo":
			_handle_get_account_info_response(ok, payload, error)
		"account.getInfoUpdate":
			_handle_get_account_info_update_response(ok, payload, error)
		"account.sendFriendRequest":
			_handle_send_friend_request_response(ok, error)
		"account.respondFriendRequest":
			_handle_accept_friend_request_response(ok, error)
		"account.setActiveCharacter":
			_handle_set_active_character_response(reqId, ok, error)
		"account.deleteCharacter":
			_handle_delete_character_response(reqId, ok, error)


func _on_ws_push(type: String, payload: Variant) -> void:
	match type:
		"account.infoUpdated":
			_apply_account_info_update(payload)


func login(username: String, password: String):
	ServerConnection.send_request("account.login", {"username": username, "password": password})


func _handle_login_response(ok: bool, payload: Variant, error: String) -> void:
	print("Login response: ", payload)
	if ok:
		Local.set_state("player_id", payload["accountId"])
		Local.set_state("session_token", payload["sessionToken"])
		Local.set_state("friend_code", payload["friendCode"])
		print("Login successful! Token: ", payload["sessionToken"])
		emit_signal("login_complete")
	else:
		print("Login failed: ", error)


func get_characters(_token: String):
	ServerConnection.send_request("account.getCharacters", {})


func _handle_get_characters_response(ok: bool, payload: Variant, error: String) -> void:
	if not ok:
		print("Characters request failed: ", error)
		return

	var response = payload
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
		var selected_id: String = ""
		# Restore previously selected character if it still exists
		if previous_selected_id != "" and Local.get_state("characters").characters.has(previous_selected_id):
			selected_id = previous_selected_id
		# Otherwise fall back to the first character matching the current faction
		if selected_id == "":
			var current_faction: int = Local.get_state("selected_faction")
			for id in Local.get_state("characters").characters.keys():
				var c = Local.get_state("characters").characters[id]
				if c.Faction == current_faction:
					selected_id = id
					break
		if selected_id != "":
			Local.set_state("char_id", selected_id)
			Local.set_state("selected_character_def", Local.get_state("characters").characters[selected_id])
		else:
			Local.set_state("char_id", "")
			Local.set_state("selected_character_def", null)
	else:
		Local.set_state("char_id", "")
		Local.set_state("selected_character_def", null)

	print("Characters received: ", Local.get_state("characters").characters)
	emit_signal("characters_received")


func create_character(_token: String, character_def: CharacterDef):
	Local.get_state("characters").characters[character_def.Name] = character_def
	var req_id = ServerConnection.send_request("account.createCharacter", {
		"name": character_def.Name,
		"weapon1": character_def.Weapon1,
		"weapon2": character_def.Weapon2,
		"weapon3": character_def.Weapon3,
		"equipment1": character_def.Equipment1,
		"equipment2": character_def.Equipment2,
		"classType": character_def.ClassType,
		"faction": character_def.Faction,
	})
	_pending_create_character[req_id] = character_def


func _handle_create_character_response(reqId: String, ok: bool, payload: Variant, error: String) -> void:
	if not _pending_create_character.has(reqId):
		return
	var character_def: CharacterDef = _pending_create_character[reqId]
	_pending_create_character.erase(reqId)
	if ok:
		character_def.ID = payload["characterId"]
		Local.get_state("characters").characters.erase(character_def.Name)
		Local.get_state("characters").characters[character_def.ID] = character_def
		print("Character created with ID: ", character_def.ID)
		emit_signal("character_created")
		set_active_character(character_def)
	else:
		print("Create character request failed: ", error)


func update_character(_token: String, character: CharacterDef):
	ServerConnection.send_request("account.updateCharacter", {
		"characterId": character.ID,
		"name": character.Name,
		"skinKey": "",
		"weapon1": character.Weapon1,
		"weapon2": character.Weapon2,
		"weapon3": character.Weapon3,
		"equipment1": character.Equipment1,
		"equipment2": character.Equipment2,
		"classType": character.ClassType,
		"faction": character.Faction,
	})


func _handle_update_character_response(ok: bool, error: String) -> void:
	if ok:
		print("Character Updated")
	else:
		print(error, "character could not be updated")


func get_account_info(_token: String, _player_id: String):
	print("Getting account info (bound identity)")
	ServerConnection.send_request("account.getInfo", {})


func _handle_get_account_info_response(ok: bool, payload: Variant, error: String) -> void:
	print("Account info response ok: ", ok)
	if ok:
		Local.set_state("player_level", payload["accountLevel"])
		Local.set_state("friends", payload["friends"])
		Local.set_state("friend_requests", payload["friendRequests"])
		Local.set_state("pending_friend_requests", payload["pendingFriendRequests"])

		# print account info
		print("Account Level: ", Local.get_state("player_level"))
		print("Player XP: ", Local.get_state("player_xp"))
		print("Friends: ", Local.get_state("friends"))
		print("Friend Requests: ", Local.get_state("friend_requests"))
		print("Pending Friend Requests: ", Local.get_state("pending_friend_requests"))

		emit_signal("account_info_received")
		print("Account info received")
	else:
		print("Account info request failed: ", error)


func get_account_info_update():
	ServerConnection.send_request("account.getInfoUpdate", {})


func _handle_get_account_info_update_response(ok: bool, payload: Variant, error: String) -> void:
	print("Account info update response ok: ", ok)
	if ok:
		_apply_account_info_update(payload)
	else:
		print("Account info update request failed: ", error)


func _apply_account_info_update(payload: Variant) -> void:
	# ignore level and xp, this will be tracked locally and updated after each match
	Local.set_state("friends", payload["friends"])
	Local.set_state("friend_requests", payload["friendRequests"])
	Local.set_state("pending_friend_requests", payload["pendingFriendRequests"])

	# print account info
	print("[Account Info Update]")
	print("Friends: ", Local.get_state("friends"))
	print("Friend Requests: ", Local.get_state("friend_requests"))
	print("Pending Friend Requests: ", Local.get_state("pending_friend_requests"))
	emit_signal("account_info_updated")


func send_friend_request(friend_id: String):
	ServerConnection.send_request("account.sendFriendRequest", {"friendCode": friend_id})


func _handle_send_friend_request_response(ok: bool, error: String) -> void:
	if ok:
		print("Friend request sent successfully")
	else:
		print("Friend request failed: ", error)


func accept_friend_request(friend_id: String):
	ServerConnection.send_request("account.respondFriendRequest", {"playerId": friend_id, "accept": true})


func _handle_accept_friend_request_response(ok: bool, error: String) -> void:
	if ok:
		print("Friend request accepted successfully")
	else:
		print("Accepting friend request failed: ", error)


func set_active_character(char_def: CharacterDef) -> void:
	if char_def == null:
		Local.set_state("selected_character_def", null)
		return
	var req_id = ServerConnection.send_request("account.setActiveCharacter", {"characterId": char_def.ID})
	_pending_set_active_character[req_id] = char_def


func _handle_set_active_character_response(reqId: String, ok: bool, error: String) -> void:
	if not _pending_set_active_character.has(reqId):
		return
	var char_def: CharacterDef = _pending_set_active_character[reqId]
	_pending_set_active_character.erase(reqId)
	if ok:
		print("Active character successfully updated")
		Local.set_state("selected_character_def", char_def)
	else:
		print("Updating active character failed: ", error)


func delete_character(_token: String, character_id: String):
	var req_id = ServerConnection.send_request("account.deleteCharacter", {"characterId": character_id})
	_pending_delete_character[req_id] = character_id


func _handle_delete_character_response(reqId: String, ok: bool, error: String) -> void:
	if not _pending_delete_character.has(reqId):
		return
	var character_id: String = _pending_delete_character[reqId]
	_pending_delete_character.erase(reqId)
	if ok:
		print("Character deleted successfully")
		Local.get_state("characters").characters.erase(character_id)
		if Local.get_state("selected_character_def") and Local.get_state("selected_character_def").ID == character_id:
			Local.set_state("selected_character_def", null)
	else:
		print("Delete character request failed: ", error)
