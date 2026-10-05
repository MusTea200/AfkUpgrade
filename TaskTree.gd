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
	_task_timer.timeout.connect(_on_task_cycle_complete)

func start_task(task_id: String):
	if active_task != null:
		stop_task()

	for task in available_tasks:
		if task.task_id == task_id:
			if task.can_start():
				active_task = task
				SaveManager.current_task_id = task_id
				SaveManager.task_start_time = TimeManager.get_current_time()

				# Deduct initial inputs if any (this is per cycle in real implementation, but for simplicity here)
				for item in active_task.input_items:
					InventoryManager.remove_item(item, active_task.input_items[item])

				_task_timer.start(active_task.cycle_time)
				task_started.emit(active_task)
				print("Started task: ", active_task.task_name)
			else:
				print("Cannot start task: Not enough resources.")
			return

func stop_task():
	if active_task:
		# Refund items if a cycle was interrupted
		if not _task_timer.is_stopped() and _task_timer.time_left > 0:
			for item in active_task.input_items:
				InventoryManager.add_item(item, active_task.input_items[item])

		_task_timer.stop()
		print("Stopped task: ", active_task.task_name)
		active_task = null
		SaveManager.current_task_id = ""
		SaveManager.task_start_time = 0

func _on_task_cycle_complete():
	if not active_task:
		return

	# 1. Give outputs for the cycle that just completed
	for item in active_task.output_items:
		InventoryManager.add_item(item, active_task.output_items[item])

	task_completed.emit(active_task, 1)

	# Fix: Advance the task_start_time so that leaving the game online
	# then going offline doesn't re-calculate rewards for the online portion.
	SaveManager.task_start_time = TimeManager.get_current_time()

	# 2. Check if we have enough inputs for the next cycle
	if not active_task.can_start():
		print("Task stopped: Not enough resources for next cycle.")
		active_task = null
		SaveManager.current_task_id = ""
		SaveManager.task_start_time = 0
		_task_timer.stop()
		return

	# 3. Deduct inputs for the NEXT cycle
	for item in active_task.input_items:
		InventoryManager.remove_item(item, active_task.input_items[item])

func process_offline_progress():
	if SaveManager.current_task_id == "" or SaveManager.task_start_time == 0:
		return

	var task_to_resume: Task = null
	for t in available_tasks:
		if t.task_id == SaveManager.current_task_id:
			task_to_resume = t
			break

	if not task_to_resume:
		return

	var current_time = TimeManager.get_current_time()
	if current_time == 0:
		return

	var elapsed_time = current_time - SaveManager.task_start_time

	# Cap the time at max_duration (e.g., 24 hours)
	var max_time_remaining = task_to_resume.max_duration
	elapsed_time = min(elapsed_time, max_time_remaining)

	if elapsed_time <= 0:
		return

	# Because start_task deducted inputs for the first cycle, we assume at least one cycle was running.
	# Let's completely recalculate based on total time elapsed since task started.

	var cycles_completed = int(elapsed_time / task_to_resume.cycle_time)

	# The first cycle's inputs were already deducted when the task started.
	# We process the first cycle completion:
	if cycles_completed > 0:
		var actual_cycles = 1 # first cycle
		for item in task_to_resume.output_items:
			InventoryManager.add_item(item, task_to_resume.output_items[item])

		# Process remaining cycles
		for i in range(1, cycles_completed):
			if task_to_resume.can_start():
				for item in task_to_resume.input_items:
					InventoryManager.remove_item(item, task_to_resume.input_items[item])
				for item in task_to_resume.output_items:
					InventoryManager.add_item(item, task_to_resume.output_items[item])
				actual_cycles += 1
			else:
				print("Ran out of inputs during offline calculation after ", actual_cycles, " cycles.")
				break

		task_completed.emit(task_to_resume, actual_cycles)

		# Resume if we still can
		if task_to_resume.can_start():
			# Keep track of fractional time left for the next cycle
			var leftover_time = elapsed_time % task_to_resume.cycle_time

			# Deduct for the newly started cycle
			for item in task_to_resume.input_items:
				InventoryManager.remove_item(item, task_to_resume.input_items[item])

			active_task = task_to_resume
			SaveManager.current_task_id = active_task.task_id
			# Set start time considering the leftover fractional progress
			SaveManager.task_start_time = TimeManager.get_current_time() - leftover_time
			_task_timer.start(active_task.cycle_time - leftover_time)
			task_started.emit(active_task)
			print("Resumed task: ", active_task.task_name)
		else:
			SaveManager.current_task_id = ""
			SaveManager.task_start_time = 0
	else:
		# Didn't even finish 1 cycle offline, resume it with elapsed time
		active_task = task_to_resume
		SaveManager.current_task_id = active_task.task_id

		# We don't deduct inputs here because they were deducted before they went offline
		# We just fast forward the timer.
		_task_timer.start(task_to_resume.cycle_time - elapsed_time)
		task_started.emit(active_task)
		print("Resumed task: ", active_task.task_name, " (partial cycle)")

func _process(delta):
	if active_task and not _task_timer.is_stopped():
		var progress = 1.0 - (_task_timer.time_left / _task_timer.wait_time)
		task_progressed.emit(progress)
