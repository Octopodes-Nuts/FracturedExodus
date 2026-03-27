extends Node

class_name MatchmakingAPI

var queued: bool = false

signal match_found(port: int, ip: String)
signal in_party_status_changed(party_members: Array[String])
signal matchmaking_status_changed(status: String)
signal server_registered
signal match_ended_reported
signal party_faction_updated

var queue_request: HTTPRequest = HTTPRequest.new()
var status_update_request: HTTPRequest = HTTPRequest.new()
var party_invite_request: HTTPRequest = HTTPRequest.new()
var party_status_request: HTTPRequest = HTTPRequest.new()
var party_leave_request: HTTPRequest = HTTPRequest.new()
var party_response_request: HTTPRequest = HTTPRequest.new()
var match_heartbeat_request: HTTPRequest = HTTPRequest.new()

var joined_match_request: HTTPRequest = HTTPRequest.new()
var match_ended_request: HTTPRequest = HTTPRequest.new()
var register_server_request: HTTPRequest = HTTPRequest.new()

var status_timer: Timer = Timer.new()
var status_update_interval: float = 1.0

var server_url: String = "http://" + Local.server_ip + ":" + Local.server_port + "/"
# var server_url = "http://209.38.77.226:8000/"
# var server_url = "http://192.168.1.238:8000/"

func _ready() -> void:
	add_child(queue_request)
	queue_request.request_completed.connect(_on_queue_request_request_completed)
	
	add_child(status_update_request)
	status_update_request.request_completed.connect(_on_status_update_request_request_completed)

	add_child(party_invite_request)
	party_invite_request.request_completed.connect(_on_party_invite_request_request_completed)

	add_child(party_status_request)
	party_status_request.request_completed.connect(_on_party_status_request_request_completed)

	add_child(party_leave_request)
	party_leave_request.request_completed.connect(_on_party_leave_request_request_completed)

	add_child(party_response_request)
	party_response_request.request_completed.connect(_on_party_response_request_request_completed)

	add_child(match_heartbeat_request)
	match_heartbeat_request.request_completed.connect(_on_match_heartbeat_request_request_completed)

	add_child(joined_match_request)
	joined_match_request.request_completed.connect(_on_joined_match_request_request_completed)

	add_child(match_ended_request)
	match_ended_request.request_completed.connect(_on_match_ended_request_request_completed)

	add_child(register_server_request)
	register_server_request.request_completed.connect(_on_register_server_request_request_completed)

	status_timer.wait_time = status_update_interval
	status_timer.timeout.connect(_on_status_timer_timeout)
	add_child(status_timer)

func _process(_delta: float) -> void:
	pass

func queue_for_match():
	if not queued:
		var url = server_url + "matchmaking/queue"
		
		var headers = ["Content-Type: application/json"]
		var body = JSON.stringify({"sessionToken": Local.get_state("session_token")})
		queue_request.request(url, headers, HTTPClient.METHOD_POST, body)
	else:
		print("Already queued for match")

func _on_queue_request_request_completed(_result, response_code, _headers, _body) -> void:
	if response_code >= 200 and response_code < 300:
		print("Response from queue request: %s" % response_code)
		queued = true
		var json_response = JSON.parse_string(_body.get_string_from_utf8())
		status_timer.start()
		emit_signal("matchmaking_status_changed", "searching")
		print("Response from queue request: %s" % json_response)
		Local.set_state("matchmaking_ticket", json_response["ticketId"])
	else:
		print("Failed to queue for match, response code: %d" % response_code)

func _on_status_update_request_request_completed(_result, response_code, _headers, _body) -> void:
	if response_code >= 200 and response_code < 300:
		var status = JSON.parse_string(_body.get_string_from_utf8())
		if Local.get_state("matchmaking_status") != status["status"]:
			emit_signal("matchmaking_status_changed", status["status"])
		Local.set_state("matchmaking_status", status["status"])
		print("Current matchmaking status: %s" % Local.get_state("matchmaking_status"))
		if Local.get_state("matchmaking_status") == "matched":
			status_timer.stop()
			queued = false
			var port = int(status["port"])
			print("PORT:", port)
			var ip = "209.38.77.226"
			emit_signal("match_found", port, ip)
		
	else:
		print("Failed to get matchmaking status, response code: %d" % response_code)

func _on_status_timer_timeout() -> void:
	var url = server_url + "matchmaking/status"
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({"sessionToken": Local.get_state("session_token"), "ticketId": Local.get_state("matchmaking_ticket")})
	status_update_request.request(url, headers, HTTPClient.METHOD_POST, body)

