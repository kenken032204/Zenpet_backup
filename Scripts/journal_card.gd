extends Node

var journals: Array = []

# Save journals to user://
func save_journals():
	var file = FileAccess.open("user://journals.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(journals))
		file.close()

# Load journals from user://
func load_journals():
	if FileAccess.file_exists("user://journals.json"):
		var file = FileAccess.open("user://journals.json", FileAccess.READ)
		if file:
			var data = JSON.parse_string(file.get_as_text())
			if typeof(data) == TYPE_ARRAY:
				journals = data
		file.close()

# Add a new journal
func add_journal(title: String, text: String):
	var journal = {
		"id": journals.size() + 1,
		"date": Time.get_datetime_string_from_system(),
		"title": title,
		"text": text
	}
	journals.append(journal)
	save_journals()

# Get a journal by ID
func get_journal(id: int) -> Dictionary:
	for j in journals:
		if j["id"] == id:
			return j
	return {}
