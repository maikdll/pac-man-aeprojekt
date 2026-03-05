extends Node

var level = 1
var health = 3
var score = 0
var isGameStopped = false;
var speedGhost = 0.6;
var speedGhostRed = 1;
var speedGhostCyan = 1;
var speedGhostPink = 1;
var speedGhostOrange = 1;
var speedPlayer = 1;
var isIntermissionMode = false;
var eatGhostScore = 200;

const SAVE_PATH = "user://leaderboard.save"
var leaderboard = [
	{"name": "Empty", "score": 0},
	{"name": "Empty", "score": 0},
	{"name": "Empty", "score": 0},
	{"name": "Empty", "score": 0},
	{"name": "Empty", "score": 0}
]

func save_leaderboard():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(leaderboard)
	
func load_leaderboard():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		leaderboard = file.get_var()

func update_leaderboard(new_name: String):
	leaderboard.append({"name": new_name, "score": Global.score})
	
	leaderboard.sort_custom(func(a, b): return a["score"] > b["score"])
	
	leaderboard = leaderboard.slice(0, 5)
	
	save_leaderboard()
