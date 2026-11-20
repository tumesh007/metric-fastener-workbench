/* Parametric printable metric fastener workbench.
   ISO coarse pitch series M1–M10.
   Complete FreeCAD Fasteners Workbench taxonomy:
   - Screws & Bolts (Socket Cap, Hex Head, Hex Flange, Button, Button Flange, Countersunk, Pan, Shoulder, Thumb with Collar, Flat Thumb, Wing)
   - Set Screws (Flat Point, Cone Point)
   - Wood & Tapping (Hex Wood, Pan Tapping, Countersunk Tapping)
   - Nuts (Hex Standard, Jam Thin, Flange, Nyloc, Acorn Dome, Wing, Thumb Collar, Flat Thumb, Square)
   - Washers (Flat, Fender, Spring Lock)
   - Rods, T-Slots, Inserts & Anchors (Threaded Rod, 2020/3030 T-Nut, Heat-Set Insert, Wall Plug)
*/

function nominal_d(s) = s=="M1"?1:s=="M1.2"?1.2:s=="M1.4"?1.4:s=="M1.6"?1.6:s=="M1.8"?1.8:s=="M2"?2:s=="M2.5"?2.5:s=="M3"?3:s=="M3.5"?3.5:s=="M4"?4:s=="M5"?5:s=="M6"?6:s=="M7"?7:s=="M8"?8:s=="M9"?9:10;
function nominal_pitch(s) = s=="M1"?0.25:s=="M1.2"?0.25:s=="M1.4"?0.3:s=="M1.6"?0.35:s=="M1.8"?0.35:s=="M2"?0.4:s=="M2.5"?0.45:s=="M3"?0.5:s=="M3.5"?0.6:s=="M4"?0.7:s=="M5"?0.8:s=="M6"?1:s=="M7"?1:s=="M8"?1.25:s=="M9"?1.25:1.5;
function nominal_af(s) = s=="M1"?2:s=="M1.2"?2.5:s=="M1.4"?2.5:s=="M1.6"?3.2:s=="M1.8"?3.5:s=="M2"?4:s=="M2.5"?5:s=="M3"?5.5:s=="M3.5"?6:s=="M4"?7:s=="M5"?8:s=="M6"?10:s=="M7"?11:s=="M8"?13:s=="M9"?14:17;

part = "thumb_screw";
size = "M3";
bolt_length = 16;
drive_type = "hex_drive";
tslot_series = 20;

head_height = 3;
head_diameter = 5.5;
drive_size = 2.5;
drive_width = 0.7;
drive_depth = 1.2;
knurl_depth = 1.2;
nut_height = 2.4;
nut_across_flats = 5.5;
thread_clearance = 0.20;
tapping_pitch = 1;
insert_diameter = 4.6;
insert_length = 4.5;
insert_flange_diameter = 5.2;
insert_flange_height = 0.5;
insert_knurl_count = 8;
plug_diameter = 7.5;
plug_length = 18;
plug_bore_diameter = 1.7;
plug_slot_width = 0.8;
bolt_count = 4;
nut_count = 4;
$fn = 36;

major_d = nominal_d(size);
pitch = nominal_pitch(size);
minor_d = major_d - 1.08*pitch;
thread_depth = 0.60*pitch;

module helix_profile(root_r, depth, p, thread_len) {
    crest=0.12*p; base=0.72*p;
    linear_extrude(height=thread_len+2*p,twist=360*(thread_len+2*p)/p,slices=max(16,ceil((thread_len+2*p)*12/p)),convexity=10)
        translate([root_r,0,0]) polygon([[0,-base/2],[depth,-crest/2],[depth,crest/2],[0,base/2]]);
}
module external_threaded_shaft(len) {
    intersection(){ union(){ cylinder(d=minor_d+0.15,h=len); translate([0,0,-pitch]) helix_profile(minor_d/2-0.03,thread_depth,pitch,len); } cylinder(d=major_d,h=len); }
}
module hex_prism(af,h){cylinder(r=af/sqrt(3),h=h,$fn=6);}

