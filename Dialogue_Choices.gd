extends ItemList
class_name DialogueChoices
#This whole script was written with itemlists in mind and may need to be largely remade if you want it to be handled differently 

@export var Text_Handler : Node
	
@onready var choice_table = []

func _ready() -> void:
	
	self.visible = false #Hides on start
	
	self.item_clicked.connect(func(element_index, _at_position, _mouse_button_index):

		if choice_table[element_index]:
			var stored_choice = choice_table[element_index] #This stops some asynchronous issues with the function being called before it can clear the table
			choice_table = []
			#print("Choice table: " + str(choice_table))
			self.clear()
			self.visible = false
			#print("Choice chosen " + stored_choice)
			Text_Handler.choice_receive.emit(stored_choice)
		)

	Text_Handler.send_choice.connect(func(incoming_data): create_choices(incoming_data))
	
func create_choices(target_dictionary): #Makes dialogue choices, replace this if you want custom choice box logic

	#print("Creating choices: " + str(target_dictionary))
	for current_choice in target_dictionary:

		var item_button_index = self.add_item(current_choice)
		
		
		#print(current_choice)
		choice_table.insert(item_button_index, current_choice)
		
	self.visible = true
	#print("Choice table: " + str(choice_table))
