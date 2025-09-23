extends Control

@onready var http = HTTPRequest.new()

func _ready():
	add_child(http)

	# test: insert a journal entry
	add_journal("Ken", "This is my first Supabase entry!")

	# test: fetch all journal entries
	get_journals()


# Fetch journals
func get_journals():
	var url = "https://rekmhywernuqjshghyvu.supabase.co/rest/v1/journals?select=*"
	var headers = [
		"apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
		"Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY"
	]
	http.request(url, headers, HTTPClient.METHOD_GET)


# Insert a journal entry
func add_journal(user_name: String, text: String):
	var url = "https://rekmhywernuqjshghyvu.supabase.co/rest/v1/journals"
	var headers = [
		"apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
		"Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
		"Content-Type: application/json"
	]
	var body = {
		"user_name": user_name,
		"entry": text
	}
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))


# Handle all HTTP responses
func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	print("HTTP Response Code: ", response_code)
	print("Response: ", body.get_string_from_utf8())
