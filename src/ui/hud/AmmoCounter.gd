extends Label

func set_ammo(magazine, reserve):
	self.text = str(magazine) + "/" +str(reserve)
