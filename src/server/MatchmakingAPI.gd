extends Node

class_name MatchmakingAPI

var queued: bool = false
var _pending_shutdown_requests: int = 0

signal match_found(port: int, ip: String)
signal in_party_status_changed(party_members: Array[String])
signal matchmaking_status_changed(status: String)
signal party_status_updated
signal server_registered
signal match_ended_reported
signal party_faction_updated

# register_server / match_ended / delete_character_forfeit are dedicated-server,
# server-token-authed calls and stay on raw HTTPRequest — they are not routed
# through ServerConnection's player-session WebSocket.
var match_ended_request: HTTPRequest = HTTPRequest.new()
var register_server_request: HTTPRequest = HTTPRequest.new()

var server_url: String:
	get: return "http://" + Local.server_ip + ":" + Local.server_port + "/"
# var server_url = "http://209.38.77.226:8000/"
# var server_url = "http://192.168.1.238:8000/"

func _ready() -> void:
	add_child(match_ended_request)
	match_ended_request.request_completed.connect(_on_match_ended_request_request_completed)

	add_child(register_server_request)
	register_server_request.request_completed.connect(_on_register_server_request_request_completed)

	ServerConnection.response_received.connect(_on_ws_response)
	ServerConnection.push_received.connect(_on_ws_push)


func _on_ws_response(_reqId: String, type: String, ok: bool, payload: Variant, error: String) -> void:
	match type:
		"matchmaking.queue":
			_handle_queue_response(ok, payload, error)
		"matchmaking.status":
			if ok:
				_handle_status_payload(payload)
			else:
				print("Failed to get matchmaking status: ", error)
		"matchmaking.party.status":
			if ok:
				_handle_party_status_payload(payload)
			else:
				print("Failed to retrieve party status: ", error)
		"matchmaking.party.invite":
			if ok:
				print("Party invite sent successfully")
			else:
				print("Failed to send party invite: ", error)
		"matchmaking.party.leave":
			if ok:
				print("Left party successfully")
			else:
				print("Failed to leave party: ", error)
		"matchmaking.party.respond":
			if ok:
				print("Party response sent successfully")
			else:
				print("Failed to send party response: ", error)
		"matchmaking.heartbeat":
			if ok:
				print("Match heartbeat sent successfully")
			else:
				print("Failed to send match heartbeat: ", error)
		"matchmaking.joined":
			if ok:
				print("Joined match successfully")
			else:
				print("Failed to join match: ", error)
		"matchmaking.left":
			if ok:
				print("Left match successfully")
			else:
				print("Failed to leave match: ", error)


func _on_ws_push(type: String, payload: Variant) -> void:
	match type:
		"matchmaking.status":
			_handle_status_payload(payload)
		"matchmaking.party.status":
			_handle_party_status_payload(payload)


func queue_for_match():
	if not queued:
		ServerConnection.send_request("matchmaking.queue", {})
	else:
		print("Already queued for match")


func _handle_queue_response(ok: bool, payload: Variant, error: String) -> void:
	if ok:
		queued = true
		emit_signal("matchmaking_status_changed", "searching")
		print("Response from queue request: %s" % payload)
		Local.set_state("matchmaking_ticket", payload["ticketId"])
	else:
		print("Failed to queue for match: ", error)


func _handle_status_payload(status: Dictionary) -> void:
	if not status.has("status"):
		return
	if Local.get_state("matchmaking_status") != status["status"]:
		emit_signal("matchmaking_status_changed", status["status"])
	Local.set_state("matchmaking_status", status["status"])
	print("Current matchmaking status: %s" % Local.get_state("matchmaking_status"))
	if Local.get_state("matchmaking_status") == "matched":
		queued = false
		var port = int(status["port"])
		print("PORT:", port)
		var ip = "209.38.77.226"
		emit_signal("match_found", port, ip)


func party_invite(player_id: String):
	ServerConnection.send_request("matchmaking.party.invite", {"playerId": player_id})


func party_status():
	ServerConnection.send_request("matchmaking.party.status", {})


