extends RefCounted
class_name ContentFactory

static func cards() -> Array[CardDef]:
	var result: Array[CardDef] = []
	# 검술: 일반 3 / 희귀 2 / 특급 2 / 전설 1
	result.append(_card(&"slash", "횡베기", &"sword", CardDef.Rarity.COMMON, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTANT, CardDef.AttackPattern.MELEE_ARC, CardDef.TargetPriority.NEAREST, 0.45, 140, 24, 14, "가장 가까운 적을 향해 넓게 벤다."))
	result.append(_card(&"vertical_cut", "종베기", &"sword", CardDef.Rarity.COMMON, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTANT, CardDef.AttackPattern.THRUST, CardDef.TargetPriority.LOWEST_HP, 0.75, 165, 30, 22, "체력이 가장 낮은 적을 내려벤다.", &"", 0, 0, 0, 1, 1, 0, &"execute"))
	result.append(_card(&"sword_thrust", "찌르기", &"sword", CardDef.Rarity.COMMON, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTANT, CardDef.AttackPattern.THRUST, CardDef.TargetPriority.NEAREST, 0.60, 230, 24, 18, "직선상의 적을 관통한다.", &"", 0, 0, 0, 1, 1, 0, &"armor_pierce", &"", 0, 1, 1))
	result.append(_card(&"pommel_strike", "칼등 치기", &"sword", CardDef.Rarity.UNCOMMON, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTANT, CardDef.AttackPattern.MELEE_ARC, CardDef.TargetPriority.NEAREST, 0.55, 125, 18, 10, "가까운 적을 밀어낸다.", &"", 0, 0, 170))
	result.append(_card(&"stance", "자세", &"sword", CardDef.Rarity.UNCOMMON, CardDef.Role.DEFENSE, CardDef.DeliveryType.STATUS, CardDef.AttackPattern.DEFENSE, CardDef.TargetPriority.SELF, 1.10, 0, 0, 0, "보호막을 얻고 잠시 검술 위력을 높인다.", &"", 0, 0, 0, 1, 1, 0, &"sword_stance"))
	result.append(_card(&"sword_wave", "검기", &"sword", CardDef.Rarity.RARE, CardDef.Role.ATTACK, CardDef.DeliveryType.PROJECTILE, CardDef.AttackPattern.PROJECTILE, CardDef.TargetPriority.NEAREST, 1.25, 620, 38, 28, "가까운 적에게 관통 검기를 날린다.", &"", 0, 0, 0, 1, 1, 0, &"", &"", 0, 1, 2))
	result.append(_card(&"draw_cut", "발도", &"sword", CardDef.Rarity.RARE, CardDef.Role.ATTACK, CardDef.DeliveryType.MOVEMENT, CardDef.AttackPattern.THRUST, CardDef.TargetPriority.LOWEST_HP, 1.80, 430, 42, 46, "딸피 적에게 지연 참격을 긋는다.", &"", 0, 0, 0, 1, 1, 0.45, &"execute"))
	result.append(_card(&"greatsword_drop", "대검투하", &"sword", CardDef.Rarity.LEGENDARY, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTALLATION_OR_SUMMON, CardDef.AttackPattern.NOVA, CardDef.TargetPriority.DENSEST_CLUSTER, 3.00, 520, 155, 78, "적이 밀집한 곳에 대검을 투하한다.", &"", 0, 0, 180, 1, 1, 0.75))

	# 창술
	result.append(_card(&"spear_thrust", "창찌르기", &"spear", CardDef.Rarity.COMMON, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTANT, CardDef.AttackPattern.THRUST, CardDef.TargetPriority.NEAREST, 0.55, 285, 22, 17, "긴 사거리로 직선을 찌른다."))
	result.append(_card(&"spear_sweep", "창휘두르기", &"spear", CardDef.Rarity.COMMON, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTANT, CardDef.AttackPattern.MELEE_ARC, CardDef.TargetPriority.NEAREST, 0.50, 185, 26, 13, "창을 넓게 휘둘러 다수의 적을 친다."))
	result.append(_card(&"javelin", "투창", &"spear", CardDef.Rarity.COMMON, CardDef.Role.ATTACK, CardDef.DeliveryType.PROJECTILE, CardDef.AttackPattern.PROJECTILE, CardDef.TargetPriority.LOWEST_HP, 0.80, 720, 30, 20, "딸피 적에게 관통 투창을 던진다.", &"", 0, 0, 0, 1, 1, 0, &"", &"", 0, 1, 2))
	result.append(_card(&"hook_strip", "걸어 빼앗기", &"spear", CardDef.Rarity.UNCOMMON, CardDef.Role.UTILITY, CardDef.DeliveryType.STATUS, CardDef.AttackPattern.THRUST, CardDef.TargetPriority.NEAREST, 0.95, 330, 30, 12, "적을 끌어당기고 방어를 약화한다.", &"weakened", 1, 3.0, -160, 1, 1, 0, &"pull"))
	result.append(_card(&"formation", "방진 세우기", &"spear", CardDef.Rarity.UNCOMMON, CardDef.Role.DEFENSE, CardDef.DeliveryType.INSTALLATION_OR_SUMMON, CardDef.AttackPattern.DEFENSE, CardDef.TargetPriority.SELF, 1.30, 0, 110, 6, "주변 적을 찌르고 보호막을 공급하는 방진을 세운다.", &"", 0, 0, 0, 1, 1, 0, &"", &"formation", 1))
	result.append(_card(&"spear_flurry", "창 연속 찌르기", &"spear", CardDef.Rarity.RARE, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTANT, CardDef.AttackPattern.THRUST, CardDef.TargetPriority.NEAREST, 1.45, 310, 25, 12, "직선으로 네 번 빠르게 찌른다.", &"", 0, 0, 0, 1, 1, 0, &"", &"", 0, 4, 1))
	result.append(_card(&"anti_armor_spear", "대전차 창술", &"spear", CardDef.Rarity.RARE, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTANT, CardDef.AttackPattern.THRUST, CardDef.TargetPriority.LOWEST_HP, 2.10, 420, 34, 48, "강한 적을 꿰뚫고 방어를 붕괴시킨다.", &"weakened", 2, 5.0, 0, 1, 1, 0.35, &"boss_hunter", &"", 0, 1, 4))
	result.append(_card(&"phalanx", "팔랑크스", &"spear", CardDef.Rarity.LEGENDARY, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTALLATION_OR_SUMMON, CardDef.AttackPattern.NOVA, CardDef.TargetPriority.DENSEST_CLUSTER, 3.10, 560, 150, 22, "적이 밀집한 곳에 자동 공격 창병대를 전개한다.", &"", 0, 0, 90, 1, 1, 0.55, &"", &"phalanx", 1))

	# 둔기
	result.append(_card(&"overhead_smash", "내리치기", &"blunt", CardDef.Rarity.COMMON, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTANT, CardDef.AttackPattern.THRUST, CardDef.TargetPriority.NEAREST, 0.65, 150, 34, 20, "가장 가까운 적을 강하게 내리친다.", &"", 0, 0, 80))
	result.append(_card(&"blunt_sweep", "휘둘러치기", &"blunt", CardDef.Rarity.COMMON, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTANT, CardDef.AttackPattern.MELEE_ARC, CardDef.TargetPriority.NEAREST, 0.60, 175, 34, 15, "넓은 부채꼴로 적을 밀어낸다.", &"", 0, 0, 120))
	result.append(_card(&"home_run", "홈런", &"blunt", CardDef.Rarity.COMMON, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTANT, CardDef.AttackPattern.THRUST, CardDef.TargetPriority.NEAREST, 0.75, 145, 30, 13, "한 적을 아주 멀리 날려버린다.", &"", 0, 0, 320))
	result.append(_card(&"grappling_hook", "갈고리", &"blunt", CardDef.Rarity.UNCOMMON, CardDef.Role.UTILITY, CardDef.DeliveryType.PROJECTILE, CardDef.AttackPattern.PROJECTILE, CardDef.TargetPriority.LOWEST_HP, 0.95, 600, 20, 9, "딸피 적을 끌어당긴다.", &"slowed", 1, 2.0, -260, 1, 1, 0, &"pull"))
	result.append(_card(&"ground_slam", "지면 강타", &"blunt", CardDef.Rarity.UNCOMMON, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTANT, CardDef.AttackPattern.NOVA, CardDef.TargetPriority.SELF, 1.25, 0, 170, 24, "주변에 충격파를 일으키고 짧게 기절시킨다.", &"stunned", 1, 0.35, 160))
	result.append(_card(&"trench_trooper", "참호 강습병", &"blunt", CardDef.Rarity.RARE, CardDef.Role.UTILITY, CardDef.DeliveryType.INSTALLATION_OR_SUMMON, CardDef.AttackPattern.DEFENSE, CardDef.TargetPriority.SELF, 2.00, 520, 100, 12, "가까운 적을 자동 사격하는 로봇을 설치한다.", &"", 0, 0, 0, 1, 1, 0, &"", &"turret", 1))
	result.append(_card(&"war_hammer", "전쟁 망치", &"blunt", CardDef.Rarity.RARE, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTALLATION_OR_SUMMON, CardDef.AttackPattern.DEFENSE, CardDef.TargetPriority.NEAREST, 2.50, 430, 90, 18, "적을 추적해 내려치는 망치 골렘을 소환한다.", &"stunned", 1, 0.2, 100, 1, 1, 0, &"", &"golem", 1))
	result.append(_card(&"mjolnir", "묠니르", &"blunt", CardDef.Rarity.LEGENDARY, CardDef.Role.ATTACK, CardDef.DeliveryType.PROJECTILE, CardDef.AttackPattern.PROJECTILE, CardDef.TargetPriority.RANDOM, 3.20, 760, 55, 62, "무작위 적 셋에게 감전 망치를 내리꽂는다.", &"shocked", 2, 2.0, 120, 3, 3, 0.45, &"chain", &"", 0, 1, 3))

	# 불
	result.append(_card(&"fire_spark", "불꽃 튀기기", &"fire", CardDef.Rarity.COMMON, CardDef.Role.ATTACK, CardDef.DeliveryType.PROJECTILE, CardDef.AttackPattern.PROJECTILE, CardDef.TargetPriority.RANDOM, 0.45, 560, 20, 8, "무작위 적 셋에게 연소 불꽃을 튄다.", &"burning", 1, 4.0, 0, 3, 3))
	result.append(_card(&"fireball", "화염구", &"fire", CardDef.Rarity.COMMON, CardDef.Role.ATTACK, CardDef.DeliveryType.PROJECTILE, CardDef.AttackPattern.PROJECTILE, CardDef.TargetPriority.NEAREST, 0.75, 620, 55, 18, "가까운 적에게 폭발하는 화염구를 쏜다.", &"burning", 1, 4.0, 50, 1, 1, 0, &"projectile_aoe"))
	result.append(_card(&"flame_lance", "화염창", &"fire", CardDef.Rarity.COMMON, CardDef.Role.ATTACK, CardDef.DeliveryType.PROJECTILE, CardDef.AttackPattern.PROJECTILE, CardDef.TargetPriority.LOWEST_HP, 0.90, 720, 28, 23, "딸피 적을 관통하며 연소시킨다.", &"burning", 1, 4.0, 0, 1, 1, 0, &"", &"", 0, 1, 3))
	result.append(_card(&"flame_surge", "불길 쇄도", &"fire", CardDef.Rarity.UNCOMMON, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTANT, CardDef.AttackPattern.NOVA, CardDef.TargetPriority.SELF, 1.10, 0, 185, 22, "주변을 불태우는 화염파를 일으킨다.", &"burning", 1, 4.0, 110))
	result.append(_card(&"heat_release", "열기 방출", &"fire", CardDef.Rarity.UNCOMMON, CardDef.Role.DEFENSE, CardDef.DeliveryType.STATUS, CardDef.AttackPattern.DEFENSE, CardDef.TargetPriority.SELF, 1.00, 0, 125, 12, "보호막을 얻고 주변 적에게 열기를 방출한다.", &"burning", 1, 4.0, 0, 1, 1, 0, &"heat_guard"))
	result.append(_card(&"burning_weapon", "타오르는 무기", &"fire", CardDef.Rarity.RARE, CardDef.Role.UTILITY, CardDef.DeliveryType.STATUS, CardDef.AttackPattern.DEFENSE, CardDef.TargetPriority.SELF, 1.60, 0, 0, 0, "잠시 모든 물리 공격에 연소를 추가한다.", &"", 0, 0, 0, 1, 1, 0, &"flaming_weapon"))
	result.append(_card(&"flame_vortex", "화염 소용돌이", &"fire", CardDef.Rarity.RARE, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTALLATION_OR_SUMMON, CardDef.AttackPattern.ZONE, CardDef.TargetPriority.DENSEST_CLUSTER, 2.00, 560, 120, 16, "밀집 지역에 지속 연소 장판을 만든다.", &"burning", 1, 4.0, 0, 1, 1, 0.35, &"", &"", 2))
	result.append(_card(&"meteor_strike", "메테오 스트라이크", &"fire", CardDef.Rarity.LEGENDARY, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTALLATION_OR_SUMMON, CardDef.AttackPattern.NOVA, CardDef.TargetPriority.DENSEST_CLUSTER, 3.60, 650, 205, 110, "밀집 지역에 거대한 메테오를 낙하시킨다.", &"burning", 3, 5.0, 240, 1, 1, 2.20))

	# 물
	result.append(_card(&"water_skip", "물수제비", &"water", CardDef.Rarity.COMMON, CardDef.Role.ATTACK, CardDef.DeliveryType.PROJECTILE, CardDef.AttackPattern.PROJECTILE, CardDef.TargetPriority.RANDOM, 0.60, 620, 22, 9, "무작위 적 셋을 튕기며 젖게 한다.", &"wet", 1, 4.0, 30, 3, 3, 0, &"chain"))
	result.append(_card(&"water_jet", "물대포", &"water", CardDef.Rarity.COMMON, CardDef.Role.ATTACK, CardDef.DeliveryType.PROJECTILE, CardDef.AttackPattern.PROJECTILE, CardDef.TargetPriority.NEAREST, 0.70, 540, 30, 14, "가까운 적을 밀어내고 젖게 한다.", &"wet", 1, 4.0, 170))
	result.append(_card(&"water_spray", "물 흩뿌리기", &"water", CardDef.Rarity.COMMON, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTANT, CardDef.AttackPattern.MELEE_ARC, CardDef.TargetPriority.NEAREST, 0.55, 190, 30, 8, "근거리 적들을 젖게 하고 밀어낸다.", &"wet", 1, 4.0, 90))
	result.append(_card(&"water_guard", "수호의 물막", &"water", CardDef.Rarity.UNCOMMON, CardDef.Role.DEFENSE, CardDef.DeliveryType.STATUS, CardDef.AttackPattern.DEFENSE, CardDef.TargetPriority.SELF, 1.00, 0, 0, 0, "물막으로 보호막을 얻는다.", &"", 0, 0, 0, 1, 1, 0, &"water_guard"))
	result.append(_card(&"puddle", "물구덩이", &"water", CardDef.Rarity.UNCOMMON, CardDef.Role.UTILITY, CardDef.DeliveryType.INSTALLATION_OR_SUMMON, CardDef.AttackPattern.ZONE, CardDef.TargetPriority.DENSEST_CLUSTER, 1.30, 520, 105, 8, "밀집 지역을 젖게 하고 느려지게 한다.", &"wet", 1, 5.0, 0, 1, 1, 0, &"slow_zone", &"", 2))
	result.append(_card(&"whirlpool", "소용돌이", &"water", CardDef.Rarity.RARE, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTALLATION_OR_SUMMON, CardDef.AttackPattern.ZONE, CardDef.TargetPriority.DENSEST_CLUSTER, 2.00, 580, 145, 12, "적을 중심으로 끌어당기는 물 장판을 만든다.", &"wet", 1, 5.0, -85, 1, 1, 0.25, &"pull_zone", &"", 2))
	result.append(_card(&"water_spirit", "물의 정령 소환", &"water", CardDef.Rarity.RARE, CardDef.Role.UTILITY, CardDef.DeliveryType.INSTALLATION_OR_SUMMON, CardDef.AttackPattern.DEFENSE, CardDef.TargetPriority.SELF, 2.40, 520, 85, 14, "플레이어를 따라다니며 젖음 탄환과 보호막을 지원한다.", &"wet", 1, 4.0, 0, 1, 1, 0, &"", &"spirit", 1))
	result.append(_card(&"tsunami", "쓰나미", &"water", CardDef.Rarity.LEGENDARY, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTALLATION_OR_SUMMON, CardDef.AttackPattern.NOVA, CardDef.TargetPriority.DENSEST_CLUSTER, 3.20, 620, 225, 68, "적이 밀집한 곳을 거대한 파도로 쓸어버린다.", &"wet", 1, 6.0, 300, 1, 1, 0.85))

	# 독: 노션의 빈 카드군을 기능 검증용으로 보완한다.
	result.append(_card(&"poison_needle", "독침", &"poison", CardDef.Rarity.COMMON, CardDef.Role.ATTACK, CardDef.DeliveryType.PROJECTILE, CardDef.AttackPattern.PROJECTILE, CardDef.TargetPriority.NEAREST, 0.55, 620, 18, 8, "가까운 적에게 중독 독침을 발사한다.", &"poisoned", 1, 6.0))
	result.append(_card(&"corrosive_spore", "부식성 포자", &"poison", CardDef.Rarity.COMMON, CardDef.Role.ATTACK, CardDef.DeliveryType.PROJECTILE, CardDef.AttackPattern.PROJECTILE, CardDef.TargetPriority.RANDOM, 0.70, 600, 28, 9, "무작위 적 셋에게 중독과 방어 약화를 건다.", &"poisoned", 1, 6.0, 0, 3, 3, 0, &"corrode"))
	result.append(_card(&"venom_concentrate", "맹독 농축", &"poison", CardDef.Rarity.COMMON, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTANT, CardDef.AttackPattern.THRUST, CardDef.TargetPriority.LOWEST_HP, 0.80, 440, 26, 16, "딸피 적에게 중독 스택 비례 피해를 준다.", &"poisoned", 1, 6.0, 0, 1, 1, 0, &"poison_scaling"))
	result.append(_card(&"toxic_mist", "독안개", &"poison", CardDef.Rarity.UNCOMMON, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTALLATION_OR_SUMMON, CardDef.AttackPattern.ZONE, CardDef.TargetPriority.DENSEST_CLUSTER, 1.20, 540, 120, 8, "밀집 지역에 중독 안개를 만든다.", &"poisoned", 1, 6.0, 0, 1, 1, 0, &"", &"", 2))
	result.append(_card(&"acid_pool", "산성 웅덩이", &"poison", CardDef.Rarity.UNCOMMON, CardDef.Role.UTILITY, CardDef.DeliveryType.INSTALLATION_OR_SUMMON, CardDef.AttackPattern.ZONE, CardDef.TargetPriority.NEAREST, 1.40, 500, 105, 10, "가까운 적 아래에 부식 장판을 만든다.", &"weakened", 1, 5.0, 0, 1, 1, 0, &"corrode_zone", &"", 2))
	result.append(_card(&"plague_flower", "역병 꽃", &"poison", CardDef.Rarity.RARE, CardDef.Role.UTILITY, CardDef.DeliveryType.INSTALLATION_OR_SUMMON, CardDef.AttackPattern.DEFENSE, CardDef.TargetPriority.DENSEST_CLUSTER, 1.80, 520, 130, 9, "주변에 중독 포자를 뿌리는 꽃을 설치한다.", &"poisoned", 1, 6.0, 0, 1, 1, 0, &"", &"flower", 1))
	result.append(_card(&"toxic_golem", "독성 골렘", &"poison", CardDef.Rarity.RARE, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTALLATION_OR_SUMMON, CardDef.AttackPattern.DEFENSE, CardDef.TargetPriority.NEAREST, 2.50, 420, 90, 15, "적을 추적하며 중독 오라를 내뿜는 골렘을 소환한다.", &"poisoned", 1, 6.0, 85, 1, 1, 0, &"", &"golem", 1))
	result.append(_card(&"bio_explosion", "생체 폭발", &"poison", CardDef.Rarity.LEGENDARY, CardDef.Role.ATTACK, CardDef.DeliveryType.INSTALLATION_OR_SUMMON, CardDef.AttackPattern.NOVA, CardDef.TargetPriority.DENSEST_CLUSTER, 3.00, 620, 175, 44, "중독 스택을 소모해 연쇄 생체 폭발을 일으킨다.", &"poisoned", 1, 6.0, 140, 1, 1, 0.65, &"poison_detonate"))
	return result


