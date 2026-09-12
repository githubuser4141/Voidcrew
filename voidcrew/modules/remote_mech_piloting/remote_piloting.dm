/// A machine tether is deliberately separate from power cabling: it must be cuttable,
/// but never joins a station powernet or shocks the operator.
/obj/structure/mecha_remote_cable
	name = "mech control cable"
	desc = "A heavy control cable paying out from a remote-piloted exosuit."
	icon = 'icons/obj/pipes_n_cables/layer_cable.dmi'
	icon_state = "l2-noconnection"
	anchored = TRUE
	obj_flags = CAN_BE_HIT
	max_integrity = 30
	var/obj/item/mecha_parts/mecha_equipment/remote_cable_reel/reel
	/// Set false only when the reel has physically recovered this length.
	var/drop_cable_coil = TRUE

/obj/structure/mecha_remote_cable/attackby(obj/item/item, mob/user, list/modifiers, list/attack_modifiers)
	if(item.tool_behaviour == TOOL_WIRECUTTER)
		user.visible_message(span_notice("[user] cuts [src]."), span_notice("You cut [src]."))
		qdel(src)
		return ITEM_INTERACT_SUCCESS
	return ..()

/obj/structure/mecha_remote_cable/Destroy()
	if(drop_cable_coil && get_turf(src))
		new /obj/item/stack/cable_coil(get_turf(src), 1)
	reel?.sever_cable(src)
	reel = null
	return ..()

/obj/structure/mecha_remote_cable/proc/set_visual_offset(index)
	// Repeated movements can leave multiple lengths on one turf. Offset them so they remain visible.
	pixel_x = ((index * 7) % 15) - 7
	pixel_y = ((index * 11) % 15) - 7

/obj/item/mecha_parts/mecha_equipment/remote_cable_reel
	name = "mech remote cable reel"
	desc = "A 30-length reel of armored cable for tethered remote piloting. Apply ordinary cable coils to refill it."
	equipment_slot = MECHA_UTILITY
	mech_flags = ALL
	var/max_cable = 30
	var/cable_remaining = 30
	var/list/obj/structure/mecha_remote_cable/deployed_cables = list()
	var/obj/machinery/computer/mecha_remote_piloting/terminal
	var/link_broken = FALSE
	/// Standard reels leave cable behind. The upgraded reel recovers it on reverse movement.
	var/auto_reel = FALSE

/obj/item/mecha_parts/mecha_equipment/remote_cable_reel/examine(mob/user)
	. = ..()
	. += span_notice("[cable_remaining] cable lengths remain in the reel.")

/obj/item/mecha_parts/mecha_equipment/remote_cable_reel/proc/connect_terminal(obj/machinery/computer/mecha_remote_piloting/new_terminal)
	terminal = new_terminal
	link_broken = FALSE
	lay_cable(get_turf(chassis))

/obj/item/mecha_parts/mecha_equipment/remote_cable_reel/proc/lay_cable(turf/cable_turf)
	if(!cable_turf || cable_remaining <= 0)
		return FALSE
	var/obj/structure/mecha_remote_cable/cable = new(cable_turf)
	cable.reel = src
	deployed_cables += cable
	cable.set_visual_offset(length(deployed_cables))
	cable_remaining--
	return TRUE

/obj/item/mecha_parts/mecha_equipment/remote_cable_reel/proc/handle_chassis_move(turf/old_turf, direction, facing)
	if(!terminal || link_broken || !chassis)
		return
	if(direction == facing)
		lay_cable(old_turf)
		return
	if(direction != REVERSE_DIR(facing))
		return
	if(!auto_reel)
		lay_cable(old_turf)
		return
	for(var/obj/structure/mecha_remote_cable/cable as anything in deployed_cables.Copy())
		if(cable.loc != get_turf(chassis))
			continue
		deployed_cables -= cable
		cable.reel = null
		cable.drop_cable_coil = FALSE
		qdel(cable)
		cable_remaining = min(cable_remaining + 1, max_cable)
		return

/obj/item/mecha_remote_cable_reclaimer
	name = "remote cable reclaimer upgrade"
	desc = "An automatic recovery drive for a mech remote cable reel."
	icon = 'icons/obj/devices/mecha_equipment.dmi'
	icon_state = "mecha_equip"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/mecha_remote_cable_reclaimer/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(istype(interacting_with, /obj/item/mecha_parts/mecha_equipment/remote_cable_reel))
		var/obj/item/mecha_parts/mecha_equipment/remote_cable_reel/reel = interacting_with
		return reel.install_reclaimer(src, user) ? ITEM_INTERACT_SUCCESS : ITEM_INTERACT_BLOCKING
	if(istype(interacting_with, /obj/vehicle/sealed/mecha))
		var/obj/vehicle/sealed/mecha/mech = interacting_with
		for(var/obj/item/mecha_parts/mecha_equipment/remote_cable_reel/reel as anything in mech.flat_equipment)
			return reel.install_reclaimer(src, user) ? ITEM_INTERACT_SUCCESS : ITEM_INTERACT_BLOCKING
		user.balloon_alert(user, "no cable reel!")
		return ITEM_INTERACT_BLOCKING
	return NONE

