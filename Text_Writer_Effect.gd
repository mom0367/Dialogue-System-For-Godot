extends Node
class_name TextHandler
signal text_receive(incomingText : String)
signal text_written
signal continue_dialogue
signal send_choice
signal choice_receive

@onready var chosen_choice = null

@onready var dialogue_finished : bool = false
signal dialogue_tree_ended

@export var characters_per_second : float = 20
##The time that the text waits before automatically continuing, set to -1 to disable
@export var auto_continue_time : float = -1
##The lowest pitch the text typing effect can do.
@export var sound_Pitch_Minimum : float = 0.75
##The highest pitch the text typing effect can do.
@export var sound_Pitch_Maximum : float = 1
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



func write_text(current_text) -> void:
	
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
		
		AudioPlayer.pitch_scale = RNG.randf_range(sound_Pitch_Minimum, sound_Pitch_Maximum)
		AudioPlayer.play()

		var wait_time : float = ((1 / characters_per_second) / clampf(speed_up_amount * int(speed_up), 1, INF))  #Waits an amount affected by the speed up amount/bool
		await get_tree().create_timer(wait_time).timeout
	
	#print("Line written: " + str(current_text))
	line_written = true
	text_written.emit()



func _ready() -> void:
	
	choice_receive.connect(func(incoming_data): chosen_choice = incoming_data)
	text_receive.connect(func(incoming_data): parse_master_array(incoming_data))
	
	
	
	text_box.gui_input.connect(func(event):
		
		if event is InputEventMouseButton:
			#print("Dialogue finished?: " + str(dialogue_finished))
			if dialogue_finished == true:
				if event.pressed:
					dialogue_gui.visible = false
			if not line_written:
				speed_up = event.pressed
			else:
				continue_dialogue.emit()
	)
	
func parse_master_array(incoming_data) -> void: #Main function that incoming text arrays pass through, this is what separates individual "lines" of dialogue
	
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
				#print("Awaiting continue dialogue")
				auto_continue()
				await continue_dialogue
			#print("choice_open: " + str(choice_open))
			#print("Current dialogue index: " + str(current_index))
			#print("Dialogue table size: " + str(incoming_data.size()))
			if (current_index + 1 == incoming_data.size()) and not choice_open:
				end_dialogue()
			#Fixes a bug where nested dialogue trees will cause system to get stuck
			elif (not incoming_data[current_index] is Dictionary) and (current_index + 1 == incoming_data.size()):
				await choice_receive
				await text_written
				end_dialogue()
				
func end_dialogue() -> void:
	#print("Dialogue completed")
	dialogue_finished = true
	dialogue_tree_ended.emit()
	
				
func process_dictionary(incoming_data) -> void:

	#print("Parsing dictionary " + str(incoming_data))
			
	send_choice.emit(incoming_data.keys())
	choice_open = true
	#print("Awaiting choice")
	await choice_receive
	#print("Choice received")
	choice_open = false
	
	
	#print("Continuing with " + str(incoming_data[chosen_choice]))
	parse_master_array(incoming_data[chosen_choice])

#Function that parses subarrays, this is for dialogue broken up into smaller pieces, usually to run functions and such inbetween
func parse_text(incoming_data) -> void: 
	
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
			
func auto_continue():
	if auto_continue_time != -1:
		#print("Starting auto continue.")
		await get_tree().create_timer(auto_continue_time).timeout
		if line_written == true:
			continue_dialogue.emit()
			#print("Auto continuing.")