static func characters() -> Array[CharacterDef]:
	var vanguard := CharacterDef.new()
	vanguard.id = &"vanguard"
	vanguard.display_name = "선봉 검사"
	vanguard.description = "검술·창술·둔기를 선택해 물리 빌드를 시험하는 일반형 캐릭터"
	vanguard.style = CharacterDef.Style.GENERAL
	vanguard.base_max_hp = 125.0
	vanguard.base_defense = 15.0
	vanguard.allowed_starting_families.assign([&"sword", &"spear", &"blunt"])
	var sword_trait := CharacterTrait.new()
	sword_trait.id = &"weapon_training"
	sword_trait.type = CharacterTrait.Type.CARD_FAMILY
	sword_trait.family_id = &"sword"
	sword_trait.family_weight_multiplier = 1.25
	vanguard.traits.append(sword_trait)

	var conduit := CharacterDef.new()
	conduit.id = &"conduit"
	conduit.display_name = "조류술사"
	conduit.description = "불·물·독의 상태와 반응을 조합하는 기믹형 캐릭터"
	conduit.style = CharacterDef.Style.GIMMICK
	conduit.base_max_hp = 90.0
	conduit.base_magic_power = 16.0
	conduit.allowed_starting_families.assign([&"fire", &"water", &"poison"])
	var flow_trait := CharacterTrait.new()
	flow_trait.id = &"elemental_flow"
	flow_trait.type = CharacterTrait.Type.SPECIAL_RULE
	flow_trait.event_hooks.assign([&"after_dodge", &"before_card_execute"])
	flow_trait.rule_values = {"next_card_multiplier": 1.35}
	conduit.traits.append(flow_trait)
	return [vanguard, conduit]


