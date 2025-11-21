include <tile_base.scad>
tile_type = "blank";
$colorize_parts = false;
$fn = 70;
union() {
    full_frame();
    mount();
}
module mount() {
    translate([6.5, 0, -5.5]){
        cylinder(7.8, 1.75, 1.75);
        cylinder(1,3,3);
    }
    
}
