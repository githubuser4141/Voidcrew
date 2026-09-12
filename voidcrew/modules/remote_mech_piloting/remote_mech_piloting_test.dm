/datum/unit_test/remote_mech_piloting

/datum/unit_test/remote_mech_piloting/Run()
	var/obj/item/mecha_parts/mecha_equipment/remote_cable_reel/reel = allocate()
	TEST_ASSERT_EQUAL(reel.cable_remaining, reel.max_cable, "A new remote cable reel must start full.")
	TEST_ASSERT(!reel.auto_reel, "The standard reel must leave cable behind when reversing.")
	var/obj/item/mecha_remote_cable_reclaimer/reclaimer = allocate()
	reel.install_reclaimer(reclaimer, allocate(/mob/living/carbon/human/consistent))
	TEST_ASSERT(reel.auto_reel, "Installing the reclaimer must enable cable recovery.")
	var/obj/structure/mecha_remote_cable/cable = allocate()
	cable.reel = reel
	reel.deployed_cables += cable
	reel.sever_cable(cable)
	TEST_ASSERT(reel.link_broken, "Destroying a deployed control cable must sever the link.")