static func survivor_relics() -> Array[Dictionary]:
	return [
		{"id": &"vital_core", "name": "박동 코어", "description": "최대 체력 +25, 즉시 25 회복", "stat": "max_hp", "value": 25.0, "icon": "HP", "color": ArtDirection.MAGENTA},
		{"id": &"overclock", "name": "과회전 태엽", "description": "모든 콤보 실행 속도 +15%", "stat": "attack_speed", "value": 0.15, "icon": "AS", "color": ArtDirection.YELLOW},
		{"id": &"prism_lens", "name": "균열 프리즘", "description": "모든 카드 피해 +18%", "stat": "power", "value": 0.18, "icon": "DM", "color": ArtDirection.CYAN},
		{"id": &"runner_boots", "name": "도주자의 부츠", "description": "이동 속도 +35", "stat": "move_speed", "value": 35.0, "icon": "MV", "color": ArtDirection.PINK},
		{"id": &"xp_magnet", "name": "기억 자석", "description": "획득 경험치 +25%", "stat": "xp", "value": 0.25, "icon": "XP", "color": ArtDirection.VIOLET},
		{"id": &"guard_pin", "name": "안전핀 부적", "description": "보호막 30 즉시 획득", "stat": "shield", "value": 30.0, "icon": "SH", "color": ArtDirection.PAPER},
	]



