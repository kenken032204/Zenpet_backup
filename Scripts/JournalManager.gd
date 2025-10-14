extends Node


var journals: Array = []
signal journal_saved(journal_text: String, journal_id: String)
var last_journal: Dictionary = {}

func _ready():
	print("🟢 JournalManager ready")
	load_journals_from_supabase()

func save_journals():
	var file = FileAccess.open("user://journals.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(journals))
		file.close()

func load_journals_from_supabase():
	var url = "https://rekmhywernuqjshghyvu.supabase.co/rest/v1/journals?select=*"
	var headers = [
		"apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
		"Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
		"Content-Type: application/json"
	]

	var http := HTTPRequest.new()
	add_child(http)

	http.request_completed.connect(func(result, response_code, headers, body):
		if response_code == 200:
			var data = JSON.parse_string(body.get_string_from_utf8())
			if typeof(data) == TYPE_ARRAY:
				journals = data
				if journals.size() > 0:
					last_journal = journals[0]
				print("✅ Journals loaded from Supabase:", journals.size())
			else:
				print("⚠️ Unexpected data format from Supabase:", data)
		else:
			print("❌ Failed to load journals from Supabase. Code:", response_code, "Body:", body.get_string_from_utf8())

		http.queue_free()
	)

	http.request(url, headers)


func add_journal(title: String, text: String) -> Dictionary:
	var now = Time.get_datetime_dict_from_system()
	var months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
	
	var formatted_date = str(months[now.month - 1]) + " " + str(now.day) + ", " + str(now.year) \
	+ " " + str(now.hour) + ":" + str(now.minute).pad_zeros(2)
	
	var new_journal = {
		"id": str(Time.get_unix_time_from_system()), # Always string
		"title": title,
		"text": text,
		"date": str(months[now.month - 1]) + " " + str(now.day) + ", " + str(now.year) \
				+ " " + str(now.hour) + ":" + str(now.minute).pad_zeros(2),
		"date_created": formatted_date   # ✅ Add this line!
	}
	journals.append(new_journal)

	journals.sort_custom(func(a, b):
		return int(b["id"]) - int(a["id"])
	)
	
	save_journals()

	if journals.size() > 0:
		last_journal = journals[0]

	emit_signal("journal_saved", new_journal["text"], new_journal["id"])
	return new_journal


func update_journal(journal_data: Dictionary) -> void:
	if not journal_data.has("id"):
		print("⚠️ Missing journal ID — cannot update!")
		return

	var journal_id = str(journal_data["id"])
	var url = "https://rekmhywernuqjshghyvu.supabase.co/rest/v1/journals?id=eq." + journal_id
	var headers = [
		"apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
		"Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
		"Content-Type: application/json",
	]

	var body = {
		"title": journal_data["title"],
		"content": journal_data["text"],
		"date_created": journal_data.get("date_created", Time.get_date_string_from_system())
	}

	print("📝 Updating journal:", journal_id, body)

	var http_request = HTTPRequest.new()
	add_child(http_request)

	http_request.request_completed.connect(func(result, response_code, headers, body_data):
		if response_code == 204:
			print("✅ Journal updated successfully on Supabase!")
		else:
			print("❌ Failed to update journal on Supabase. Response code:", response_code, "Body:", body_data.get_string_from_utf8())
	)

	http_request.request(url, headers, HTTPClient.METHOD_PATCH, JSON.stringify(body))

func get_journal(id: String) -> Dictionary:
	var id_int = int(id)
	for j in journals:
		if int(j["id"]) == id_int:
			return j
	return {}

# Delete a journal by ID from Supabase
func delete_journal(id: int) -> bool:
	
	var url = "https://rekmhywernuqjshghyvu.supabase.co/rest/v1/journals?id=eq." + str(id)

	var headers = [
		"apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
		"Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
		"Content-Type: application/json",
		]

	var http := HTTPRequest.new()
	get_tree().root.add_child(http)

	var err = http.request(url, headers, HTTPClient.METHOD_DELETE)
	if err != OK:
		push_error("Failed request: %s" % err)
		return false

	var result = await http.request_completed
	http.queue_free()

	var response_code: int = result[1]
	if response_code == 204:
		# ✅ Remove from local list
		for i in range(journals.size()):
			if int(float(journals[i]["id"])) == id:
				journals.remove_at(i)
				break
		print("Deleted journal with ID:", id)
		return true
	else:
		print("❌ Failed to delete from Supabase:", response_code, result[3].get_string_from_utf8())
		return false
