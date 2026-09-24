extends Node

###############################################################
# ServerConnection
#
# Owns a single persistent WebSocketPeer used for all player-facing
# traffic (account + matchmaking). Replaces the old per-call HTTPRequest
# pattern with one shared connection so the server can push state
# changes (matchmaking/party updates, account info changes) instead of
# the client having to poll for them.
#
# Connects lazily on the first send_request()/send_message() call, not
# in _ready(), so headless dedicated-server exports (which load every
# autoload but never log in) never open a socket.
###############################################################

## reqId(String), type(String), ok(bool), payload(Variant), error(String)
signal response_received(reqId: String, type: String, ok: bool, payload: Variant, error: String)
## type(String), payload(Variant)
signal push_received(type: String, payload: Variant)
## Mirrors WebSocketPeer.State values (STATE_CONNECTING/STATE_OPEN/STATE_CLOSING/STATE_CLOSED)
signal connection_state_changed(state: int)

const RECONNECT_MIN_DELAY_SEC: float = 1.0
const RECONNECT_MAX_DELAY_SEC: float = 15.0
const REQUEST_TIMEOUT_SEC: float = 10.0

var _peer: WebSocketPeer = WebSocketPeer.new()
var _should_connect: bool = false
var _last_state: int = WebSocketPeer.STATE_CLOSED

var _reconnect_delay_sec: float = RECONNECT_MIN_DELAY_SEC
var _next_reconnect_at_ms: int = 0

var _req_counter: int = 0
var _outbound_queue: Array = []
var _pending_requests: Dictionary = {} # reqId -> {"type": String, "sent_at": int (ms)}

# reqId of the in-flight account.authenticate sent for reconnect resync, if any.
var _resync_auth_req_id: String = ""


func _ready() -> void:
	# Must keep polling/reconnecting even while the game tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS


func send_request(type: String, payload: Dictionary) -> String:
	_ensure_connecting()
	_req_counter += 1
	var req_id := "c-%d" % _req_counter
	_pending_requests[req_id] = {"type": type, "sent_at": Time.get_ticks_msec()}
	_dispatch_or_queue({"type": type, "reqId": req_id, "payload": payload})
	return req_id


func send_message(type: String, payload: Dictionary) -> void:
	_ensure_connecting()
	_dispatch_or_queue({"type": type, "payload": payload})


func _ensure_connecting() -> void:
	if _should_connect:
		return
	_should_connect = true
	_open_socket()


func _open_socket() -> void:
	var url := "ws://" + Local.server_ip + ":" + Local.server_port + "/ws"
	var err := _peer.connect_to_url(url)
	if err != OK:
		push_warning("[ServerConnection] connect_to_url failed with error %d" % err)
	_last_state = _peer.get_ready_state()


func _dispatch_or_queue(envelope: Dictionary) -> void:
	if _peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_send_envelope(envelope)
	else:
		_outbound_queue.append(envelope)


func _send_envelope(envelope: Dictionary) -> void:
	_peer.send_text(JSON.stringify(envelope))


func _flush_outbound_queue() -> void:
	if _outbound_queue.is_empty():
		return
	var pending := _outbound_queue
	_outbound_queue = []
	for envelope in pending:
		_send_envelope(envelope)


func _process(_delta: float) -> void:
	if not _should_connect:
		return

	_peer.poll()
	var state := _peer.get_ready_state()
	if state != _last_state:
		_last_state = state
		emit_signal("connection_state_changed", state)
		if state == WebSocketPeer.STATE_OPEN:
			_reconnect_delay_sec = RECONNECT_MIN_DELAY_SEC
			_next_reconnect_at_ms = 0
			_flush_outbound_queue()
			_on_socket_opened()

	while _peer.get_available_packet_count() > 0:
		var packet: PackedByteArray = _peer.get_packet()
		var text := packet.get_string_from_utf8()
		var parsed = JSON.parse_string(text)
		if typeof(parsed) != TYPE_DICTIONARY:
			push_warning("[ServerConnection] Ignoring malformed message: %s" % text)
			continue
		_dispatch_incoming(parsed)

	if state == WebSocketPeer.STATE_CLOSED:
		var now := Time.get_ticks_msec()
		if _next_reconnect_at_ms == 0:
			_next_reconnect_at_ms = now + int(_reconnect_delay_sec * 1000.0)
		elif now >= _next_reconnect_at_ms:
			_next_reconnect_at_ms = 0
			_reconnect_delay_sec = min(_reconnect_delay_sec * 2.0, RECONNECT_MAX_DELAY_SEC)
			_open_socket()

	_check_request_timeouts()


func _dispatch_incoming(data: Dictionary) -> void:
	var type: String = data.get("type", "")
	var payload = data.get("payload")
	if data.has("reqId"):
		var req_id: String = data["reqId"]
		var ok: bool = data.get("ok", false)
		var error: String = data.get("error", "")
		_pending_requests.erase(req_id)
		if req_id == _resync_auth_req_id:
			_resync_auth_req_id = ""
			if ok:
				_pull_resync_state()
		emit_signal("response_received", req_id, type, ok, payload, error)
	else:
		emit_signal("push_received", type, payload)


func _check_request_timeouts() -> void:
	if _pending_requests.is_empty():
		return
	var now := Time.get_ticks_msec()
	var timeout_ms := int(REQUEST_TIMEOUT_SEC * 1000.0)
	var timed_out: Array = []
	for req_id in _pending_requests.keys():
		var info: Dictionary = _pending_requests[req_id]
		if now - int(info["sent_at"]) >= timeout_ms:
			timed_out.append(req_id)
	for req_id in timed_out:
		var info: Dictionary = _pending_requests[req_id]
		_pending_requests.erase(req_id)
		emit_signal("response_received", req_id, info["type"], false, null, "timeout")


func _on_socket_opened() -> void:
	# Reconnect resync: rebind the connection to the existing session (if any)
	# without a full login, then re-pull state that may have changed while
	# disconnected instead of waiting on a push that could have been missed.
	var session_token = Local.get_state("session_token")
	if session_token != null and String(session_token) != "":
		_resync_auth_req_id = send_request("account.authenticate", {"sessionToken": session_token})


func _pull_resync_state() -> void:
	send_request("matchmaking.party.status", {})
	send_request("matchmaking.status", {})