module drive_recess(depth) {
    if(drive_type=="hex_drive") cylinder(r=drive_size/sqrt(3),h=depth+0.05,$fn=6);
    else if(drive_type=="torx") for(i=[0:2]) rotate([0,0,i*60]) cube([drive_size*0.35,drive_size,depth+0.05],center=true);
    else if(drive_type=="phillips") union(){translate([-drive_width/2,-drive_size/2,0]) cube([drive_width,drive_size,depth+0.05]);translate([-drive_size/2,-drive_width/2,0]) cube([drive_size,drive_width,depth+0.05]);}
    else if(drive_type=="slotted") translate([-drive_size/2,-drive_width/2,0]) cube([drive_size,drive_width,depth+0.05]);
}

// Screws & Bolts
module socket_cap_model() {
    h = head_height; cut = min(drive_depth, h - 0.2);
    translate([0,0,bolt_length+h]) rotate([180,0,0]) union() {
        external_threaded_shaft(bolt_length);
        translate([0,0,bolt_length]) difference() {
            cylinder(d=head_diameter, h=h);
            translate([0,0,h-cut]) drive_recess(cut);
        }
    }
}

module hex_bolt_model() {
    h = head_height;
    translate([0,0,bolt_length+h]) rotate([180,0,0]) union() {
        external_threaded_shaft(bolt_length);
        translate([0,0,bolt_length]) hex_prism(head_diameter, h);
    }
}

module hex_flange_bolt_model() {
    h = head_height; fl_d = head_diameter * 1.32; fl_h = max(0.5, h * 0.25);
    translate([0,0,bolt_length+h]) rotate([180,0,0]) union() {
        external_threaded_shaft(bolt_length);
        translate([0,0,bolt_length]) union() {
            cylinder(d=fl_d, h=fl_h);
            translate([0,0,fl_h]) hex_prism(head_diameter, h - fl_h);
        }
    }
}

module button_head_model() {
    h = head_height; cut = min(drive_depth, h - 0.2);
    translate([0,0,bolt_length+h]) rotate([180,0,0]) union() {
        external_threaded_shaft(bolt_length);
        translate([0,0,bolt_length]) difference() {
            resize([head_diameter, head_diameter, h*1.8]) sphere(d=head_diameter);
            translate([0,0,-h]) cube([head_diameter*2, head_diameter*2, h*2], center=true);
            translate([0,0,h*0.8-cut]) drive_recess(cut);
        }
    }
}

module button_flange_model() {
    h = head_height; fl_d = head_diameter * 1.35; fl_h = max(0.4, h * 0.22); cut = min(drive_depth, h - 0.2);
    translate([0,0,bolt_length+h]) rotate([180,0,0]) union() {
        external_threaded_shaft(bolt_length);
        translate([0,0,bolt_length]) union() {
            cylinder(d=fl_d, h=fl_h);
            translate([0,0,fl_h]) difference() {
                resize([head_diameter, head_diameter, (h-fl_h)*1.8]) sphere(d=head_diameter);
                translate([0,0,-(h-fl_h)]) cube([head_diameter*2, head_diameter*2, (h-fl_h)*2], center=true);
                translate([0,0,(h-fl_h)*0.8-cut]) drive_recess(cut);
            }
        }
    }
}

module countersunk_screw_model() {
    h = head_height; cut = min(drive_depth, h - 0.2);
    translate([0,0,bolt_length+h]) rotate([180,0,0]) union() {
        external_threaded_shaft(bolt_length);
        translate([0,0,bolt_length]) difference() {
            cylinder(d1=major_d, d2=head_diameter, h=h);
            translate([0,0,h-cut]) drive_recess(cut);
        }
    }
}

module pan_head_model() {
    h = head_height; cut = min(drive_depth, h - 0.2);
    translate([0,0,bolt_length+h]) rotate([180,0,0]) union() {
        external_threaded_shaft(bolt_length);
        translate([0,0,bolt_length]) difference() {
            cylinder(d1=head_diameter*0.95, d2=head_diameter, h=h);
            translate([0,0,h-cut]) drive_recess(cut);
        }
    }
}

