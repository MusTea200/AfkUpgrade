extends Control

@onready var inventory_panel = $UI/InventoryPanel/VBoxContainer
@onready var task_panel = $UI/TaskPanel/VBoxContainer
@onready var progress_bar = $UI/CurrentTaskPanel/ProgressBar
@onready var current_task_label = $UI/CurrentTaskPanel/Label

var active_tree: Node = null

func _ready():
	InventoryManager.inventory_changed.connect(_on_inventory_changed)

	# Create a dummy TaskTree for testing
	var mining_tree = load("res://TaskTree.tscn").instantiate()
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

	mining_tree.available_tasks = [gather_wood, craft_planks]

	mining_tree.task_started.connect(_on_task_started)
	mining_tree.task_completed.connect(_on_task_completed)
	mining_tree.task_progressed.connect(_on_task_progressed)

	_populate_task_list()

	TimeManager.time_synced.connect(_on_time_synced)

func _on_time_synced(time):
	SaveManager.load_game()
	if active_tree:
		active_tree.process_offline_progress()

func _populate_task_list():
	for child in task_panel.get_children():
		child.queue_free()

	if not active_tree:
		return

	for task in active_tree.available_tasks:
		var btn = Button.new()
		btn.text = task.task_name + " (" + str(task.cycle_time) + "s)"
		btn.pressed.connect(func(): active_tree.start_task(task.task_id))
		task_panel.add_child(btn)

func _on_inventory_changed():
	for child in inventory_panel.get_children():
		child.queue_free()

	var items = InventoryManager.get_all_items()
	for item_id in items:
		var lbl = Label.new()
		lbl.text = item_id.capitalize() + ": " + str(items[item_id])
		# Modern paper styling
		lbl.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
		inventory_panel.add_child(lbl)

func _on_task_started(task: Task):
	current_task_label.text = "Working on: " + task.task_name

func _on_task_completed(task: Task, cycles: int):
	print("Completed ", cycles, " of ", task.task_name)

func _on_task_progressed(progress: float):
	progress_bar.value = progress * 100
