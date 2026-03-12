extends Node

var queued: bool = false

signal match_found(port: int, ip: String)

var queue_request: HTTPRequest = HTTPRequest.new()
var status_update_request: HTTPRequest = HTTPRequest.new()

var status_timer: Timer = Timer.new()
var status_update_interval: float = 1.0

func _ready() -> void:
	add_child(queue_request)
	queue_request.request_completed.connect(_on_queue_request_request_completed)
	
	add_child(status_update_request)
	status_update_request.request_completed.connect(_on_status_update_request_request_completed)

	status_timer.wait_time = status_update_interval
	status_timer.timeout.connect(_on_status_timer_timeout)
	add_child(status_timer)

func _process(_delta: float) -> void:
	pass

func queue_for_match():
	if not queued:
		var url = "http://localhost:8000/matchmaking/queue"
		
		var headers = ["Content-Type: application/json"]
		var body = JSON.stringify({"sessionToken": Local.session_token})
		queue_request.request(url, headers, HTTPClient.METHOD_POST, body)
	else:
		print("Already queued for match")

func _on_queue_request_request_completed(_result, response_code, _headers, _body) -> void:
	if response_code >= 200 and response_code < 300:
		print("Response from queue request: %s" % response_code)
		queued = true
		var json_response = JSON.parse_string(_body.get_string_from_utf8())
		status_timer.start()
		print("Response from queue request: %s" % json_response)
		Local.matchmaking_ticket = json_response["ticketId"]
	else:
		print("Failed to queue for match, response code: %d" % response_code)

func _on_status_update_request_request_completed(_result, response_code, _headers, _body) -> void:
	if response_code >= 200 and response_code < 300:
		var status = JSON.parse_string(_body.get_string_from_utf8())
		Local.matchmaking_status = status["status"]
		print("Current matchmaking status: %s" % Local.matchmaking_status)
		if Local.matchmaking_status == "matched":
			status_timer.stop()
			queued = false
			var port = int(status["port"])
			var ip = "127.0.0.1"
			emit_signal("match_found", port, ip)
		
	else:
		print("Failed to get matchmaking status, response code: %d" % response_code)

func _on_status_timer_timeout() -> void:
	if queued:
		var url = "http://localhost:8000/matchmaking/status"
		var headers = ["Content-Type: application/json"]
		var body = JSON.stringify({"sessionToken": Local.session_token, "ticketId": Local.matchmaking_ticket})
		status_update_request.request(url, headers, HTTPClient.METHOD_POST, body)
		status_timer.start()