module shoulder_screw_model() {
    sh_d = major_d + 1.5; sh_len = max(4, bolt_length * 0.5); th_len = bolt_length; h = head_height; cut = min(drive_depth, h - 0.2);
    translate([0,0,sh_len+th_len+h]) rotate([180,0,0]) union() {
        external_threaded_shaft(th_len);
        translate([0,0,th_len]) cylinder(d=sh_d, h=sh_len);
        translate([0,0,th_len+sh_len]) difference() {
            cylinder(d=sh_d * 1.4, h=h);
            translate([0,0,h-cut]) drive_recess(cut);
        }
    }
}

module thumb_screw_model() {
    collar_h = min(head_height * 0.45, max(1.2, major_d * 0.55));
    wheel_h = head_height - collar_h;
    total_h = head_height;
    wheel_d = max(head_diameter, major_d * 3.2);
    collar_d = max(major_d * 1.8, head_diameter * 0.65);
    n_teeth = max(18, round(wheel_d * 1.4));
    tooth_depth = max(0.2, knurl_depth);
    tooth_w = max(1.1, 3.14159 * wheel_d / (n_teeth * 1.6));
    cut = min(drive_depth, wheel_h - 0.2);
    translate([0,0,bolt_length+total_h]) rotate([180,0,0]) difference() {
        union() {
            external_threaded_shaft(bolt_length + 0.05);
            translate([0,0,bolt_length]) cylinder(d=collar_d, h=collar_h + 0.05);
            translate([0,0,bolt_length+collar_h]) {
                cylinder(d=wheel_d, h=wheel_h);
                for(i=[0:n_teeth-1]) rotate([0,0,i*360/n_teeth]) translate([wheel_d/2 - tooth_depth*0.2, -tooth_w/2, 0]) cube([tooth_depth*1.2, tooth_w, wheel_h]);
            }
        }
        if(drive_type!="none" && cut>0.05) translate([0,0,bolt_length+total_h-cut]) drive_recess(cut);
    }
}

module flat_thumb_screw_model() {
    wheel_d = max(head_diameter, major_d * 3.0);
    wheel_h = head_height;
    n_teeth = max(18, round(wheel_d * 1.4));
    tooth_depth = max(0.2, knurl_depth);
    tooth_w = max(1.1, 3.14159 * wheel_d / (n_teeth * 1.6));
    cut = min(drive_depth, wheel_h - 0.2);
    translate([0,0,bolt_length+wheel_h]) rotate([180,0,0]) difference() {
        union() {
            external_threaded_shaft(bolt_length + 0.05);
            translate([0,0,bolt_length]) {
                cylinder(d=wheel_d, h=wheel_h);
                for(i=[0:n_teeth-1]) rotate([0,0,i*360/n_teeth]) translate([wheel_d/2 - tooth_depth*0.2, -tooth_w/2, 0]) cube([tooth_depth*1.2, tooth_w, wheel_h]);
            }
        }
        if(drive_type!="none" && cut>0.05) translate([0,0,bolt_length+wheel_h-cut]) drive_recess(cut);
    }
}

module wing_screw_model() {
    base_d = max(major_d * 2.0, head_diameter * 0.8);
    h = head_height;
    wing_span = max(major_d * 4.6, 16);
    wing_th = max(2.2, major_d * 0.6);
    union() {
        cylinder(d=base_d, h=h);
        translate([0,0,h/2]) cube([wing_span, wing_th, h], center=true);
        for(i=[-1,1]) translate([i*(wing_span/2 - wing_th/2), 0, h/2]) cylinder(d=wing_th, h=h, center=true);
        translate([0,0,h]) external_threaded_shaft(bolt_length);
    }
}

