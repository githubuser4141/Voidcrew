/datum/design/mech_remote_control_receiver
	name = "Remote Control Receiver"
	desc = "An exosuit module that receives remote pilot input."
	id = "mech_remote_control_receiver"
	build_type = MECHFAB
	build_path = /obj/item/mecha_parts/mecha_equipment/remote_control_receiver
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 3, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 2)
	construction_time = 10 SECONDS
	category = list(RND_CATEGORY_MECHFAB_EQUIPMENT + RND_SUBCATEGORY_MECHFAB_EQUIPMENT_MODULES)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE

/datum/design/mech_remote_cable_reel
	name = "Remote Cable Reel"
	desc = "An exosuit module that pays out a 30-length remote control cable."
	id = "mech_remote_cable_reel"
	build_type = MECHFAB
	build_path = /obj/item/mecha_parts/mecha_equipment/remote_cable_reel
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	construction_time = 10 SECONDS
	category = list(RND_CATEGORY_MECHFAB_EQUIPMENT + RND_SUBCATEGORY_MECHFAB_EQUIPMENT_MODULES)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE

/datum/design/mech_remote_cable_reclaimer
	name = "Reclaiming Remote Cable Reel"
	desc = "An upgraded remote cable reel that automatically recovers cable while reversing."
	id = "mech_remote_cable_reclaimer"
	build_type = MECHFAB
	build_path = /obj/item/mecha_remote_cable_reclaimer
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 7, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 2, /datum/material/gold = SHEET_MATERIAL_AMOUNT)
	construction_time = 15 SECONDS
	category = list(RND_CATEGORY_MECHFAB_EQUIPMENT + RND_SUBCATEGORY_MECHFAB_EQUIPMENT_MODULES)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE
