extends Node
class_name TextHandler
#TODO make some of these not export and just take in the node above instead of needing to input the associated text box
signal text_receive(incomingText : String)
signal text_written
signal continue_dialogue
signal send_choice
signal choice_receive

@onready var chosen_choice = null

@onready var dialogue_finished : bool = false
signal dialogue_tree_ended

@export var characters_per_second : float = 20
@export var text_Sound_Pitch_Minimum : float = 0.75
@export var text_Sound_Pitch_Maximum : float = 1
@export var dialogue_gui : Node
@export var text_label : Node
@export var text_box : Node
@export var AudioPlayer : AudioStreamPlayer
@onready var RNG = RandomNumberGenerator.new()
@onready var line_written : bool = false
@onready var speed_up : bool = false
@export var speed_up_amount : float = 2
@onready var cancel_write : bool = false

@onready var checkpoint = null #Used to store states of dialogue to return to

@export var choice_box : ItemList #Replace this if you want custom choice box logic
@onready var choice_open : bool = false

@onready var remaining_Dialogue : int = 0



func write_text(current_text):
	
	#print("Writing text " + current_text)
	cancel_write = false
	
	line_written = false
	text_label.text = (text_label.text + current_text)
	#print("Adding " + current_text)

	var bbcoderegex : RegEx = RegEx.new()
	bbcoderegex.compile("\\[.*?\\]")
	var textNoBBCode : String = bbcoderegex.sub(current_text, "", true)
	#print("textNoBBCode" + str(textNoBBCode))
	
	for count in textNoBBCode.length():
		#print(count)
		if cancel_write:
			break

		text_label.visible_characters = text_label.visible_characters + 1;
		
		AudioPlayer.pitch_scale = RNG.randf_range(text_Sound_Pitch_Minimum, text_Sound_Pitch_Maximum)
		AudioPlayer.play()

		var wait_time = ((1 / characters_per_second) / clampf(speed_up_amount * int(speed_up), 1, INF))  #Waits an amount affected by the speed up amount/bool
		#current equation can't make the text slower if you wanted that for some reason
		await get_tree().create_timer(wait_time).timeout
	
	#print("Line written: " + str(current_text))
	line_written = true
	text_written.emit()



func _ready():
	
	choice_receive.connect(func(incoming_data): chosen_choice = incoming_data)
	text_receive.connect(func(incoming_data): parse_master_array(incoming_data))
	
	
	
	text_box.gui_input.connect(func(event):
		
		if event is InputEventMouseButton:
			
			if dialogue_finished == true:
				if event.pressed:
					dialogue_gui.visible = false
				
			if not line_written:
				
				speed_up = event.pressed
				
			else:
				
				continue_dialogue.emit()
	)
	
func parse_master_array(incoming_data): #Main function that incoming text arrays pass through, this is what separates individual "lines" of dialogue
	
	#print("Parse master array incoming: " + str(incoming_data))
	
	dialogue_finished = false
	dialogue_gui.visible = true
	
	if incoming_data is Dictionary:
		
		process_dictionary(incoming_data)
	
	elif not incoming_data is Array:
		
		parse_text(incoming_data)
		
	else:
		

		for current_index in incoming_data.size():
			
			var current_element = incoming_data[current_index]
			#print("Current element: " + str(current_element))
			
			#Remnant from a readability improvement test, worked initially but was impossible to expand to support function returns.
			#if incoming_data is Array:
				#if (incoming_data.size() - 1) > (current_index):
					#if incoming_data[current_index + 1] is Dictionary:
						#process_dictionary(incoming_data[current_index + 1])
						
					##None of the commented code below works and is likely completely pointless, left in for archival reasons.
					##elif incoming_data[current_index + 1] is Callable:

						##print(incoming_data[current_index + 1].get_method_list())
						##var return_value = incoming_data[current_index + 1].call()
						##if return_value != null:
							##if return_value is Dictionary:
								##process_dictionary(return_value)


			
			await parse_text(current_element)
			
			if not current_element is Dictionary:
				await continue_dialogue
			
			if (current_index + 1 == incoming_data.size()) and not choice_open:
				#print("Dialogue completed")
				dialogue_finished = true
				dialogue_tree_ended.emit()
				
func process_dictionary(incoming_data):

	#print("Parsing dictionary " + str(incoming_data))
			
	send_choice.emit(incoming_data.keys())
	choice_open = true
	await choice_receive
	choice_open = false
	
	
	#print("Continuing with " + str(incoming_data[chosen_choice]))
	parse_master_array(incoming_data[chosen_choice])

#Function that parses subarrays, this is for dialogue broken up into smaller pieces, usually to run functions and such inbetween
#Primary determines if you're running through the current main array or a subarray
func parse_text(incoming_data): 
	
	#print("Parse_text data: " + str(incoming_data))

	if not incoming_data is Array: #Encloses single data (strings, functions, etc) into an array to be processed.
		
		incoming_data = [incoming_data]
	


	text_label.text = ""
	text_label.visible_characters = 0
	
	for current_element in incoming_data:
		
		
		#print("Current element: " + str(current_element))
		
		if current_element is String:
			
			#print("Writing " + current_element)
			await write_text(current_element)
		
		elif current_element is Callable: #Calls function, if function returns, parse as array, used for conditional dialogue.
			
			var return_value = current_element.call()
			#print("Return value: " + str(return_value))
			if return_value != null:
				if return_value is Dictionary:
					process_dictionary(return_value)
				else:
					parse_master_array(return_value)
				
			
		elif current_element is Array: 
			parse_text(current_element)
		elif current_element is Dictionary:
			process_dictionary(current_element)
		else:
		
			await write_text(str(current_element))