static func enemies() -> Array[EnemyDef]:
	return [
		_enemy(&"furnace_hound", "용광로 사냥개", EnemyDef.Role.MELEE, EnemyDef.Rank.MOB, 38.0, 7.0, 112.0),
		_enemy(&"rivet_gunner", "리벳 사수", EnemyDef.Role.RANGED, EnemyDef.Rank.MOB, 32.0, 7.5, 92.0),
		_enemy(&"rolling_charger", "압연 돌격기", EnemyDef.Role.CHARGER, EnemyDef.Rank.MOB, 48.0, 9.0, 118.0),
		_enemy(&"boiler_bug", "보일러 벌레", EnemyDef.Role.BOMBER, EnemyDef.Rank.MOB, 26.0, 12.0, 104.0),
		_enemy(&"armored_wall", "철갑 방벽", EnemyDef.Role.SHIELD, EnemyDef.Rank.MOB, 76.0, 7.0, 68.0),
		_enemy(&"repair_drone", "수리 드론", EnemyDef.Role.SUPPORT, EnemyDef.Rank.MOB, 30.0, 4.0, 98.0),
		_enemy(&"casting_incubator", "주조 배양기", EnemyDef.Role.SUMMONER, EnemyDef.Rank.MOB, 54.0, 5.0, 62.0),
		_enemy(&"slag_shaman", "슬래그 주술사", EnemyDef.Role.DISRUPTOR, EnemyDef.Rank.MOB, 42.0, 8.0, 84.0),
	]


