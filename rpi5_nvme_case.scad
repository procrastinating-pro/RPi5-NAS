// ==============================================================================
// OBUDOWA RASPBERRY PI 5 + M.2 HAT+ (NAKŁADANA OD GÓRY - BEZ SZYN I ZATRZASKÓW)
// ==============================================================================

$fn = 60;

// --- CO CHCESZ WYGENEROWAĆ? ---
// "both" = dół i góra obok siebie (do druku)
// "bottom" = tylko dół | "top" = tylko góra | "assembled" = podgląd złożenia
render_mode = "both"; 

// --- KONFIGURACJA I SKALOWANIE LOGO NA GÓRNYM DEKLU ---
logo_type = "custom_text";            // ["custom_text", "raspberry", "svg", "none"]
logo_string = "ToMati";       // Tekst dla trybu "custom_text"
logo_subtext = "NAS // RPi5"; // Podpis pod napisem
logo_svg_file = "logo.svg";   // Plik SVG (dla logo_type = "svg")
logo_depth = 0.6;             // Głębokość graweru [mm]

logo_scale = 1.0;             // Skala logo
logo_svg_target_w = 36.0;     // Szerokość SVG w mm przy skali 1.0
logo_rot = 0;                 // Obrót logo w stopniach
logo_offset_x = 0.0;          // Przesunięcie X
logo_offset_y = 0.0;          // Przesunięcie Y
logo_auto_vent_gap = true;    // Automatyczna przerwa w wentylacji wokół logo

// --- GŁÓWNE PARAMETRY WYMIAROWE ---
nvme_heatsink_extra_h = 18.0; // Zapas wysokości na radiator NVMe
wall = 2.4;                   // Grubość ścianek
bottom_thick = 2.0;           // Grubość podłogi i sufitu
pcb_clearance = 0.6;          // Luz wokół płytki PCB

// --- WYMIARY BAZOWE RASPBERRY PI 5 ---
pcb_l = 85.0;
pcb_w = 56.0;
pcb_thick = 1.6;
corner_r = 3.5;

// Kołki montażowe RPi 5
hole_dx = 58.0;
hole_dy = 49.0;
hole_offset = 3.5;
standoff_h = 4.5;
standoff_od = 6.2;
standoff_id = 2.5;

// Wysokość bazowa do M.2 HAT+ i całkowita wysokość
hat_base_h = standoff_h + pcb_thick + 16.0 + 1.6; 
inner_l = pcb_l + 2 * pcb_clearance;
inner_w = pcb_w + 2 * pcb_clearance;
inner_h = hat_base_h + nvme_heatsink_extra_h;

outer_l = inner_l + 2 * wall;
outer_w = inner_w + 2 * wall;
outer_h = inner_h + 2 * bottom_thick;

// Wysokość podziału obudowy
split_z = bottom_thick + standoff_h + pcb_thick + 15.5;
lip_h = 2.5;
lip_tol = 0.25;               // Luz pasowania kołnierza

// ==============================================================================
// MODUŁY POMOCNICZE I LOGO
// ==============================================================================

module rounded_box(l, w, h, r) {
    hull() {
        translate([r, r, 0]) cylinder(r=r, h=h);
        translate([l-r, r, 0]) cylinder(r=r, h=h);
        translate([r, w-r, 0]) cylinder(r=r, h=h);
        translate([l-r, w-r, 0]) cylinder(r=r, h=h);
    }
}

module logo_2d_shape() {
    translate([logo_offset_x, logo_offset_y])
    rotate([0, 0, logo_rot])
    scale([logo_scale, logo_scale]) {
        if (logo_type == "custom_text") {
            difference() {
                hull() {
                    translate([-14, 0]) circle(r=12, $fn=6);
                    translate([14, 0]) circle(r=12, $fn=6);
                }
                hull() {
                    translate([-14, 0]) circle(r=10.4, $fn=6);
                    translate([14, 0]) circle(r=10.4, $fn=6);
                }
                square([6, 30], center=true);
            }
            translate([0, 2])
                text(logo_string, size=7.2, font="Liberation Sans:style=Bold", halign="center", valign="center");
            translate([0, -5.5])
                text(logo_subtext, size=3.2, font="Liberation Mono:style=Bold", halign="center", valign="center");
        } else if (logo_type == "raspberry") {
            scale([0.85, 0.85]) {
                for (pos = [[-5.5, 4], [5.5, 4], [-7, -2.5], [7, -2.5], [-3.8, -8.5], [3.8, -8.5], [0, -2], [0, 5.5], [0, -10]]) {
                    translate(pos) difference() {
                        circle(r=4.2);
                        circle(r=2.6);
                    }
                }
                translate([-3.5, 12.5]) rotate([0, 0, 35]) scale([1.6, 0.85]) circle(r=3.5);
                translate([3.5, 12.5]) rotate([0, 0, -35]) scale([1.6, 0.85]) circle(r=3.5);
            }
        } else if (logo_type == "svg") {
            // Import pliku SVG przeskalowanego do docelowej szerokości
            resize([logo_svg_target_w, 0], auto=true)
                import(file = logo_svg_file, center = true, dpi = 96);
                
            // Napis NAS // RPi5 bezpośrednio pod logiem SVG
            translate([0, - (logo_svg_target_w * 0.45) - 3.5])
                text("NAS // RPi5", size=3.2, font="Liberation Mono:style=Bold", halign="center", valign="center");
        }
    }
}

module top_logo_engraving() {
    if (logo_type != "none") {
        translate([outer_l / 2, outer_w / 2, outer_h - logo_depth])
            linear_extrude(height = logo_depth + 1.0)
                logo_2d_shape();
    }
}

