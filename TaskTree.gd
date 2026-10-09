extends Node

signal task_started(task: Task)
signal task_completed(task: Task, cycles: int)
signal task_progressed(progress: float)

@export var available_tasks: Array[Task] = []
var active_task: Task = null
var _task_timer: Timer

func _ready():
	_task_timer = Timer.new()
	_task_timer.one_shot = false
	add_child(_task_timer)
	if not _task_timer.timeout.is_connected(_on_task_cycle_complete):
		_task_timer.timeout.connect(_on_task_cycle_complete)

func start_task(task_id: String):
	if is_instance_valid(active_task):
		stop_task()

	for task in available_tasks:
		if is_instance_valid(task) and task.task_id == task_id:
			if task.can_start():
				active_task = task
				SaveManager.current_task_id = task_id
				SaveManager.task_start_time = TimeManager.get_current_time()

				for item in active_task.input_items:
					InventoryManager.remove_item(item, active_task.input_items[item])

				if is_instance_valid(_task_timer):
					_task_timer.start(active_task.cycle_time)

				task_started.emit(active_task)
				print("Started task: ", active_task.task_name)
			else:
				print("Cannot start task: Not enough resources.")
			return

func stop_task():
	if is_instance_valid(active_task):
		if is_instance_valid(_task_timer) and not _task_timer.is_stopped() and _task_timer.time_left > 0:
			for item in active_task.input_items:
				InventoryManager.add_item(item, active_task.input_items[item])

		if is_instance_valid(_task_timer):
			_task_timer.stop()

		print("Stopped task: ", active_task.task_name)
		active_task = null
		SaveManager.current_task_id = ""
		SaveManager.task_start_time = 0

func _on_task_cycle_complete():
	if not is_instance_valid(active_task):
		return

	for item in active_task.output_items:
		InventoryManager.add_item(item, active_task.output_items[item])

	task_completed.emit(active_task, 1)
	SaveManager.task_start_time = TimeManager.get_current_time()

	if not active_task.can_start():
		print("Task stopped: Not enough resources for next cycle.")
		active_task = null
		SaveManager.current_task_id = ""
		SaveManager.task_start_time = 0
		if is_instance_valid(_task_timer):
			_task_timer.stop()
		return

	for item in active_task.input_items:
		InventoryManager.remove_item(item, active_task.input_items[item])

func process_offline_progress():
	if SaveManager.current_task_id == "" or SaveManager.task_start_time == 0:
		return

	var task_to_resume: Task = null
	for t in available_tasks:
		if is_instance_valid(t) and t.task_id == SaveManager.current_task_id:
			task_to_resume = t
			break

	if not is_instance_valid(task_to_resume):
		return

	var current_time = TimeManager.get_current_time()
	if current_time == 0:
		return

	var elapsed_time = current_time - SaveManager.task_start_time
	var max_time_remaining = task_to_resume.max_duration
	elapsed_time = min(elapsed_time, max_time_remaining)

	if elapsed_time <= 0:
		return

	var cycles_completed = int(elapsed_time / task_to_resume.cycle_time)

	if cycles_completed > 0:
		var actual_cycles = 1
		for item in task_to_resume.output_items:
			InventoryManager.add_item(item, task_to_resume.output_items[item], true)

		for i in range(1, cycles_completed):
			if task_to_resume.can_start():
				for item in task_to_resume.input_items:
					InventoryManager.remove_item(item, task_to_resume.input_items[item], true)
				for item in task_to_resume.output_items:
					InventoryManager.add_item(item, task_to_resume.output_items[item], true)
				actual_cycles += 1
			else:
				print("Ran out of inputs during offline calculation after ", actual_cycles, " cycles.")
				break

		task_completed.emit(task_to_resume, actual_cycles)

		if task_to_resume.can_start():
			var leftover_time = elapsed_time % task_to_resume.cycle_time
			for item in task_to_resume.input_items:
				InventoryManager.remove_item(item, task_to_resume.input_items[item], true)

			active_task = task_to_resume
			SaveManager.current_task_id = active_task.task_id
			SaveManager.task_start_time = TimeManager.get_current_time() - leftover_time

			if is_instance_valid(_task_timer):
				_task_timer.start(active_task.cycle_time - leftover_time)

			task_started.emit(active_task)
			print("Resumed task: ", active_task.task_name)
		else:
			SaveManager.current_task_id = ""
			SaveManager.task_start_time = 0
	else:
		active_task = task_to_resume
		SaveManager.current_task_id = active_task.task_id

		if is_instance_valid(_task_timer):
			_task_timer.start(task_to_resume.cycle_time - elapsed_time)

		task_started.emit(active_task)
		print("Resumed task: ", active_task.task_name, " (partial cycle)")

	InventoryManager.emit_inventory_changed()

func _process(delta):
	if is_instance_valid(active_task) and is_instance_valid(_task_timer) and not _task_timer.is_stopped():
		var progress = 1.0 - (_task_timer.time_left / _task_timer.wait_time)
		task_progressed.emit(progress)
