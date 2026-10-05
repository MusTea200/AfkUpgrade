extends Node

var current_online_time: int = 0
var last_sync_time: int = 0
var is_time_synced: bool = false
signal time_synced(online_time)
signal time_sync_failed()

var http_request: HTTPRequest

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	sync_time()

func sync_time():
	# Use HTTPS to avoid cleartext HTTP restrictions on Android 9+
	var error = http_request.request("https://worldtimeapi.org/api/timezone/Etc/UTC")
	if error != OK:
		print("An error occurred in the HTTP request.")
		time_sync_failed.emit()

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("unixtime"):
			current_online_time = json["unixtime"]
			last_sync_time = Time.get_ticks_msec()
			is_time_synced = true
			time_synced.emit(current_online_time)
			print("Time synced: ", current_online_time)
		else:
			print("Failed to parse time JSON")
			time_sync_failed.emit()
	else:
		print("Failed to sync time. Response code: ", response_code)
		time_sync_failed.emit()

func get_current_time() -> int:
	if not is_time_synced:
		return 0 # Or fallback to OS time, but we want to avoid manipulation
	var elapsed_seconds = (Time.get_ticks_msec() - last_sync_time) / 1000
	return current_online_time + elapsed_seconds
