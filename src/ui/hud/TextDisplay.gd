extends Label

func display_text(action, text: String):
	if not action:
		self.text = text
	# Append action in front of text if there is text to display

func clear():
	self.text = ""