module oval_wing_screw_model() {
    span = max(major_d * 5.2, 20);
    th = max(major_d * 0.9, 4.0);
    h = head_height;
    hub_d = max(major_d * 2.2, head_diameter * 0.85);
    union() {
        cylinder(d=hub_d, h=h);
        hull() {
            cylinder(d=hub_d, h=h);
            for(i=[-1,1]) translate([i*(span/2 - th/2), 0, h/2]) cylinder(d=th, h=h, center=true);
        }
        translate([0,0,h]) external_threaded_shaft(bolt_length);
    }
}

// Set Screws
module set_screw_flat_model() {
    cut = min(drive_depth, bolt_length * 0.4);
    difference() {
        external_threaded_shaft(bolt_length);
        translate([0,0,bolt_length-cut]) drive_recess(cut);
    }
}

module set_screw_cone_model() {
    cut = min(drive_depth, bolt_length * 0.4); tip_h = min(1.5, bolt_length * 0.25);
    difference() {
        union() {
            cylinder(d1=0.4, d2=major_d, h=tip_h);
            translate([0,0,tip_h]) external_threaded_shaft(bolt_length - tip_h);
        }
        translate([0,0,bolt_length-cut]) drive_recess(cut);
    }
}

// Wood & Tapping
module tapping_shaft(csk=false) {
    root = max(0.25, major_d - 0.95 * tapping_pitch);
    tip = min(bolt_length * 0.32, 2.2 * tapping_pitch);
    threaded = max(0.5, bolt_length - tip);
    intersection() {
        union() {
            translate([0,0,tip]) cylinder(d=root, h=threaded);
            cylinder(d1=0.35, d2=root, h=tip);
            translate([0,0,tip-tapping_pitch]) helix_profile(root/2-0.025, 0.58*tapping_pitch, tapping_pitch, threaded);
        }
        union() {
            translate([0,0,tip]) cylinder(d=major_d, h=threaded);
            cylinder(d1=0.35, d2=major_d, h=tip+0.01);
        }
    }
}

module wood_hex_screw_model() {
    h = head_height;
    translate([0,0,bolt_length+h]) rotate([180,0,0]) union() {
        tapping_shaft();
        translate([0,0,bolt_length]) hex_prism(head_diameter, h);
    }
}

module tapping_screw_model() {
    h = head_height; cut = min(drive_depth, h - 0.2);
    translate([0,0,bolt_length+h]) rotate([180,0,0]) union() {
        tapping_shaft();
        translate([0,0,bolt_length]) difference() {
            cylinder(d1=head_diameter*0.95, d2=head_diameter, h=h);
            translate([0,0,h-cut]) drive_recess(cut);
        }
    }
}

module csk_tapping_screw_model() {
    h = head_height; cut = min(drive_depth, h - 0.2);
    translate([0,0,bolt_length+h]) rotate([180,0,0]) union() {
        tapping_shaft();
        translate([0,0,bolt_length]) difference() {
            cylinder(d1=major_d, d2=head_diameter, h=h);
            translate([0,0,h-cut]) drive_recess(cut);
        }
    }
}

// Nuts
module hex_nut_core(h, extra_body=0) {
    difference() {
        children();
        union() {
            translate([0,0,-0.1]) cylinder(d=minor_d+2*thread_clearance, h=h+extra_body+0.2);
            translate([0,0,-pitch]) helix_profile((minor_d+2*thread_clearance)/2-0.02, thread_depth, pitch, h+extra_body+0.5);
            translate([0,0,-0.01]) cylinder(d1=major_d+2*thread_clearance, d2=minor_d+2*thread_clearance, h=min(0.45,h/4)+0.02);
            translate([0,0,h+extra_body-min(0.45,h/4)]) cylinder(d1=minor_d+2*thread_clearance, d2=major_d+2*thread_clearance, h=min(0.45,h/4)+0.02);
        }
    }
}