static func named_enemies() -> Array[EnemyDef]:
	return [
		_enemy(&"red_supervisor", "붉은 감독관", EnemyDef.Role.SHIELD, EnemyDef.Rank.NAMED, 245.0, 13.0, 76.0),
		_enemy(&"lady_of_pressure", "압력의 귀부인", EnemyDef.Role.CHARGER, EnemyDef.Rank.NAMED, 215.0, 15.0, 128.0),
		_enemy(&"void_welder", "공허 용접사", EnemyDef.Role.DISRUPTOR, EnemyDef.Rank.NAMED, 230.0, 14.0, 96.0),
	]


static func _enemy(id: StringName, name: String, role: EnemyDef.Role, rank: EnemyDef.Rank, hp: float, power: float, speed: float) -> EnemyDef:
	var enemy := EnemyDef.new()
	enemy.id = id
	enemy.display_name = name
	enemy.role = role
	enemy.rank = rank
	enemy.base_max_hp = hp
	enemy.base_attack_power = power
	enemy.base_move_speed = speed
	enemy.is_named = rank == EnemyDef.Rank.NAMED
	enemy.named_scale = 1.0
	return enemy

static func maps() -> Array[MapDef]:
	var foundry := MapDef.new()
	foundry.id = &"foundry"
	foundry.display_name = "카르보 제련소"
	foundry.arena_shape = MapDef.ArenaShape.POLYGON
	foundry.max_depth = 5
	foundry.max_total_nodes = 12
	return [foundry]


