extends Node

signal debt_changed(balance: int, payment: int)
signal collector_visit_requested

const STARTING_LOAN := 250
const REPAYMENT_RATE := 0.12
const SAVE_VERSION := 2
const SALES_BEFORE_MISFORTUNE_CHECK := 5
const MISFORTUNE_GOLD_THRESHOLD := 8
const DEBT_DISTRESS_THRESHOLD := 125

var loan_balance := STARTING_LOAN
var sales_since_visit := 0
var collector_visit_pending := false


func _ready() -> void:
	SaveManager.game_loaded.connect(_load_from_save)
	_load_from_save()


func record_shop_sale(sale_price: int) -> int:
	if sale_price <= 0 or loan_balance <= 0:
		return 0
	var payment := mini(loan_balance, maxi(1, ceili(float(sale_price) * REPAYMENT_RATE)))
	loan_balance -= payment
	sales_since_visit += 1
	_store_in_save()
	debt_changed.emit(loan_balance, payment)
	return payment


func consider_misfortune(player_gold: int) -> void:
	if collector_visit_pending or loan_balance < DEBT_DISTRESS_THRESHOLD:
		return
	if sales_since_visit < SALES_BEFORE_MISFORTUNE_CHECK or player_gold > MISFORTUNE_GOLD_THRESHOLD:
		return
	collector_visit_pending = true
	_store_in_save()
	var shop_log := get_node_or_null("/root/ShopLog")
	if shop_log != null:
		shop_log.call("record_debt_event", "The Tax Collector has been requested.", 0, loan_balance)
	collector_visit_requested.emit()


func has_collector_visit_pending() -> bool:
	return collector_visit_pending and loan_balance > 0


func claim_collector_visit() -> bool:
	if not has_collector_visit_pending():
		return false
	collector_visit_pending = false
	sales_since_visit = 0
	_store_in_save()
	return true


func get_ledger_text() -> String:
	if loan_balance <= 0:
		return "Loan: paid"
	return "Loan: %dg" % loan_balance


func _load_from_save() -> void:
	var saved_data: Dictionary = SaveManager.current_save.get("tax_debt", {})
	loan_balance = maxi(0, int(saved_data.get("loan_balance", STARTING_LOAN)))
	sales_since_visit = maxi(0, int(saved_data.get("sales_since_visit", 0)))
	collector_visit_pending = bool(saved_data.get("collector_visit_pending", false)) if int(saved_data.get("version", 0)) >= SAVE_VERSION else false


func _store_in_save() -> void:
	SaveManager.current_save["tax_debt"] = {
		"version": SAVE_VERSION,
		"loan_balance": loan_balance,
		"sales_since_visit": sales_since_visit,
		"collector_visit_pending": collector_visit_pending,
	}