module hex_nut_model() { hex_nut_core(nut_height) hex_prism(nut_across_flats, nut_height); }
module jam_nut_model() { jh = max(1.2, nut_height * 0.55); hex_nut_core(jh) hex_prism(nut_across_flats, jh); }
module flange_nut_model() {
    fl_d = nut_across_flats * 1.32; fl_h = max(0.5, nut_height * 0.24);
    hex_nut_core(nut_height) union() {
        cylinder(d=fl_d, h=fl_h);
        translate([0,0,fl_h]) hex_prism(nut_across_flats, nut_height - fl_h);
    }
}
module nyloc_nut_model() {
    col_h = nut_height * 0.35;
    hex_nut_core(nut_height, col_h) union() {
        hex_prism(nut_across_flats, nut_height);
        translate([0,0,nut_height]) cylinder(d=nut_across_flats*0.9, h=col_h);
    }
}
module acorn_nut_model() {
    dom_h = nut_across_flats * 0.45;
    difference() {
        union() {
            hex_prism(nut_across_flats, nut_height);
            translate([0,0,nut_height]) intersection() {
                sphere(d=nut_across_flats*0.95);
                cylinder(d=nut_across_flats*0.95, h=dom_h);
            }
        }
        union() {
            translate([0,0,-0.1]) cylinder(d=minor_d+2*thread_clearance, h=nut_height + 0.1);
            translate([0,0,-pitch]) helix_profile((minor_d+2*thread_clearance)/2-0.02, thread_depth, pitch, nut_height);
        }
    }
}
module wing_nut_model() {
    wing_span = max(major_d * 4.6, 16);
    wing_th = max(2.2, major_d * 0.6);
    wing_h = max(7.0, nut_across_flats * 1.3);
    hex_nut_core(nut_height) union() {
        hex_prism(nut_across_flats, nut_height);
        for(i=[-1,1]) translate([i*nut_across_flats*0.42, 0, 0]) hull() {
            cylinder(d=wing_th, h=nut_height);
            translate([i*(wing_span/2 - nut_across_flats*0.42 - wing_th/2), 0, wing_h - wing_th]) cylinder(d=wing_th, h=wing_th);
        }
    }
}
module thumb_nut_model() {
    collar_h = min(nut_height * 0.45, max(1.2, major_d * 0.55));
    wheel_h = nut_height - collar_h;
    tot_h = nut_height;
    wheel_d = max(nut_across_flats * 1.4, major_d * 3.2);
    collar_d = max(major_d * 1.8, nut_across_flats * 0.9);
    n_teeth = max(18, round(wheel_d * 1.4));
    tooth_depth = max(0.2, knurl_depth);
    tooth_w = max(1.1, 3.14159 * wheel_d / (n_teeth * 1.6));
    hex_nut_core(tot_h) union() {
        cylinder(d=collar_d, h=collar_h);
        translate([0,0,collar_h]) union() {
            cylinder(d=wheel_d, h=wheel_h);
            for(i=[0:n_teeth-1]) rotate([0,0,i*360/n_teeth]) translate([wheel_d/2 - tooth_depth*0.2, -tooth_w/2, 0]) cube([tooth_depth*1.2, tooth_w, wheel_h]);
        }
    }
}
module flat_thumb_nut_model() {
    wheel_d = max(nut_across_flats * 1.4, major_d * 3.0);
    wheel_h = nut_height;
    n_teeth = max(18, round(wheel_d * 1.4));
    tooth_depth = max(0.2, knurl_depth);
    tooth_w = max(1.1, 3.14159 * wheel_d / (n_teeth * 1.6));
    hex_nut_core(wheel_h) union() {
        cylinder(d=wheel_d, h=wheel_h);
        for(i=[0:n_teeth-1]) rotate([0,0,i*360/n_teeth]) translate([wheel_d/2 - tooth_depth*0.2, -tooth_w/2, 0]) cube([tooth_depth*1.2, tooth_w, wheel_h]);
    }
}
module square_nut_model() {
    hex_nut_core(nut_height) translate([-nut_across_flats/2, -nut_across_flats/2, 0]) cube([nut_across_flats, nut_across_flats, nut_height]);
}