/obj/item/mecha_parts/mecha_equipment/remote_cable_reel/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(istype(tool, /obj/item/mecha_remote_cable_reclaimer))
		return install_reclaimer(tool, user) ? ITEM_INTERACT_SUCCESS : ITEM_INTERACT_BLOCKING
	if(!istype(tool, /obj/item/stack/cable_coil))
		return ..()
	var/obj/item/stack/cable_coil/coil = tool
	var/cable_needed = max_cable - cable_remaining
	if(!cable_needed)
		user.balloon_alert(user, "reel full!")
		return ITEM_INTERACT_BLOCKING
	var/cable_loaded = min(cable_needed, coil.get_amount())
	if(!coil.use(cable_loaded))
		return ITEM_INTERACT_BLOCKING
	cable_remaining += cable_loaded
	user.balloon_alert(user, "loaded [cable_loaded] length[cable_loaded == 1 ? "" : "s"]")
	return ITEM_INTERACT_SUCCESS

/obj/item/mecha_parts/mecha_equipment/remote_cable_reel/proc/install_reclaimer(obj/item/mecha_remote_cable_reclaimer/upgrade, mob/living/user)
	if(auto_reel)
		user.balloon_alert(user, "already upgraded!")
		return FALSE
	auto_reel = TRUE
	qdel(upgrade)
	user.visible_message(span_notice("[user] installs [upgrade] in [src]."), span_notice("You install [upgrade]. The reel will now recover cable while reversing."))
	return TRUE

/obj/item/mecha_parts/mecha_equipment/remote_cable_reel/proc/sever_cable(obj/structure/mecha_remote_cable/cable)
	deployed_cables -= cable
	detach_cables()
	if(!terminal)
		return
	link_broken = TRUE
	terminal.clear_link(TRUE)

/obj/item/mecha_parts/mecha_equipment/remote_cable_reel/Destroy()
	detach_cables()
	if(terminal?.controlled_mech == chassis)
		terminal.clear_link(TRUE)
	terminal = null
	return ..()

/obj/item/mecha_parts/mecha_equipment/remote_cable_reel/proc/detach_cables()
	for(var/obj/structure/mecha_remote_cable/cable as anything in deployed_cables.Copy())
		cable.reel = null
	deployed_cables.Cut()

/// Both cable and radio links terminate in this receiver. The cable reel only supplies a tether.
/obj/item/mecha_parts/mecha_equipment/remote_control_receiver
	name = "mech remote control receiver"
	desc = "A hardened receiver that lets an exosuit accept remote pilot input. Link it to a remote radio sender with a multitool."
	equipment_slot = MECHA_UTILITY
	mech_flags = ALL
	unstackable = TRUE
	var/obj/machinery/mecha_remote_radio/radio_sender

/obj/item/mecha_parts/mecha_equipment/remote_control_receiver/multitool_act(mob/living/user, obj/item/multitool/multitool)
	if(!istype(multitool.buffer, /obj/machinery/mecha_remote_radio))
		user.balloon_alert(user, "save a radio sender first!")
		return ITEM_INTERACT_BLOCKING
	var/obj/machinery/mecha_remote_radio/sender = multitool.buffer
	sender.link_receiver(src)
	multitool.set_buffer(null)
	user.visible_message(span_notice("[user] links [src] to [sender]."), span_notice("You link [src] to [sender]."))
	return ITEM_INTERACT_SUCCESS

/obj/item/mecha_parts/mecha_equipment/remote_control_receiver/Destroy()
	if(radio_sender?.linked_receiver == src)
		radio_sender.linked_receiver = null
	radio_sender = null
	return ..()

/obj/machinery/mecha_remote_radio
	name = "mech remote radio sender"
	desc = "A fixed, high-gain transmitter for remote exosuit controls. Save it to a multitool, then link an installed receiver on a mech."
	icon = 'icons/obj/machines/telecomms.dmi'
	icon_state = "bus"
	anchored = TRUE
	density = TRUE
	var/active = TRUE
	var/range = 30
	var/obj/item/mecha_parts/mecha_equipment/remote_control_receiver/linked_receiver

