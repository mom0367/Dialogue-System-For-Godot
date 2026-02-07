**IF YOU ARE USING THIS FOR A MULTIPLAYER GAME REMEMBER TO SANATIZE YOUR INCOMING DATA, THIS PARSER CAN EXECUTE FUNCTIONS**

This requires an input set up for speeding up text

The way the code parser works is by using a series of "master" arrays and subarrays, essentially:
	
	* A master array is what includes individual "lines" of dialogue (Lines as in chunks displayed on the box, not literal lines), that are separated by the text box
	* A sub array is what holds smaller "fragments" of a dialogue line, this is mainly used for inserting functions into specific points of dialogue
	
Making dialogue lines:
	
	While there is a bit of functionality for sending strings directly to the parser for ease of use, primarily you want to turn dialogue into arrays, for example:
	The first array of a dialogue/dialogue branch is considered the master array, and everything should be wrapped into it 
	(I might add a way to detect single arrays without needing a master wrap at some point but I'm lazy sorry lol)
	
	[["Test dialogue"]] - A basic one "line" dialogue, wrapped in a master array
	[["Test1", "Test2"]] - A basic two "line" dialogue, wrapped in a master array
	[[["Test1A", "Test1B"], "Test2"]] - A two line dialogue where the first line is broken into two chunks, these will be merged into one line. wrapped in a master array
	
	
	
Putting functions in dialogue:
	
	Placing a function in a parsed array allows it to be ran, useful if you want to execute code during dialogue.
	Example:
	["Line1", func(): dothing, "Line2"]
	
	Giving the function a return will cause the return value to be parsed as an array, this is useful for making dialogue conditions, I suggest only doing this at the end of an array.
	
	
	
	
Additional credits:
	-Default typewriter sound by yottasounds on freesound