// Washers
module flat_washer_model() {
    inner_d = major_d + 0.35; outer_d = max(major_d * 2.2, major_d + 3.5); th = max(0.5, major_d * 0.18);
    difference() { cylinder(d=outer_d, h=th); translate([0,0,-0.1]) cylinder(d=inner_d, h=th+0.2); }
}
module fender_washer_model() {
    inner_d = major_d + 0.35; outer_d = max(major_d * 3.2, major_d + 6.0); th = max(0.8, major_d * 0.25);
    difference() { cylinder(d=outer_d, h=th); translate([0,0,-0.1]) cylinder(d=inner_d, h=th+0.2); }
}
module spring_washer_model() {
    inner_d = major_d + 0.35; outer_d = max(major_d * 1.8, major_d + 2.5); th = max(0.7, major_d * 0.25);
    lift = max(0.4, th * 0.65); gap_deg = 20;
    difference() {
        linear_extrude(height=th+lift, twist=360-gap_deg, slices=36, convexity=4)
            translate([inner_d/2, 0, 0]) square([(outer_d - inner_d)/2, th]);
        rotate([0,0,-gap_deg/2]) translate([0, -outer_d*1.5, -0.1]) cube([outer_d*2, outer_d*3, th+lift+0.2]);
    }
}

// Rods & T-Slots
module threaded_rod_model() { external_threaded_shaft(bolt_length); }
module tslot_nut_model() {
    slot_w = tslot_series==30 ? 8 : 6; nut_w = tslot_series==30 ? 14 : 10;
    nut_l = tslot_series==30 ? 16 : 11.5; nut_h = tslot_series==30 ? 5 : 4; neck_h = tslot_series==30 ? 2 : 1.5;
    base_h = nut_h - neck_h;
    hex_nut_core(nut_h) union() {
        translate([0,0,base_h/2]) cube([nut_l, nut_w, base_h], center=true);
        translate([0,0,base_h+neck_h/2]) cube([nut_l*0.65, slot_w-0.4, neck_h], center=true);
    }
}

// Inserts & Anchors
module heat_set_insert_model() {
    inner_root = minor_d + 2*thread_clearance; body_h = max(0.5, insert_length - insert_flange_height);
    difference() {
        union() {
            translate([0,0,insert_flange_height]) cylinder(d=insert_diameter, h=body_h);
            if(insert_flange_diameter>0) cylinder(d=insert_flange_diameter, h=insert_flange_height);
            if(insert_knurl_count>0) for(i=[0:insert_knurl_count-1]) rotate([0,0,i*360/insert_knurl_count]) translate([insert_diameter/2-0.10, -0.16, insert_flange_height]) cube([0.30, 0.32, body_h]);
        }
        translate([0,0,-0.1]) cylinder(d=inner_root, h=insert_length+0.2);
        translate([0,0,-pitch]) helix_profile(inner_root/2-0.02, thread_depth, pitch, insert_length);
    }
}
module wall_plug_model() {
    tip = min(plug_length*0.22, plug_diameter*1.4); body = plug_length - tip; slot_start = plug_length*0.30;
    difference() {
        union() {
            cylinder(d=plug_diameter, h=body);
            translate([0,0,body]) cylinder(d1=plug_diameter, d2=plug_diameter*0.30, h=tip);
            cylinder(d1=plug_diameter*1.18, d2=plug_diameter, h=min(1.2, plug_length*0.12));
            for(i=[0:3]) rotate([0,0,i*90]) translate([plug_diameter*0.42, -0.28, slot_start]) cube([plug_diameter*0.18, 0.56, body-slot_start]);
        }
        translate([0,0,-0.1]) cylinder(d=plug_bore_diameter, h=plug_length+0.2);
        if(plug_slot_width>0) for(i=[0:1]) rotate([0,0,i*90]) translate([-plug_slot_width/2, -plug_diameter, slot_start]) cube([plug_slot_width, plug_diameter*2, plug_length-slot_start+0.1]);
    }
}

