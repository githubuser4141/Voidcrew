# Remote mech piloting notes

When filtering mech equipment, use a typed `in` loop:

```dm
for(var/obj/item/mecha_parts/mecha_equipment/remote_cable_reel/reel in mech.flat_equipment)
```

Do **not** use `as anything` for this. It disables the type filter, so an unrelated installed module (for example, an ejector) can be treated as the reel or receiver and cause runtime errors.
