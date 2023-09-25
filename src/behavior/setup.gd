extends Node

var account: Account

func _ready():
	account = _get_account_info()

## Connect to account and load information

func _get_account_info():
	return Node()
