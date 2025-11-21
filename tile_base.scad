// Copyright 2025 - Marcin Raczkowski (Marmot.Tech)
//
// Licence: https://creativecommons.org/licenses/by-sa/4.0/
//
// Reference/Specs: https://github.com/FrameworkComputer/Framework-Desktop/blob/main/Tiles/FRAMEWORK_DESKTOP_BLANK_TILE_V0.pdf

/* [General] */

// What element to display
tile_type = "all"; // ["all", "blank", "horizontal", "cross", "frame", "mounts (debug)"]
// Colorize elements (preview only)
$colorize_elements = true;
// Tolerance [mm]
tolerance = 0.4;
// Hatch Angle [deg]
hatch_angle = 45;
// Hatch Line Thickness [mm]
hatch_thickness = 1.125;

/* [Specification (Avoid Changing)] */

// Front Thickness [mm]
front_thickness = 2.3; // .1
// Frame Thickness [mm]
frame_thickness = 2.3;
// Inner Size
inner_size = 21.0;

// Width/Height of the singular tile [mm]
tile_size = 28.5;

// All height measurements are from the base

raised_edge_size = [2.8, 10.0, 2.6];

constraint_size = [1.6, 3.2, 4.4];
constraint_offset = 11.97;
constraint_slope = 0.96; //0.01

hook_size   = [1.0, 6.0, 4.4];
hook_offset = 12.90;
hook_base   = [3.2, 1.6];
hook_thickness = 0.4;

/* [Hidden] */

$ff = 0.02; // fudge factor - to fix any rendering issues
width = tile_size - tolerance;
height = tile_size - tolerance;
trim = inner_size/2;

module part_color(c) {
  if ($preview && $colorize_elements) {
    color(c) children();
  } else children();
}

module raised_edges() {
  for(r = [0:3]) {
    rotate([0,0,90*r])
      translate([(width - raised_edge_size[0]) / 2, 0, raised_edge_size[2]/2])
        cube(raised_edge_size, center=true);
    ;
  }
}

module constraints(base = frame_thickness) {
  for(r = [0:3]) {
    rotate([0,0,90*r])
      translate([constraint_offset + constraint_size[0]/2, 0, base])
        linear_extrude(constraint_size[2]-base, scale=constraint_slope)
        square([constraint_size[0], constraint_size[1]], center=true);
    ;
  }
}

module hooks(w=hook_thickness, h=1.2, trim_margin = tolerance) {
  hd = hook_size[0];
  hw = hook_size[1];
  hh = hook_size[2];
  
  bw = hook_base[0];
  bh = hook_base[1];
  
  hook_profile = [
    [0, 0],   // top middle
    [w, w/2],   // hook top
    [w, h-w],
    [0, h],   // hook bottom
    [0, hh],  // bottom front
    [-hd, hh], // top back
    [-hd, 0], // top back
  ];
  
  part_color("red") for(r = [0:3])
    rotate([0, 0, 45 + 90*r]) {
      intersection(){
        // Cube that trims the hook to the inner edge of the frame
        translate([(inner_size-trim)*sqrt(2)/2-trim_margin, 0, bh+trim/2])
          rotate([0, 0, 45]) cube(trim, center=true);
        // Hook shape
        translate([hook_offset, 0, hook_size[2]])
          rotate([-90, 0, 0]) 
            linear_extrude(hook_size[1], center=true) 
              polygon(hook_profile);
      }
        // Base to attach to frame
      translate([hook_offset-hd, -hw/2, 0])
        cube([bw+hd, hw, bh]);
    }
}

// Cutout around the neck of the hook that coerces the slicer 
// to generate stronger borders / walls around the hook neck.
module hook_cutout(b=hook_base[1]) {
  trim_margin = 0;
  h = hook_size[2] - b;
  
  for(r = [0:3])
    rotate([0, 0, 45 + 90*r])
      intersection(){
        // Cube that trims the hook to the inner edge of the frame
        translate([(inner_size-trim)*sqrt(2)/2-trim_margin, 0, b+trim/2])
          rotate([0, 0, 45]) cube(trim, center=true);
        translate([hook_offset - hook_size[0]/2, 0, b+h/2])
          cube([hook_size[0]+tolerance, hook_size[1]+tolerance, h], center=true);
      }
}


module frame() {
  difference() { 
    linear_extrude(frame_thickness) 
      difference() {
        square(tile_size, center=true);
        square(inner_size, center=true);
      }
    hook_cutout();
  }
}

module solid_fill() {
  difference() {
    linear_extrude(front_thickness)
      square(inner_size, center=true);
    hook_cutout();
  }
}


module crosshatch_fill(angle = hatch_angle, thickness = hatch_thickness) {
  n = ceil(inner_size / thickness / 2)+1;
  difference() {
    linear_extrude(front_thickness) intersection() {
      square(inner_size, center=true);
      
      union() for(i = [n/-2:n/2]) {
        rotate([0, 0, angle]) translate([0, thickness*2*i])
          square([inner_size * 2, thickness], center=true);
      }
    }
    
    hook_cutout();
  }
}

module horizontal_fill() {
  crosshatch_fill(0);
}


/* --- */

module mounts() {
  part_color("maroon") raised_edges();
  part_color("orange") constraints();
  part_color("red")    hooks();
}

module full_frame() {
  mounts();
  part_color("blue")   frame();
}

module blank_tile() {
  full_frame();
  solid_fill();
}

if (tile_type == "all") {
  translate([ 0,  0, 0]) { full_frame(); }
  translate([ 0, 30, 0]) { full_frame(); solid_fill(); }
  translate([30, 30, 0]) { full_frame(); crosshatch_fill(); }
  translate([30,  0, 0]) { full_frame(); horizontal_fill(); }
} else if (tile_type == "mounts") {
  mounts();
} else if (tile_type == "frame") {
  full_frame();
} else if (tile_type == "blank") {
  blank_tile();
} else if (tile_type == "cross") {
  full_frame();
  crosshatch_fill();
} else if (tile_type == "horizontal") {
  full_frame();
  horizontal_fill();
};


/*
 * Usage:
 *
 * include <tile_base.scad>
 * tile_type = "none";
 * $colorize_parts = false;
 *
 * union() {
 *   full_frame(); // (or just mounts())
 *   my_design();
 * }
 *
 * // or
 *
 * difference(){
 *   blank_tile();
 *   carve_out();
 * }
 *
 */