static func starting_deck(family_id: StringName, all_cards: Array[CardDef]) -> DeckState:
	var deck := DeckState.new()
	var selected: Array[CardDef] = []
	for card in all_cards:
		if card.family_id == family_id and card.rarity in [CardDef.Rarity.COMMON, CardDef.Rarity.UNCOMMON]:
			selected.append(card)
			if selected.size() >= 4:
				break
	for card in selected:
		deck.add_card(CardInstance.create(card, &"start"))
	return deck


static func default_cycle(deck: DeckState) -> CycleState:
	var cycle := CycleState.new()
	if deck.cards.is_empty():
		return cycle
	var lane_count := mini(3, deck.cards.size())
	var lane_times: Array[float] = []
	for lane_index in range(lane_count):
		cycle.combos.append(ComboState.create(StringName("combo_%d" % (lane_index + 1))))
		lane_times.append(0.0)
	for card in deck.cards:
		var best_lane := 0
		for lane_index in range(1, lane_count):
			if lane_times[lane_index] < lane_times[best_lane]:
				best_lane = lane_index
		cycle.combos[best_lane].card_instance_ids.append(card.instance_id)
		lane_times[best_lane] += card.card_def.execution_interval
	return cycle


static func _card(id: StringName, name: String, family: StringName, rarity: CardDef.Rarity, role: CardDef.Role, delivery: CardDef.DeliveryType, pattern: CardDef.AttackPattern, priority: CardDef.TargetPriority, interval: float, max_range: float, radius: float, power: float, description: String, status_id: StringName = &"", status_stacks: int = 0, status_duration: float = 0.0, knockback: float = 0.0, projectile_count: int = 1, target_count: int = 1, effect_delay: float = 0.0, special_rule: StringName = &"", summon_kind: StringName = &"", active_limit: int = 0, hit_count: int = 1, pierce_count: int = 0) -> CardDef:
	var card := CardDef.new()
	card.id = id
	card.display_name = name
	card.description = description
	card.large_category = &"element" if family in [&"fire", &"water", &"poison"] else &"cold_weapon"
	card.small_category = &"natural_element" if family in [&"fire", &"water", &"poison"] else &"melee"
	card.family_id = family
	card.rarity = rarity
	card.role = role
	card.delivery_type = delivery
	card.execution_interval = interval
	card.effect_delay = effect_delay
	card.attack_pattern = pattern
	card.target_priority = priority
	card.max_range = max_range
	card.impact_radius = radius
	card.base_power = power
	card.status_id = status_id
	card.status_stacks = status_stacks
	card.status_duration = status_duration
	card.knockback_force = knockback
	card.projectile_count = projectile_count
	card.target_count = target_count
	card.special_rule = special_rule
	card.summon_kind = summon_kind
	card.active_limit = active_limit
	card.hit_count = hit_count
	card.pierce_count = pierce_count
	card.projectile_speed = 650.0 if max_range >= 600.0 else 520.0
	card.main_type = _main_type(pattern, summon_kind)
	card.sub_types.assign([family, _priority_tag(priority)])
	card.card_tags.assign([StringName("family_%s" % family), card.main_type])
	card.effect_specs.append(_effect_spec(card))
	return card


