class_name CustomerDialogue extends RefCounted

const FACTION_PROFILES := {
	"commoners": {
		"entry": [
			"The upper route is safe enough today. I came down for food and lamp oil.",
			"My family works the first landing. I need supplies before the next shift.",
			"I came in with the scavengers. The surface prices are worse than the monsters.",
		],
	},
	"craftsfolk": {
		"entry": [
			"I made it through the freight lift for ore and salvage. Show me what you have.",
			"The old stonecutters' route is open again. I need materials before it closes.",
			"I am not here for adventure. I am here for the things adventurers leave behind.",
		],
	},
	"reagent_circle": {
		"entry": [
			"The fumes below changed overnight. I need fresh samples before they settle.",
			"I came down for residue and teeth. The dungeon is an unpleasant laboratory.",
			"The surface has no reagent this lively. Point me toward anything strange.",
		],
	},
	"patron_houses": {
		"entry": [
			"My escort is waiting above the old vaults. I came for a relic, not a stroll.",
			"House Voss is paying for a proper trophy from below. Your shop is the nearest stop.",
			"The dungeon is dangerous, but at least its treasures have not learned manners.",
		],
	},
	"expedition_companies": {
		"entry": [
			"We made it back from the lower route. I need supplies before we go in again.",
			"The shop is the only dry place between the entrance and the next descent.",
			"Our scout is injured and our torches are gone. Sell me something useful.",
		],
	},
}

const PROFILES := {
	"Peasant": {
		"names": ["Mira", "Nell", "Bram", "Tilda"],
		"entry": ["Morning, shopkeep.", "Anything useful today?", "I hope the prices are kind."],
		"browse": ["Let me have a closer look.", "Maybe there is something for supper.", "I will know it when I see it."],
		"purchase": ["That {item} will do nicely.", "Perfect, I needed {item}.", "A fair find: {item}."],
		"empty": ["No wares today? I will come back later.", "Looks like the shelves are bare."],
		"pricey": ["That is more coin than I have.", "I cannot spare that much today."],
		"hostile": ["I have heard enough about this shop.", "I will take my coin elsewhere."],
		"farewell": ["Take care, shopkeep.", "Until next time."],
	},
	"Blacksmith": {
		"names": ["Bran", "Hilda", "Orin", "Maeve"],
		"entry": ["I need solid materials.", "Show me something that will last.", "I am looking for good stock."],
		"browse": ["Let me inspect the workmanship.", "The useful things are never on top.", "I will know quality when I see it."],
		"purchase": ["{item} will serve my forge well.", "That {item} has potential.", "I can make use of {item}."],
		"empty": ["No materials worth buying today.", "I will check your shelves another day."],
		"pricey": ["That price would bend an anvil.", "I will not pay that much for it."],
		"hostile": ["A bad reputation is worse than bad steel.", "I do not trade with dishonest folk."],
		"farewell": ["Keep your stock sturdy.", "Back to the forge for me."],
	},
	"Alchemist": {
		"names": ["Elara", "Pip", "Morrow", "Sera"],
		"entry": ["I require unusual ingredients.", "Do you have anything reactive?", "My work needs rare components."],
		"browse": ["Hmm, the residue may be useful.", "Careful, I am examining the fumes.", "There is promise in odd little things."],
		"purchase": ["Excellent. {item} will help my experiment.", "{item} is just the reagent I needed.", "At last, a usable {item}."],
		"empty": ["No ingredients today? A shame.", "My flask will remain empty for now."],
		"pricey": ["That would ruin my research budget.", "The value is not in the right proportions."],
		"hostile": ["I will not risk my work on this shop.", "Poor dealings make poor reagents."],
		"farewell": ["Try not to mix anything dangerous.", "Back to the laboratory."],
	},
	"Noble": {
		"names": ["Lady Voss", "Lord Bell", "Dame Corin", "Sir Alden"],
		"entry": ["I expect a refined selection.", "Perhaps you have something worthy of my coin.", "Do not disappoint me, shopkeeper."],
		"browse": ["Presentation matters, you know.", "I shall consider the finer details.", "Let us see if your wares have taste."],
		"purchase": ["A fine choice. I shall take {item}.", "{item} is worthy of my collection.", "Very well, I will purchase {item}."],
		"empty": ["How unfortunate. There is nothing to consider.", "I expected a better selection."],
		"pricey": ["Even I will not reward such excess.", "That price lacks all decorum."],
		"hostile": ["Your reputation precedes you, unpleasantly.", "I shall not be seen shopping here."],
		"farewell": ["Do improve the display before I return.", "Good day, shopkeeper."],
	},
	"Adventurer": {
		"names": ["Rook", "Sable", "Tamsin", "Kellan"],
		"entry": ["I need supplies before the next delve.", "Anything that helps me survive?", "I am stocking up for danger."],
		"browse": ["This might save my life down there.", "You can never carry too many supplies.", "The dungeon always asks for one more item."],
		"purchase": ["{item} could save a run. Sold.", "I will take {item} into the dungeon.", "Good. {item} is coming with me."],
		"empty": ["No supplies? That is bad timing.", "I will have to make do without."],
		"pricey": ["I need my coin for the road.", "That is too steep for a dungeon run."],
		"hostile": ["I have heard this shop is trouble.", "I will take my chances without your wares."],
		"farewell": ["Stay sharp, shopkeep.", "See you after the next dungeon run."],
	},
	"Tax Collector": {
		"names": ["The Tax Collector"],
		"entry": ["Ah. There you are.", "I had hoped we would not need to meet."],
		"browse": ["Please, continue.", "Do not mind me."],
		"farewell": ["We will speak again.", "Do take care."],
	},
}


static func pick_name(customer_type: String) -> String:
	return _pick(customer_type, "names", "Customer")


static func pick_line(customer_type: String, category: String, fallback: String) -> String:
	return _pick(customer_type, category, fallback)


static func pick_faction_line(faction_id: String, category: String, fallback: String) -> String:
	return _pick_from_profile(FACTION_PROFILES.get(faction_id, {}), category, fallback)


static func _pick(customer_type: String, category: String, fallback: String) -> String:
	return _pick_from_profile(PROFILES.get(customer_type, {}), category, fallback)


static func _pick_from_profile(profile: Dictionary, category: String, fallback: String) -> String:
	var options: Array = profile.get(category, [])
	if options.is_empty():
		return fallback
	return str(options.pick_random())