/obj/machinery/mecha_remote_radio/attack_hand(mob/living/user, list/modifiers)
	active = !active
	to_chat(user, span_notice("You [active ? "activate" : "deactivate"] [src]."))
	return TRUE

/obj/machinery/mecha_remote_radio/multitool_act(mob/living/user, obj/item/multitool/multitool)
	multitool.set_buffer(src)
	user.balloon_alert(user, "sender saved")
	return ITEM_INTERACT_SUCCESS

/obj/machinery/mecha_remote_radio/proc/link_receiver(obj/item/mecha_parts/mecha_equipment/remote_control_receiver/new_receiver)
	if(linked_receiver && linked_receiver != new_receiver)
		linked_receiver.radio_sender = null
	if(new_receiver.radio_sender && new_receiver.radio_sender != src)
		new_receiver.radio_sender.linked_receiver = null
	linked_receiver = new_receiver
	new_receiver.radio_sender = src

/obj/machinery/mecha_remote_radio/Destroy()
	if(linked_receiver?.radio_sender == src)
		linked_receiver.radio_sender = null
	linked_receiver = null
	return ..()

/obj/machinery/radio_jammer/large
	name = "large radio jammer"
	desc = "A fixed wideband jammer that silences nearby radio traffic and remote mech links."
	icon = 'icons/obj/machines/telecomms.dmi'
	icon_state = "broadcaster"
	anchored = TRUE
	density = TRUE
	var/active = TRUE
	var/range = 30

/obj/machinery/radio_jammer/large/Initialize(mapload)
	. = ..()
	GLOB.active_jammers |= src

/obj/machinery/radio_jammer/large/Destroy()
	GLOB.active_jammers -= src
	return ..()

/obj/machinery/radio_jammer/large/attack_hand(mob/living/user, list/modifiers)
	active = !active
	if(active)
		GLOB.active_jammers |= src
	else
		GLOB.active_jammers -= src
	to_chat(user, span_notice("You [active ? "activate" : "deactivate"] [src]."))
	return TRUE

/obj/vehicle/sealed/mecha
	/// The terminal currently receiving this mech's remote input.
	var/obj/machinery/computer/mecha_remote_piloting/remote_terminal

/obj/vehicle/sealed/mecha/proc/can_remote_pilot(mob/living/user)
	return remote_terminal?.operator == user && remote_terminal.can_control(src)

/obj/vehicle/sealed/mecha/multitool_act(mob/living/user, obj/item/multitool/multitool)
	for(var/obj/item/mecha_parts/mecha_equipment/remote_control_receiver/receiver as anything in flat_equipment)
		return receiver.multitool_act(user, multitool)
	return ..()

/obj/machinery/computer/mecha_remote_piloting
	name = "remote mech piloting terminal"
	desc = "A strapped-in console for controlling an unoccupied exosuit by cable or radio."
	icon_screen = "mecha"
	icon_keyboard = "tech_key"
	anchored = TRUE
	can_buckle = TRUE
	buckle_lying = 0
	buckle_dir = SOUTH
	/// The buckled pilot. Kept distinct from the machinery's generic occupant for link validation.
	var/mob/living/carbon/human/operator
	var/obj/vehicle/sealed/mecha/controlled_mech
	var/control_mode
	var/obj/machinery/mecha_remote_radio/radio_sender

/obj/machinery/computer/mecha_remote_piloting/is_buckle_possible(mob/living/target, force = FALSE, check_loc = TRUE)
	if(!ishuman(target))
		return FALSE
	return ..()

/obj/machinery/computer/mecha_remote_piloting/post_buckle_mob(mob/living/carbon/human/new_operator)
	operator = new_operator
	set_occupant(new_operator)
	to_chat(operator, span_notice("The terminal is ready. Use it to select an exosuit."))

/obj/machinery/computer/mecha_remote_piloting/post_unbuckle_mob(mob/living/carbon/human/old_operator)
	if(old_operator == operator)
		clear_link()
		operator = null
	set_occupant(null)

/obj/machinery/computer/mecha_remote_piloting/attack_hand(mob/living/user, list/modifiers)
	if(user == operator)
		select_mech()
		return TRUE
	return ..()