func party_invite(player_id: String):
	var url = server_url + "matchmaking/party/invite"
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({"sessionToken": Local.get_state("session_token"), "playerId": player_id})
	party_invite_request.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_party_invite_request_request_completed(_result, response_code, _headers, _body) -> void:
	if response_code >= 200 and response_code < 300:
		print("Party invite sent successfully")
	else:
		print("Failed to send party invite, response code: %d" % response_code)

func party_status():
	var encoded_session_token = String(Local.get_state("session_token")).uri_encode()
	var url = server_url + "matchmaking/party/status?sessionToken=" + encoded_session_token
	party_status_request.request(url, [], HTTPClient.METHOD_GET)

func _on_party_status_request_request_completed(_result, response_code, _headers, _body) -> void:
	if response_code >= 200 and response_code < 300:
		var status = JSON.parse_string(_body.get_string_from_utf8())

		if status.has("inboundInvites"):
			print(status["inboundInvites"])
			Local.set_state("party_invites", status["inboundInvites"])
		if status.has("members"):
			print("[Party Members] ", status["members"])
			if len(status["members"]) > 0:
				Local.set_state("in_party", true)
				if status_timer.is_stopped():
					status_timer.start()
			else:
				Local.set_state("in_party", false)
			Local.set_state("party_members", status["members"])
			var party_member_names = []
			for member in Local.get_state("party_members"):
				party_member_names.append(member["username"])
			emit_signal("in_party_status_changed", Local.get_state("party_members"))
		if status.has("status"):
			Local.set_state("party_status", status["status"])
		if status.has("primaryPlayerId"):
			Local.set_state("party_leader_id", status["primaryPlayerId"])
			if Local.get_state("party_leader_id") == Local.get_state("player_id"):
				Local.set_state("party_leader", true)
			else:
				Local.set_state("party_leader", false)
		if status.has("partyFaction"):
			emit_signal("party_faction_updated", status["partyFaction"])
			print("[ACTIVE PARTY] ", status["partyFaction"])
		print("Current party status: %s" % Local.get_state("party_status"))
	else:
		print("Failed to retrieve party status, response code: %d" % response_code)

func party_leave():
	var url = server_url + "matchmaking/party/leave"
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({"sessionToken": Local.get_state("session_token")})
	party_leave_request.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_party_leave_request_request_completed(_result, response_code, _headers, _body) -> void:
	if response_code >= 200 and response_code < 300:
		print("Left party successfully")
	else:
		print("Failed to leave party, response code: %d" % response_code)

func party_response(invite_id: String, accept: bool):
	var url = server_url + "matchmaking/party/respond"
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({"sessionToken": Local.get_state("session_token"), "inviteId": invite_id, "accept": accept})
	party_response_request.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_party_response_request_request_completed(_result, response_code, _headers, _body) -> void:
	if response_code >= 200 and response_code < 300:
		print("Party response sent successfully")
	else:
		print("Failed to send party response, response code: %d" % response_code)

func send_match_heartbeat():
	var url = server_url + "matchmaking/heartbeat"
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({"sessionToken": Local.get_state("session_token")})
	match_heartbeat_request.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_match_heartbeat_request_request_completed(_result, response_code, _headers, _body) -> void:
	if response_code >= 200 and response_code < 300:
		print("Match heartbeat sent successfully")
	else:
		print("Failed to send match heartbeat, response code: %d" % response_code)

func leave_match():
	var url = server_url + "matchmaking/left"
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({"sessionToken": Local.get_state("session_token")})
	# Attach to root so the request survives scene changes (e.g. _exit_tree or change_scene_to_file)
	var req := HTTPRequest.new()
	get_tree().root.add_child(req)
	req.request_completed.connect(func(_result, response_code, _headers, _body):
		if response_code >= 200 and response_code < 300:
			print("Left match successfully")
		else:
			print("Failed to leave match, response code: %d" % response_code)
		req.queue_free()
	)
	req.request(url, headers, HTTPClient.METHOD_POST, body)

func joined_match():
	var url = server_url + "matchmaking/joined"
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({"sessionToken": Local.get_state("session_token"), "ticketId": Local.get_state("matchmaking_ticket")})
	joined_match_request.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_joined_match_request_request_completed(_result, response_code, _headers, _body) -> void:
	if response_code >= 200 and response_code < 300:
		print("Joined match successfully")
	else:
		print("Failed to join match, response code: %d" % response_code)

func match_ended():
	var url = server_url + "matchmaking/match/ended"
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({"serverToken": Local.get_state("server_token")})
	match_ended_request.request(url, headers, HTTPClient.METHOD_POST, body)

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