static func _effect_spec(card: CardDef) -> EffectSpec:
	var spec := EffectSpec.new()
	spec.power = card.base_power
	spec.radius = card.impact_radius
	spec.projectile_speed = card.projectile_speed
	spec.pierce_count = card.pierce_count
	spec.status_id = card.status_id
	spec.status_stacks = card.status_stacks
	spec.duration = card.status_duration
	spec.knockback_force = card.knockback_force
	spec.tags = card.card_tags.duplicate()
	spec.target_spec = _target_spec(card)
	match card.attack_pattern:
		CardDef.AttackPattern.PROJECTILE: spec.type = EffectSpec.Type.PROJECTILE
		CardDef.AttackPattern.ZONE: spec.type = EffectSpec.Type.SPAWN_ZONE
		CardDef.AttackPattern.MELEE_ARC, CardDef.AttackPattern.THRUST: spec.type = EffectSpec.Type.MELEE_DAMAGE
		CardDef.AttackPattern.NOVA: spec.type = EffectSpec.Type.AREA_DAMAGE
		CardDef.AttackPattern.DEFENSE:
			spec.type = EffectSpec.Type.SPAWN_ENTITY if card.summon_kind in [&"golem", &"spirit"] else EffectSpec.Type.SPAWN_INSTALLATION if card.summon_kind != &"" else EffectSpec.Type.GRANT_SHIELD
		_: spec.type = EffectSpec.Type.AREA_DAMAGE
	return spec