/obj/machinery/computer/mecha_remote_piloting/proc/select_mech()
	if(!operator || operator.incapacitated)
		return
	var/list/available_mechs = list()
	for(var/obj/vehicle/sealed/mecha/mech as anything in GLOB.mechas_list)
		if(!length(mech.return_occupants()) && !mech.remote_terminal)
			available_mechs[mech.name] = mech
	if(!length(available_mechs))
		to_chat(operator, span_warning("No unoccupied exosuits are available."))
		return
	var/choice = tgui_input_list(operator, "Select an unoccupied exosuit.", name, sort_list(available_mechs))
	var/obj/vehicle/sealed/mecha/mech = available_mechs[choice]
	if(!mech || length(mech.return_occupants()) || mech.remote_terminal)
		return
	var/obj/item/mecha_parts/mecha_equipment/remote_control_receiver/receiver = get_remote_receiver(mech)
	if(!receiver)
		to_chat(operator, span_warning("That exosuit has no remote control receiver."))
		return
	var/mode = tgui_input_list(operator, "Select control link.", name, list("Cable", "Radio"))
	if(mode == "Cable")
		var/obj/item/mecha_parts/mecha_equipment/remote_cable_reel/reel = get_cable_reel(mech)
		if(!reel || !Adjacent(mech))
			to_chat(operator, span_warning("Cable control requires an adjacent mech with a remote cable reel."))
			return
		begin_control(mech, "cable", reel)
	else if(mode == "Radio")
		var/obj/machinery/mecha_remote_radio/sender = receiver.radio_sender
		if(!sender)
			to_chat(operator, span_warning("That exosuit's receiver is not multitool-linked to a radio sender."))
			return
		if(!Adjacent(sender) || !sender.active || get_dist(sender, mech) > sender.range || sender.z != mech.z)
			to_chat(operator, span_warning("Radio control requires an adjacent active sender that can reach that exosuit."))
			return
		begin_control(mech, "radio", null, sender)
	else
		return

/obj/machinery/computer/mecha_remote_piloting/proc/get_cable_reel(obj/vehicle/sealed/mecha/mech)
	for(var/obj/item/mecha_parts/mecha_equipment/remote_cable_reel/reel as anything in mech.flat_equipment)
		return reel

/obj/machinery/computer/mecha_remote_piloting/proc/get_remote_receiver(obj/vehicle/sealed/mecha/mech)
	for(var/obj/item/mecha_parts/mecha_equipment/remote_control_receiver/receiver as anything in mech.flat_equipment)
		return receiver

/obj/machinery/computer/mecha_remote_piloting/proc/begin_control(obj/vehicle/sealed/mecha/mech, mode, obj/item/mecha_parts/mecha_equipment/remote_cable_reel/reel, obj/machinery/mecha_remote_radio/sender)
	clear_link()
	controlled_mech = mech
	control_mode = mode
	radio_sender = sender
	if(reel)
		reel.connect_terminal(src)
	controlled_mech.remote_terminal = src
	operator.remote_control = mech
	operator.click_intercept = src
	operator.reset_perspective(mech)
	operator.update_mouse_pointer()
	to_chat(operator, span_notice("Remote link established with [mech]."))

/obj/machinery/computer/mecha_remote_piloting/proc/can_control(obj/vehicle/sealed/mecha/mech)
	if(mech != controlled_mech || !operator || operator.buckled != src || length(mech.return_occupants()) || !get_remote_receiver(mech))
		return FALSE
	if(control_mode == "radio")
		var/obj/item/mecha_parts/mecha_equipment/remote_control_receiver/receiver = get_remote_receiver(mech)
		return receiver?.radio_sender == radio_sender && Adjacent(radio_sender) && radio_sender.active && radio_sender.z == mech.z && get_dist(radio_sender, mech) <= radio_sender.range && !is_within_radio_jammer_range(radio_sender) && !is_within_radio_jammer_range(mech)
	if(control_mode == "cable")
		var/obj/item/mecha_parts/mecha_equipment/remote_cable_reel/reel = get_cable_reel(mech)
		return reel?.terminal == src && !reel.link_broken
	return FALSE

/obj/machinery/computer/mecha_remote_piloting/proc/clear_link(warn = FALSE)
	if(warn && operator)
		to_chat(operator, span_warning("Your remote mech link has been severed."))
	if(controlled_mech?.remote_terminal == src)
		controlled_mech.remote_terminal = null
	if(control_mode == "cable")
		var/obj/item/mecha_parts/mecha_equipment/remote_cable_reel/reel = get_cable_reel(controlled_mech)
		if(reel?.terminal == src)
			reel.terminal = null
	if(operator?.remote_control == controlled_mech)
		operator.remote_control = null
		operator.click_intercept = null
		operator.reset_perspective()
		operator.update_mouse_pointer()
	controlled_mech = null
	control_mode = null
	radio_sender = null

/obj/machinery/computer/mecha_remote_piloting/proc/InterceptClickOn(mob/living/user, params, atom/target)
	if(user != operator || !can_control(controlled_mech))
		clear_link(TRUE)
		return TRUE
	controlled_mech.on_mouseclick(user, target, params2list(params))
	return TRUE

/obj/machinery/computer/mecha_remote_piloting/Destroy()
	clear_link()
	return ..()
