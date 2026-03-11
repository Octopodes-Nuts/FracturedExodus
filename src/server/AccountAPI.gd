extends Node

signal login_complete
signal characters_received

func _ready():
	pass

func login(username: String, password: String):

	var request = HTTPRequest.new()
	add_child(request)

	request.request_completed.connect(_on_login_request_completed)

	var url = "http://127.0.0.1:8000/player/login"
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

	var url = "http://127.0.0.1:8000/player/characters"
	var body = {"sessionToken": token}
	var json_body = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]
	var err = request.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		print("Error making get_characters request: ", err)

func _on_get_characters_request_complete(_result, response_code, _headers, body):
	if response_code == 200:
		var response = JSON.parse_string(body.get_string_from_utf8())
		
		print("characters: ", response)
		
		emit_signal("characters_received")
	else:
		print("Characters request failed with code: ", response_code)
