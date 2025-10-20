extends Node

signal journal_saved(journal_text: String, journal_id: String)

var journals: Array = []
var last_journal: Dictionary = {}

const API_URL = "http://192.168.254.111/zenpet"
const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

func _ready() -> void:
	print("🟢 JournalManager initialized")

func _make_request(endpoint: String, method: int, body: String = "") -> Variant:
	var http = HTTPRequest.new()
	add_child(http)
	
	var headers = ["Content-Type: application/json"]
	var url = "%s/%s" % [API_URL, endpoint]
	
	var err = http.request(url, headers, method, body if body else "")
	
	if err != OK:
		print("❌ HTTP Request failed: ", err)
		http.queue_free()
		return null
	
	var result = await http.request_completed
	var response_code: int = result[1]
	var response_body: PackedByteArray = result[3]
	var response_text: String = response_body.get_string_from_utf8()
	
	http.queue_free()
	
	print("📊 Response Code: %d, Body: %s" % [response_code, response_text])
	
	# Handle success responses (200, 201, 204)
	if response_code == 200 or response_code == 201 or response_code == 204:
		if response_text.is_empty():
			return {"success": true}
		var parsed = JSON.parse_string(response_text)
		return parsed if parsed else null
	else:
		print("❌ HTTP Error %d: %s" % [response_code, response_text])
		return null

# 📥 Load all journals from PHP backend
func load_journals_from_php(user_id: int) -> void:
	var response = await _make_request(
		"get_journals.php?user_id=%d" % user_id,
		HTTPClient.METHOD_GET
	)
	
	if response is Array:
		journals = []
		for journal in response:
			if typeof(journal) == TYPE_DICTIONARY and journal.has("id"):
				journals.append({
					"id": str(journal["id"]),
					"title": journal.get("title", "Untitled"),
					"text": journal.get("content", ""),
					"content": journal.get("content", ""),
					"date": journal.get("date_created", ""),
					"date_created": journal.get("date_created", ""),
					"color": journal.get("color", "#FFFFFF")
				})
		
		if journals.size() > 0:
			last_journal = journals[0]
		
		print("✅ Loaded %d journals from PHP" % journals.size())
	else:
		print("⚠️ Failed to load journals")
		journals = []

# ➕ Add new journal via PHP
func add_journal(title: String, text: String, user_id: int, color: String = "#F39C12") -> Dictionary:
	var payload = {
		"user_id": user_id,
		"title": title,
		"content": text,
		"color": color
	}
	
	var response = await _make_request(
		"add_journal.php",
		HTTPClient.METHOD_POST,
		JSON.stringify(payload)
	)
	
	if response is Dictionary and response.get("success", false):
		var new_journal = {
			"id": str(response["id"]),
			"title": response["title"],
			"text": response["content"],
			"content": response["content"],
			"date": response["date_created"],
			"date_created": response["date_created"],
			"color": response["color"]
		}
		
		journals.append(new_journal)
		last_journal = new_journal
		
		emit_signal("journal_saved", new_journal["text"], new_journal["id"])
		print("✅ Journal saved: %s" % new_journal["id"])
		return new_journal
	else:
		print("❌ Failed to save journal")
		return {}

# ✏️ Update existing journal via PHP
func update_journal(journal_data: Dictionary, user_id: int) -> bool:
	if not journal_data.has("id"):
		print("⚠️ Missing journal ID")
		return false
	
	var journal_id = str(journal_data["id"])
	print("🔄 Attempting to update journal ID:", journal_id)

	var payload = {
		"id": int(journal_id),
		"user_id": user_id,
		"title": journal_data.get("title", ""),
		"content": journal_data.get("text", journal_data.get("content", "")),
		"color": journal_data.get("color", "#FFFFFF")
	}

	print("📤 Sending update payload:", JSON.stringify(payload))

	var response = await _make_request(
		"update_journal.php",
		HTTPClient.METHOD_POST,
		JSON.stringify(payload)
	)

	if response is Dictionary:
		print("📥 Received update response:", JSON.stringify(response))

	if response is Dictionary and response.get("success", false):
		# 🧠 Use updated decrypted data from backend
		var updated_data = {
			"id": str(response.get("id", journal_id)),
			"title": response.get("title", payload["title"]),
			"text": response.get("content", payload["content"]),
			"content": response.get("content", payload["content"]),
			"date": response.get("date", journals.filter(func(j): return str(j["id"]) == journal_id)[0].get("date", "")),
			"color": response.get("color", payload["color"])
		}

		# 🔁 Replace cached version
		for i in range(journals.size()):
			if str(journals[i]["id"]) == journal_id:
				journals[i] = updated_data
				break

		last_journal = updated_data
		print("✅ Journal updated successfully:", updated_data)
		return true
	else:
		print("❌ Failed to update journal. Response:", response)
		return false

# 🗑️ Delete journal via PHP
func delete_journal(journal_id: int, user_id: int = 0) -> bool:
	var payload = {"id": journal_id, "user_id": user_id}
	var response = await _make_request(
		"delete_journal.php",
		HTTPClient.METHOD_POST,
		JSON.stringify(payload)
	)
	
	if response is Dictionary and response.get("success", false):
		for i in range(journals.size()):
			if int(journals[i]["id"]) == journal_id:
				journals.remove_at(i)
				break
		print("✅ Journal deleted: %d" % journal_id)
		return true
	else:
		print("❌ Failed to delete journal: ", response)
		return false


# 🔍 Get journal by ID from local cache
func get_journal(id: String) -> Dictionary:
	var id_int = int(id)
	for journal in journals:
		if int(journal["id"]) == id_int:
			return journal
	return {}