// ==============================================================================
// WYCIĘCIA NA PORTY
// ==============================================================================
module port_cutouts() {
    pcb_z = bottom_thick + standoff_h + pcb_thick;
    pcb_x0 = wall + pcb_clearance;
    pcb_y0 = wall + pcb_clearance;

    translate([pcb_x0, pcb_y0, 0]) {
        // Przód: Ethernet i USB
        translate([pcb_l - 2, 10.25 - 8.5, pcb_z - 0.5]) cube([wall + 10, 17.0, 14.8]);
        translate([pcb_l - 2, 29.0 - 7.8, pcb_z - 0.5]) cube([wall + 10, 15.6, 16.5]);
        translate([pcb_l - 2, 47.0 - 7.8, pcb_z - 0.5]) cube([wall + 10, 15.6, 16.5]);

        // Bok: USB-C i HDMI
        translate([11.2 - 5.5, -wall - 5, pcb_z - 1.0]) cube([11.0, wall + 10, 5.5]);
        translate([25.8 - 5.5, -wall - 5, pcb_z - 1.0]) cube([(39.2 - 25.8) + 11.0, wall + 10, 6.0]);

        // Tył: Karta SD, Przycisk, Taśma PCIe
        translate([-wall - 5, 28.0 - 8.0, pcb_z - pcb_thick - 3.5]) cube([wall + 10, 16.0, 4.5]);
        translate([-wall - 5, 13.5 - 3.5, pcb_z - 0.5]) cube([wall + 10, 7.0, 5.0]);
        translate([-wall/2, 18.0, pcb_z]) cube([wall/2 + 2.0, 22.0, 22.0]);
    }
}

// ==============================================================================
// WENTYLACJA
// ==============================================================================
module ventilation_cuts() {
    vent_z_start = bottom_thick + hat_base_h - 6;
    vent_h = nvme_heatsink_extra_h + 2;
    
    // Boczne szczeliny
    for (x = [18 : 5 : outer_l - 18]) {
        translate([x, -2, vent_z_start]) cube([2.2, outer_w + 4, vent_h]);
    }

    base_half_w = (logo_type == "none") ? 0 : 
                  (logo_type == "raspberry") ? 14 : 
                  (logo_type == "svg") ? max(logo_svg_target_w / 2 + 4, 24) : 27;
                  
    safe_half_x = logo_auto_vent_gap ? (base_half_w * logo_scale) : 27;
    logo_center_x = (outer_l / 2) + logo_offset_x;

    // Górne szczeliny (omijające SVG i napis)
    for (x = [12 : 4.5 : outer_l - 12]) {
        if (logo_type == "none" || abs(x - logo_center_x) > safe_half_x) {
            translate([x - 1.1, 12, outer_h - bottom_thick - 2]) cube([2.2, outer_w - 24, bottom_thick + 4]);
        }
    }

    // Dolne szczeliny
    for (x = [18 : 6 : outer_l - 18]) {
        translate([x, 14, -2]) cube([2.4, outer_w - 28, bottom_thick + 4]);
    }
}

// ==============================================================================
// BRYŁY GŁÓWNE (DOŁEK I GÓRA Z KOŁNIERZEM CENTRUJĄCYM)
// ==============================================================================

module full_case_shell() {
    difference() {
        rounded_box(outer_l, outer_w, outer_h, corner_r + wall);
        translate([wall, wall, bottom_thick])
            rounded_box(inner_l, inner_w, inner_h, corner_r);
        port_cutouts();
        ventilation_cuts();
        top_logo_engraving();
    }
}

module bottom_part() {
    pcb_x0 = wall + pcb_clearance;
    pcb_y0 = wall + pcb_clearance;

    union() {
        intersection() {
            full_case_shell();
            cube([outer_l, outer_w, split_z]);
        }

        for (dx = [hole_offset, hole_offset + hole_dx]) {
            for (dy = [hole_offset, hole_offset + hole_dy]) {
                translate([pcb_x0 + dx, pcb_y0 + dy, bottom_thick]) {
                    difference() {
                        cylinder(d=standoff_od, h=standoff_h);
                        translate([0, 0, -0.1]) cylinder(d=standoff_id, h=standoff_h + 0.2);
                    }
                }
            }
        }
    }
}

module top_part() {
    union() {
        // Górna skorupa
        intersection() {
            full_case_shell();
            translate([0, 0, split_z])
                cube([outer_l, outer_w, outer_h - split_z]);
        }

        // Wewnętrzny kołnierz pozycjonujący (wchodzi do wnętrza dolnej części)
        difference() {
            translate([wall + lip_tol, wall + lip_tol, split_z - lip_h])
                rounded_box(inner_l - 2*lip_tol, inner_w - 2*lip_tol, lip_h + 0.5, corner_r);
                
            translate([wall + 1.2 + lip_tol, wall + 1.2 + lip_tol, split_z - lip_h - 1])
                rounded_box(inner_l - 2.4 - 2*lip_tol, inner_w - 2.4 - 2*lip_tol, lip_h + 3, max(0.5, corner_r - 1.2));
                
            port_cutouts();
        }
    }
}

// ==============================================================================
// RENDEROWANIE
// ==============================================================================
if (render_mode == "bottom") {
    bottom_part();
} else if (render_mode == "top") {
    translate([0, outer_w, outer_h])
        rotate([180, 0, 0])
            top_part();
} else if (render_mode == "both") {
    bottom_part();
    translate([0, outer_w * 2 + 12, outer_h])
        rotate([180, 0, 0])
            top_part();
} else if (render_mode == "assembled") {
    bottom_part();
    color("DodgerBlue", 0.85) top_part();
}