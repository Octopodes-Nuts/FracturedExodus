extends Label

func display_text(action, txt: String):
	if not action:
		self.text = txt
	# Append action in front of text if there is text to display

func clear():
	self.text = ""
