class_name inventoryData extends Resource

@export var slots : Array[slotData]


func _init() -> void:
	connect_slots()

func addItem(item : ItemData, count : int = 1) -> bool:
	for s in slots:
		if s:
			if s.item_data == item:
				s.quantity += count
				return true
	for i in slots.size():
		if slots[i] == null:
			var new = slotData.new()
			new.item_data = item
			new.quantity = count
			slots[i] = new
			new.changed.connect(slot_changed)
			return true
	print("inventory was full")
	return false


func get_item_count(item: ItemData) -> int:
	var total: int = 0
	for slot in slots:
		if slot != null and slot.item_data == item:
			total += slot.quantity
	return total


func has_space_for(item: ItemData) -> bool:
	for slot in slots:
		if slot != null and slot.item_data == item:
			return true
	return slots.has(null)


func remove_item(item: ItemData, count: int = 1) -> bool:
	if count < 1 or get_item_count(item) < count:
		return false
	var remaining: int = count
	for slot in slots:
		if slot == null or slot.item_data != item:
			continue
		var removed: int = mini(slot.quantity, remaining)
		slot.quantity -= removed
		remaining -= removed
		if remaining == 0:
			return true
	return false
	
func connect_slots() -> void:
	for s in slots:
		if s:
			s.changed.connect(slot_changed)
			
func slot_changed() -> void:
	for s in slots:
		if s:
			if s.quantity < 1:
				s.changed.disconnect(slot_changed)
				var index = slots.find(s)
				slots[index] = null
	emit_changed()
	
#Gather the information into an array
func getSaveData() -> Array:
	#Make the array
	var item_holder : Array = []
	#Iterate through all items in the slots.
	for i in slots.size():
		item_holder.append(item_saver(slots[i]))
	return item_holder
#Convert items into a dictionary
func item_saver(slot : slotData) -> Dictionary:
	#Creates a temporary dictionary to hold the data.
	var result = {item = "", quantity = 0 }
	#If the slot isn't empty
	if slot != null:
		#Take the value and put it in our temporary dictionary
		result.quantity = slot.quantity
		#If the slot has item data
		if slot.item_data != null:
			#set the dictionary equal to the path so that it can find it in the resource tree.
			result.item = slot.item_data.resource_path
	return result


func parseSave(save_data : Array) -> void:
	#Create an array with the same size as the number of slots
	var myArraySize = slots.size()
	#Clear the slots
	slots.clear()
	#Resize the array for empty slots
	slots.resize(myArraySize)
	#Itterate through the array
	for i in save_data.size():
		#Pulls the data at that specific iteration
		#First slot in inventory should be first slot in save data
		slots[i] = pullItem(save_data[i])
	connect_slots()
	pass
	
#Takes a dictionary anc converts it into item.
func pullItem(saveObject : Dictionary) -> slotData:
	#If there is no object in the dictionary do not return
	if saveObject.item == "":
		return null
	#Creates a new slot data to hold the item in the dictionary.
	var newData : slotData = slotData.new()
	#Instantiate the slotdata item data with what is in the dictionary
	newData.item_data = load(saveObject.item)
	#Converts the string to an int
	newData.quantity = int(saveObject.quantity)
	
	return newData
