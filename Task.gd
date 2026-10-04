extends Resource
class_name Task

@export var task_id: String = ""
@export var task_name: String = "New Task"
@export_multiline var description: String = ""

# Time required to complete one cycle in seconds
@export var cycle_time: int = 60

# Maximum duration a task can run (e.g., 24 hours = 86400 seconds)
@export var max_duration: int = 86400

# Dictionary of required items { "item_id": amount }
@export var input_items: Dictionary = {}

# Dictionary of items yielded per cycle { "item_id": amount }
@export var output_items: Dictionary = {}

func can_start() -> bool:
	for item_id in input_items:
		if not InventoryManager.has_item(item_id, input_items[item_id]):
			return false
	return true
