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

func add_journal(title: String, text: String) -> void:
	var now = Time.get_datetime_dict_from_system()
	var months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
	
	var new_journal = {
		"id": str(Time.get_unix_time_from_system()), # Always string
		"title": title,
		"text": text,
		"date": str(months[now.month - 1]) + " " + str(now.day) + ", " + str(now.year) \
				+ " " + str(now.hour) + ":" + str(now.minute).pad_zeros(2)
	}
	journals.append(new_journal)
	save_journals()

# Get a journal by ID (string-based lookup)
func get_journal(id: String) -> Dictionary:
	for j in journals:
		if j["id"] == id:
			return j
	return {}

# Delete a journal by ID
func delete_journal(id: String) -> bool:
	for i in range(journals.size()):
		if journals[i]["id"] == id:
			journals.remove_at(i)
			save_journals()
			return true
	return false