static func _target_spec(card: CardDef) -> TargetSpec:
	var spec := TargetSpec.new()
	spec.range = maxf(1.0, card.max_range)
	spec.count = maxi(1, card.target_count)
	match card.target_priority:
		CardDef.TargetPriority.LOWEST_HP: spec.type = TargetSpec.Type.LOWEST_HP
		CardDef.TargetPriority.RANDOM: spec.type = TargetSpec.Type.RANDOM_ENEMIES
		CardDef.TargetPriority.DENSEST_CLUSTER: spec.type = TargetSpec.Type.DENSEST_CLUSTER
		CardDef.TargetPriority.SELF: spec.type = TargetSpec.Type.SELF
		_: spec.type = TargetSpec.Type.NEAREST_ENEMY
	return spec


static func _main_type(pattern: CardDef.AttackPattern, summon_kind: StringName) -> StringName:
	if summon_kind != &"": return &"summon" if summon_kind in [&"golem", &"spirit"] else &"installation"
	if pattern == CardDef.AttackPattern.ZONE: return &"zone"
	if pattern == CardDef.AttackPattern.PROJECTILE: return &"projectile"
	if pattern == CardDef.AttackPattern.DEFENSE: return &"defense"
	return &"melee"


static func _priority_tag(priority: CardDef.TargetPriority) -> StringName:
	return [&"nearest", &"lowest_hp", &"random", &"densest", &"self"][priority]