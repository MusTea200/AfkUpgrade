extends Node

const SAVE_FILE = "user://save_game.json"

var current_task_id: String = ""
var task_start_time: int = 0
var last_disconnect_time: int = 0

func _ready():
	# Allow saving when the app is closed/quits
	# Note: NOTIFICATION_WM_CLOSE_REQUEST might be needed depending on OS
	pass

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		save_game()

func save_game():
	var save_data = {
		"inventory": InventoryManager.get_all_items(),
		"current_task_id": current_task_id,
		"task_start_time": task_start_time,
		"last_disconnect_time": TimeManager.get_current_time()
	}

	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data)
		file.store_line(json_string)
		print("Game saved successfully.")
	else:
		print("Error opening save file for writing.")

func load_game():
	if not FileAccess.file_exists(SAVE_FILE):
		print("No save file found.")
		return false

	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data = json.get_data()
			if data.has("inventory"):
				InventoryManager.load_inventory(data["inventory"])
			if data.has("current_task_id"):
				current_task_id = data["current_task_id"]
			if data.has("task_start_time"):
				task_start_time = data["task_start_time"]
			if data.has("last_disconnect_time"):
				last_disconnect_time = data["last_disconnect_time"]
			print("Game loaded successfully.")
			return true
		else:
			print("JSON Parse Error: ", json.get_error_message())
	return false

func process_afk_time():
	if current_task_id == "" or task_start_time == 0:
		return

	var current_time = TimeManager.get_current_time()
	if current_time == 0:
		return # Time not synced yet

	var elapsed_since_start = current_time - task_start_time
	print("AFK time processed: ", elapsed_since_start, " seconds elapsed on task ", current_task_id)

	# The actual task manager will use this info to calculate yields
