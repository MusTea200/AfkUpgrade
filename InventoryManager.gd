extends Node

signal inventory_changed

# Dictionary to store item quantities. Key: String (item_id), Value: int (quantity)
var items: Dictionary = {}

func add_item(item_id: String, amount: int, silent: bool = false) -> void:
	if items.has(item_id):
		items[item_id] += amount
	else:
		items[item_id] = amount

	if not silent:
		inventory_changed.emit()
		print("Added ", amount, " of ", item_id, ". Total: ", items[item_id])

func remove_item(item_id: String, amount: int, silent: bool = false) -> bool:
	if items.has(item_id) and items[item_id] >= amount:
		items[item_id] -= amount
		if items[item_id] <= 0:
			items.erase(item_id)

		if not silent:
			inventory_changed.emit()
			print("Removed ", amount, " of ", item_id, ".")
		return true

	if not silent:
		print("Not enough ", item_id, " to remove.")
	return false

func has_item(item_id: String, amount: int) -> bool:
	return items.has(item_id) and items[item_id] >= amount

func get_item_count(item_id: String) -> int:
	if items.has(item_id):
		return items[item_id]
	return 0

func get_all_items() -> Dictionary:
	return items

func load_inventory(data: Dictionary) -> void:
	items = data
	inventory_changed.emit()
