## CardInstance.gd
## 실제 덱 안에 들어가는 카드 인스턴스.
## 동일한 CardDef 라도 강화 레벨, 보너스 모디파이어가 다를 수 있다.
##
## 직렬화 가능 — SaveLoadController 가 Dictionary 로 변환해 저장한다.
extends RefCounted
class_name CardInstance


# =============================================================================
# 식별
# =============================================================================

## 이 인스턴스의 고유 ID (런 내에서 유일)
var instance_id  : StringName = &""

## 참조하는 CardDef resource
var card_def     : CardDef = null

## CardDef ID (직렬화 시 저장하는 값)
var card_def_id  : StringName = &""


# =============================================================================
# 강화 상태
# =============================================================================

var upgrade_level: int = 0

## 이 인스턴스에만 적용된 추가 모디파이어
## 예: [{ "stat": "power", "type": "flat", "value": 5.0 }]
var bonus_modifiers: Array[Dictionary] = []


# =============================================================================
# 메타데이터
# =============================================================================

## 획득 출처 (예: &"reward", &"shop", &"start")
var acquired_from : StringName = &""

## 제거 불가 여부 (특정 유물 효과 등)
var locked       : bool = false

## 덱에서 제거 불가 여부
var undeletable  : bool = false

static var _next_serial := 1


# =============================================================================
# 생성자
# =============================================================================

static func create(def: CardDef, source: StringName = &"", supplied_id: StringName = &"") -> CardInstance:
	var inst          := CardInstance.new()
	if supplied_id != &"":
		inst.instance_id = supplied_id
	else:
		inst.instance_id = StringName("card_%08d" % _next_serial)
		_next_serial += 1
	inst.card_def     = def
	inst.card_def_id  = def.id
	inst.acquired_from = source
	return inst


# =============================================================================
# 편의 프로퍼티 (CardDef 위임)
# =============================================================================

var display_name: String:
	get: return card_def.display_name if card_def else ""
var mp_cost: float:
	get: return _calc_mp_cost()
var cast_type: CardDef.CastType:
	get: return card_def.cast_type if card_def else CardDef.CastType.INSTANT
var effect_specs: Array:
	get: return card_def.effect_specs if card_def else []
var family_id: StringName:
	get: return card_def.family_id if card_def else &""


func _calc_mp_cost() -> float:
	if card_def == null:
		return 0.0
	var base := card_def.mp_cost
	for m in bonus_modifiers:
		if m.get("stat") == "mp_cost":
			if m.get("type") == "flat":
				base += m["value"]
			elif m.get("type") == "percent":
				base *= (1.0 + m["value"] / 100.0)
	return maxf(0.0, base)


# =============================================================================
# 직렬화 / 역직렬화
# =============================================================================

func to_dict() -> Dictionary:
	return {
		"instance_id"     : instance_id,
		"card_def_id"     : card_def_id,
		"upgrade_level"   : upgrade_level,
		"bonus_modifiers" : bonus_modifiers.duplicate(true),
		"acquired_from"   : acquired_from,
		"locked"          : locked,
		"undeletable"     : undeletable,
	}


static func from_dict(data: Dictionary, def_lookup: Callable) -> CardInstance:
	var inst             := CardInstance.new()
	inst.instance_id     = data.get("instance_id", &"")
	inst.card_def_id     = data.get("card_def_id", &"")
	inst.card_def        = def_lookup.call(inst.card_def_id)
	inst.upgrade_level   = data.get("upgrade_level", 0)
	inst.bonus_modifiers = data.get("bonus_modifiers", []).duplicate(true)
	inst.acquired_from   = data.get("acquired_from", &"")
	inst.locked          = data.get("locked", false)
	inst.undeletable     = data.get("undeletable", false)
	return inst
