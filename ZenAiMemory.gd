extends Node

var journal_memory: Array = []

func add_entry(entry: Dictionary) -> void:
	if entry.has("title") and entry.has("content"):
		journal_memory.append(entry)
		print("🧠 ZenAi memory updated (%d entries)" % journal_memory.size())
	else:
		push_warning("⚠️ Invalid journal entry format")

func get_recent_entries(limit := 5) -> Array:
	if journal_memory.is_empty():
		return []
	return journal_memory.slice(-limit, journal_memory.size())
