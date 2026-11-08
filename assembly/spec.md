# Discant and bass together

`assembly.scad` puts the discant into the bass's frame with `../bass/link.scad`'s
`to_bass()`: the discant turned 180° about z, so that the gauges' plates sit in the
discant's outer holders and the bass's inner holders, pointing along the bass's y and
sensing along its z [given]. The bass on top; the discant behind it and below, its
gauge pad facing the bass's hand plate.

`make` builds the discant and the bass first, then the discant's parts moved
(`../build/assembly/d_*.stl`), light keys for all 64 (stem, felt, cap; the full
buttons are on the two sides' own pages), and the phone page `phone.html`.

Checked by solid intersection (`../bass/spec.md` §4): the whole discant, mated,
touches none of the bass's parts.

## Stored [given: plugged like the old hinge's two positions; the bass covers the discant's keys]

The earlier design folded the two halves on hinges (../../pcb/README.md, eziach.png);
here the gauge plates are the plug and the bass has two sockets:

- **Playing:** the plates slide along the bass's y into the inner holders at the bottom
  of its back wall (as before).
- **Stored:** the discant turns 90° about x, its keys toward the box's thin back wall,
  and back by its own slope (rows climb 3 per 16: atan(3/16) = 10.62°) [given: use the
  slope], so that caps and housing lie parallel to the wall, 1 mm off it, 27.8 mm thick
  instead of 37.6. Its plates lie in the same slope plane [given: gauges in the slope's
  plane], so they point straight up the bass's z: the discant slides straight up until
  they sit 6 mm deep in a short socket in a pocket in the deck's underside [given: short
  socket]. The box, 265 wide and straight [given: widen it], covers all 46 keys; the
  deck lies over the discant's back, the playing mount under its front edge.

With the gauges in the slope plane, the playing position too has the discant's slope
plane level (the plates still along the bass's y): the discant hangs 3.3 mm below the
bass's bottom instead of 16.6.

Below the stored discant's front edge stays 9.3 mm (the socket's 8.3 mm and 1 mm) above
the playing mount, the travel to slide it on and off; for that the box is 5.3 mm longer
than the hand plate [given: +3 mm, then the latch's 2.3]. The bass's box below the deck is 11.2 thin [given: 4.8 thinner,
with a 6 mm battery], so the stored discant lies 4.8 closer; the deck's back face
(27.8) is then the package's back. Checked:
clear of case, cover, lid, battery and the bass's keys both seated and 9.3 mm lower; 2.7 mm of deck
stay under the back row's springs. Package **282.9 × 40.3 × 149.5 mm (1.7 L)**.
`../bass/link.scad`: `to_store()`, `store_socket()`, `store_pocket()`; the page's Stored
switch shows it.

## Latches [given: in both positions]

Both are in the inner holders (`../strain_gauge/inner_holder.scad`): a spring tongue in
each holder's top wall either side, its tooth in the plate's inner slot between web and
column, behind the slot's closed end. Sliding on, the tooth rides over the W's bottom
block and drops into the slot. It touches only the W, never the column or the fixed
arms, so the force still runs through the gauges' columns.

- **Playing** (mount on the box's back wall): square tooth, a positive lock that holds
  the strap's pull. To take the bass off, lift the lug on each tongue's tip (four in
  all, from above, between box and discant) and slide.
- **Stored** (socket under the deck): 45° tooth, a detent; four of them hold about 9 N
  [estimate: tongue 3 × 1 × 11 mm, PLA, E 3500 MPa, 0.6 mm deflection, friction 0.3]
  against the discant's weight (about 3.5 N [estimate]); a firm pull down releases it.

Checked: seated, teeth and plates clear; moved 0.3 mm in the pull-off direction, the
teeth of both positions meet the slots' ends.

Open: the electrical connector between the halves; the tongue's strain on bending is
about 0.7 % [estimate], fine for PETG, at the limit for PLA.
