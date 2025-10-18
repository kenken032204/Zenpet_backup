extends Control

var database = PostgreSQLClient.new()

const USER = "postgres"
const PASSWORD = "Derppy101"
const HOST = "localhost"
const PORT = 5433
const DB_NAME = "postgres"

func _ready():
	var url = "postgresql://" + USER + ":" + PASSWORD + "@" + HOST + ":" + str(PORT) + "/" + DB_NAME
	print("Connecting to:", url)

	database.connection_established.connect(_on_connected)
	database.connection_error.connect(_on_error)
	database.connection_closed.connect(_on_closed)

	# ✅ Only one argument — the full URL string
	database.connect_to_host(url)

func _on_connected():
	print("✅ Connected successfully!")
	select_from_db()

func select_from_db():
	var result = database.execute("SELECT * FROM users;")
	if result and result.rows:
		print("📋 Query result:")
		for row in result.rows:
			print(row)
	else:
		print("⚠️ No rows or result empty.")
	
	database.close()

func _on_error():
	print("❌ Connection failed!")

func _on_closed():
	print("🔒 Connection closed.")
