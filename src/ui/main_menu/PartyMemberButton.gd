extends Button

class_name PartyMemberButton

var member_id: String
var member_username: String

signal party_member_clicked(member_id: String)

func init(mem_id: String, mem_user: String):
	member_id = mem_id
	member_username = mem_user
	
	text = member_username

func _pressed() -> void:
	party_member_clicked.emit(member_id)
