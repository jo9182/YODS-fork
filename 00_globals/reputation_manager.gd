
extends Node

signal reputation_changed(new_score: int)

# clamped between -100 and 100
var score: int = 0 : set = _set_score

# how much each sale moves the needle
const FAIR_GAIN     = 3   # priced within 20% of base_value
const CHEAP_GAIN    = 5   # priced below base_value (generous)
const GREEDY_LOSS   = 4   # priced 20-60% above base_value
const GOUGE_LOSS    = 10  # priced more than 60% above base_value


enum Mood { HOSTILE, WARY, NEUTRAL, FRIENDLY, BELOVED }

func get_mood() -> Mood:
	if score < -50:   return Mood.HOSTILE
	if score < -15:   return Mood.WARY
	if score < 20:    return Mood.NEUTRAL
	if score < 60:    return Mood.FRIENDLY
	return Mood.BELOVED


func get_mood_label() -> String:
	match get_mood():
		Mood.HOSTILE:  return "Hostile"
		Mood.WARY:     return "Wary"
		Mood.NEUTRAL:  return "Neutral"
		Mood.FRIENDLY: return "Friendly"
		Mood.BELOVED:  return "Beloved"
	return ""


# called by ShopManager after a sale
func record_sale(sale_price: int, base_value: int) -> void:
	if base_value <= 0:
		# no base value set, treat as neutral
		return

	var ratio = float(sale_price) / float(base_value)

	if ratio <= 1.0:
		score += CHEAP_GAIN
	elif ratio <= 1.2:
		score += FAIR_GAIN
	elif ratio <= 1.6:
		score -= GREEDY_LOSS
	else:
		score -= GOUGE_LOSS


# returns a multiplier for how much gold an NPC brings
# beloved customers bring 50% more, hostile bring nothing (they won't visit)
func get_budget_multiplier() -> float:
	match get_mood():
		Mood.HOSTILE:  return 0.0
		Mood.WARY:     return 0.75
		Mood.NEUTRAL:  return 1.0
		Mood.FRIENDLY: return 1.25
		Mood.BELOVED:  return 1.5
	return 1.0


# returns the max ratio an NPC will tolerate (price / base_value)
# wary customers won't buy anything more than 10% above base value
func get_price_tolerance() -> float:
	match get_mood():
		Mood.HOSTILE:  return 0.0   # won't buy anything
		Mood.WARY:     return 1.1
		Mood.NEUTRAL:  return 1.3
		Mood.FRIENDLY: return 1.6
		Mood.BELOVED:  return 99.0  # accepts any price
	return 1.3


func get_save_data() -> Dictionary:
	return { "reputation_score": score }


func load_save_data(data: Dictionary) -> void:
	score = data.get("reputation_score", 0)


func _set_score(value: int) -> void:
	score = clamp(value, -100, 100)
	reputation_changed.emit(score)
