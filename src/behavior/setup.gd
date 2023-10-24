###############################################################
# Copyright (c) 2023 Octopodes Studio
# Authors: Isaiah Raspet
###############################################################

extends Node

var account: Account

func _ready():
	account = _get_account_info()

## Connect to account and load information

func _get_account_info():
	return Account.new()