func _handle_party_status_payload(status: Dictionary) -> void:
	if status.has("inboundInvites"):
		print(status["inboundInvites"])
		Local.set_state("party_invites", status["inboundInvites"])
	if status.has("members"):
		print("[Party Members] ", status["members"])
		if len(status["members"]) > 0:
			Local.set_state("in_party", true)
		else:
			Local.set_state("in_party", false)
		Local.set_state("party_members", status["members"])
		print(status["members"])
		var party_member_names = []
		for member in Local.get_state("party_members"):
			party_member_names.append(member["username"])
		emit_signal("in_party_status_changed", Local.get_state("party_members"))
	else:
		Local.set_state("in_party", false)
		Local.set_state("party_leader", true)
		Local.set_state("party_members", [])
	if status.has("status"):
		Local.set_state("party_status", status["status"])
		if not Local.get_state("party_leader"):
			if status["status"] == "searching" and not queued:
				queued = true
				# Grab party ticket if the server provides one so status pulls work.
				if status.has("ticketId"):
					Local.set_state("matchmaking_ticket", status["ticketId"])
				emit_signal("matchmaking_status_changed", "searching")
			elif status["status"] == "matched" and status.has("port"):
				# Non-leader may have skipped "searching" entirely due to timing —
				# handle matched directly from party status so they don't get stuck.
				queued = false
				emit_signal("match_found", int(status["port"]), "209.38.77.226")
	if status.has("primaryPlayerId"):
		Local.set_state("party_leader_id", status["primaryPlayerId"])
		if Local.get_state("party_leader_id") == Local.get_state("player_id"):
			Local.set_state("party_leader", true)
		else:
			Local.set_state("party_leader", false)
	if status.has("partyFaction"):
		emit_signal("party_faction_updated", status["partyFaction"])
		print("[ACTIVE PARTY] ", status["partyFaction"])
	if status.has("allMembersHaveActiveCharacter"):
		Local.set_state("all_party_members_have_character", status["allMembersHaveActiveCharacter"])

	emit_signal("party_status_updated")
	print("Current party status: %s" % Local.get_state("party_status"))


func party_leave():
	ServerConnection.send_request("matchmaking.party.leave", {})


func party_response(invite_id: String, accept: bool):
	ServerConnection.send_request("matchmaking.party.respond", {"inviteId": invite_id, "accept": accept})


func send_match_heartbeat():
	ServerConnection.send_request("matchmaking.heartbeat", {})


func leave_match():
	ServerConnection.send_request("matchmaking.left", {})


func joined_match():
	ServerConnection.send_request("matchmaking.joined", {"ticketId": Local.get_state("matchmaking_ticket")})


func match_ended():
	var url = server_url + "matchmaking/match/ended"
	var headers = ["Content-Type: application/json"]
	var server_token = Local.get_state("server_token")
	var body = JSON.stringify({"serverToken": server_token})
	print("[MatchmakingAPI] match_ended url=%s server_token=%s" % [url, server_token])
	_pending_shutdown_requests += 1
	var req := HTTPRequest.new()
	get_tree().root.add_child(req)
	req.request_completed.connect(func(result, response_code, _headers, _body):
		if response_code >= 200 and response_code < 300:
			print("Match ended reported successfully")
		else:
			print("Failed to report match ended, result=%d response_code=%d" % [result, response_code])
		req.queue_free()
		_pending_shutdown_requests -= 1
		if _pending_shutdown_requests <= 0:
			emit_signal("match_ended_reported")
	)
	var err = req.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		push_warning("[MatchmakingAPI] Failed to submit match ended request, err=%d" % err)
		_pending_shutdown_requests -= 1

func delete_character_forfeit(character_id: String) -> void:
	if character_id.is_empty():
		return
	var url = server_url + "player/character/delete"
	var headers = ["Content-Type: application/json"]
	var server_token = Local.get_state("server_token")
	var body: Dictionary = {"characterId": character_id}
	if server_token != "":
		body["serverToken"] = server_token
	else:
		push_warning("[MatchmakingAPI] No token available to delete character for forfeit")
		return
	print("[MatchmakingAPI] delete_character_forfeit url=%s server_token=%s character_id=%s" % [url, server_token, character_id])

	_pending_shutdown_requests += 1
	var req := HTTPRequest.new()
	get_tree().root.add_child(req)
	req.request_completed.connect(func(result, response_code, _headers, _body):
		if response_code >= 200 and response_code < 300:
			print("[MatchmakingAPI] Forfeit delete succeeded for character_id=%s" % character_id)
		else:
			print("[MatchmakingAPI] Forfeit delete failed for character_id=%s result=%d code=%d" % [character_id, result, response_code])
		req.queue_free()
		_pending_shutdown_requests -= 1
		if _pending_shutdown_requests <= 0:
			emit_signal("match_ended_reported")
	)
	var err = req.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		push_warning("[MatchmakingAPI] Failed to submit forfeit delete request err=%d" % err)
		_pending_shutdown_requests -= 1
		if _pending_shutdown_requests <= 0:
			emit_signal("match_ended_reported")

func _on_match_ended_request_request_completed(_result, response_code, _headers, _body) -> void:
	if response_code >= 200 and response_code < 300:
		emit_signal("match_ended_reported")
		print("Match ended reported successfully")
	else:
		print("Failed to report match ended, response code: %d" % response_code)

func register_server(server_name: String, registration_token: String):
	var url = server_url + "matchmaking/server/register"
	print("[SERVER] URL for server registration: ", url)
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({"sessionToken": Local.get_state("session_token"), "serverName": server_name, "registrationKey": registration_token})
	register_server_request.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_register_server_request_request_completed(_result, response_code, _headers, _body) -> void:
	if response_code >= 200 and response_code < 300:
		print("Server registered successfully")
		Local.set_state("server_token", JSON.parse_string(_body.get_string_from_utf8())["serverToken"])
		Local.set_state("server_token_id", JSON.parse_string(_body.get_string_from_utf8())["tokenId"])
		emit_signal("server_registered")
	else:
		print("Failed to register server, response code: %d" % response_code)