module winged_wall_plug_model() {
    tip = min(plug_length*0.22, plug_diameter*1.4); body = plug_length - tip;
    w_span = plug_diameter * 0.28; w_th = max(0.6, plug_diameter * 0.12);
    mid_z = plug_length * 0.35; bot_z = plug_length * 0.65;
    wing_h = max(2.5, plug_length * 0.18);
    difference() {
        union() {
            cylinder(d=plug_diameter, h=body);
            translate([0,0,body]) cylinder(d1=plug_diameter, d2=plug_diameter*0.30, h=tip);
            cylinder(d1=plug_diameter*1.18, d2=plug_diameter, h=min(1.2, plug_length*0.12));
            for(i=[0:2]) rotate([0,0,i*120]) translate([plug_diameter/2 - 0.2, -w_th/2, mid_z])
                linear_extrude(height=wing_h, scale=[0.3, 0.6]) square([w_span, w_th]);
            for(i=[0:2]) rotate([0,0,i*120 + 60]) translate([plug_diameter/2 - 0.2, -w_th/2, bot_z])
                linear_extrude(height=wing_h, scale=[0.3, 0.6]) square([w_span, w_th]);
        }
        translate([0,0,-0.1]) cylinder(d=plug_bore_diameter, h=plug_length+0.2);
    }
}

module batch_model() {
    bolt_spacing = max(head_diameter, major_d) + 5; nut_spacing = nut_across_flats + 5; nut_row_y = max(head_diameter, nut_across_flats) + 6;
    if(bolt_count>0) for(i=[0:bolt_count-1]) translate([i*bolt_spacing, 0, 0]) socket_cap_model();
    if(nut_count>0) for(i=[0:nut_count-1]) translate([i*nut_spacing, nut_row_y, 0]) hex_nut_model();
}

if(part=="socket_cap" || part=="bolt") socket_cap_model();
else if(part=="hex_bolt") hex_bolt_model();
else if(part=="hex_flange_bolt") hex_flange_bolt_model();
else if(part=="button_head") button_head_model();
else if(part=="button_flange") button_flange_model();
else if(part=="countersunk_screw") countersunk_screw_model();
else if(part=="pan_head") pan_head_model();
else if(part=="shoulder_screw") shoulder_screw_model();
else if(part=="thumb_screw") thumb_screw_model();
else if(part=="flat_thumb_screw") flat_thumb_screw_model();
else if(part=="wing_screw") wing_screw_model();
else if(part=="oval_wing_screw") oval_wing_screw_model();
else if(part=="set_screw_flat" || part=="set_screw") set_screw_flat_model();
else if(part=="set_screw_cone") set_screw_cone_model();
else if(part=="wood_hex_screw") wood_hex_screw_model();
else if(part=="tapping_screw" || part=="self_tapping") tapping_screw_model();
else if(part=="csk_tapping_screw") csk_tapping_screw_model();
else if(part=="hex_nut" || part=="nut") hex_nut_model();
else if(part=="jam_nut") jam_nut_model();
else if(part=="flange_nut") flange_nut_model();
else if(part=="nyloc_nut") nyloc_nut_model();
else if(part=="acorn_nut") acorn_nut_model();
else if(part=="wing_nut") wing_nut_model();
else if(part=="thumb_nut") thumb_nut_model();
else if(part=="flat_thumb_nut") flat_thumb_nut_model();
else if(part=="square_nut") square_nut_model();
else if(part=="flat_washer" || part=="washer") flat_washer_model();
else if(part=="fender_washer") fender_washer_model();
else if(part=="spring_washer") spring_washer_model();
else if(part=="threaded_rod") threaded_rod_model();
else if(part=="tslot_nut") tslot_nut_model();
else if(part=="heat_set_insert") heat_set_insert_model();
else if(part=="wall_plug") wall_plug_model();
else if(part=="winged_wall_plug") winged_wall_plug_model();
else batch_model();
