extends Control

@onready var inventory_panel = $UI/InventoryPanel/VBoxContainer
@onready var task_panel = $UI/TaskPanel/VBoxContainer
@onready var progress_bar = $UI/CurrentTaskPanel/VBoxContainer/ProgressBar
@onready var current_task_label = $UI/CurrentTaskPanel/VBoxContainer/Label

var active_tree: Node = null

func _ready():
	InventoryManager.inventory_changed.connect(_on_inventory_changed)

	# Create a dummy TaskTree for testing safely
	var mining_tree = load("res://TaskTree.tscn").instantiate()
	if is_instance_valid(mining_tree):
		mining_tree.name = "MiningTree"
		add_child(mining_tree)
		active_tree = mining_tree

		# Create dummy tasks
		var gather_wood = Task.new()
		gather_wood.task_id = "gather_wood"
		gather_wood.task_name = "Gather Wood"
		gather_wood.description = "Collect wood from the forest."
		gather_wood.cycle_time = 5
		gather_wood.output_items = {"wood": 1}

		var craft_planks = Task.new()
		craft_planks.task_id = "craft_planks"
		craft_planks.task_name = "Craft Planks"
		craft_planks.description = "Craft wood into planks."
		craft_planks.cycle_time = 10
		craft_planks.input_items = {"wood": 2}
		craft_planks.output_items = {"planks": 1}

		# Defensive array assignment to avoid typing conflicts in GDScript 4
		var tasks: Array[Task] = []
		tasks.append(gather_wood)
		tasks.append(craft_planks)
		mining_tree.available_tasks = tasks

		mining_tree.task_started.connect(_on_task_started)
		mining_tree.task_completed.connect(_on_task_completed)
		mining_tree.task_progressed.connect(_on_task_progressed)

		_populate_task_list()

	# Connect time signals defensively
	if not TimeManager.time_synced.is_connected(_on_time_synced):
		TimeManager.time_synced.connect(_on_time_synced)
	if not TimeManager.time_sync_failed.is_connected(_on_time_sync_failed):
		TimeManager.time_sync_failed.connect(_on_time_sync_failed)

func _on_time_synced(time):
	SaveManager.load_game()
	if is_instance_valid(active_tree) and active_tree.has_method("process_offline_progress"):
		active_tree.process_offline_progress()

func _on_time_sync_failed():
	print("Time sync failed. Loading save without offline progress.")
	SaveManager.load_game()
	if is_instance_valid(active_tree) and SaveManager.current_task_id != "":
		active_tree.start_task(SaveManager.current_task_id)

func _populate_task_list():
	if not is_instance_valid(task_panel):
		return

	# Keep the title and separator, remove only old buttons
	for child in task_panel.get_children():
		if child is Button:
			child.queue_free()

	if not is_instance_valid(active_tree):
		return

	for task in active_tree.available_tasks:
		if is_instance_valid(task):
			var btn = Button.new()
			btn.text = str(task.task_name) + " (" + str(task.cycle_time) + "s)"

			# Build tooltip text to show task details
			var tooltip = str(task.description)
			if not task.input_items.is_empty():
				tooltip += "\n\nRequires:"
				for item in task.input_items:
					tooltip += "\n- " + str(item).capitalize() + ": " + str(task.input_items[item])
			if not task.output_items.is_empty():
				tooltip += "\n\nYields:"
				for item in task.output_items:
					tooltip += "\n- " + str(item).capitalize() + ": " + str(task.output_items[item])
			btn.tooltip_text = tooltip

			# Using bind carefully
			btn.pressed.connect(func(t_id=task.task_id):
				if is_instance_valid(active_tree):
					active_tree.start_task(t_id)
			)
			task_panel.add_child(btn)

func _on_inventory_changed():
	if not is_instance_valid(inventory_panel):
		return

	# Clear old items, keep headers
	for child in inventory_panel.get_children():
		if child is Label and child.name != "Title":
			child.queue_free()

	var items = InventoryManager.get_all_items()
	for item_id in items:
		var lbl = Label.new()
		lbl.name = "Item_" + item_id
		lbl.text = str(item_id).capitalize() + ": " + str(items[item_id])
		lbl.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
		inventory_panel.add_child(lbl)

func _on_task_started(task: Task):
	if is_instance_valid(current_task_label) and is_instance_valid(task):
		current_task_label.text = "Working on: " + str(task.task_name)

func _on_task_completed(task: Task, cycles: int):
	if is_instance_valid(task):
		print("Completed ", cycles, " of ", task.task_name)

func _on_task_progressed(progress: float):
	if is_instance_valid(progress_bar):
		progress_bar.value = progress * 100
