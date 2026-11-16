// ==============================================================================
// OBUDOWA RASPBERRY PI 5 + M.2 HAT+ (WERSJA V6 - ŚCIANKA 1 MM POD ŚRUBĘ M2.5)
// - Dodatkowe wycięcie pod łeb śruby M2.5 (m25_head_pocket_d = 5.4 mm) wchodzące w głąb kołka,
//   dzięki czemu między łbem śruby M2.5 a spodem płytki Raspberry Pi zostaje DOKŁADNIE 1.0 mm ścianki!
// - Nóżki dopasowane do gniazda w dnie obudowy (foot_socket_h = 2.2 mm)
// - Prowadnica mocno zintegrowana ze ścianką górnej obudowy (wchodzi 1.2 mm w głąb ścianki bocznej)
// - Podwyższona dolna obudowa + zamknięcia przednich okienek (USB/LAN) na górnej obudowie
// - Pełnowymiarowa nakładka z logo (w obrysie obudowy, dystans 8 mm) + 4 nóżki
// ==============================================================================

$fn = 60;

// --- CO CHCESZ WYGENEROWAĆ? ---
// "all"       = dół, góra, pełnowymiarowa nakładka logo + 4 nóżki (gotowe do druku)
// "both"      = dół i góra obok siebie
// "bottom"    = tylko dół
// "top"       = tylko góra
// "badge"     = tylko nakładka logo
// "feet"      = tylko 4 nóżki dystansowe
// "assembled" = podgląd złożenia 3D z nakładką i nóżkami
render_mode = "all"; 

// --- KONFIGURACJA PEŁNOWYMIAROWEJ NAKŁADKI LOGO (BADGE) ---
logo_type = "custom_text";            // ["custom_text", "raspberry", "svg", "none"]
logo_string = "ToMati";               // Tekst dla trybu "custom_text"
logo_subtext = "NAS // RPi5";         // Podpis pod napisem
logo_svg_file = "logo.svg";           // Plik SVG (dla logo_type = "svg")
logo_depth = 1.0;                     // Głębokość graweru/reliefu na nakładce [mm]

logo_standoff_h = 8.0;                // Odstęp nakładki od góry obudowy [mm]
badge_thick = 2.8;                    // Grubość płytki nakładki logo [mm]
badge_margin = 0.0;                   // 0.0 = dokładnie w wymiarach zewnętrznych obudowy
badge_pin_d = 4.4;                    // Średnica czopów montażowych nakładki [mm]
badge_pin_tol = 0.20;                 // Luz pasowania kołków w otworach obudowy [mm]
badge_pin_depth = 2.4;                // Głębokość gniazd pod kołki w górnym deklu [mm]

logo_scale = 1.45;                    // Skala logo dopasowana do pełnego obrysu obudowy
logo_svg_target_w = 50.0;             // Szerokość bazowa SVG w mm (przed skalowaniem)
logo_rot = 0;                         // Obrót logo w stopniach
logo_offset_x = 0.0;                  // Przesunięcie X
logo_offset_y = 0.0;                  // Przesunięcie Y

// --- GŁÓWNE PARAMETRY WYMIAROWE I PRZEDŁUŻENIE TYŁU NA TAŚMĘ PCIe ---
rear_pcie_ext = 8.0;                  // Przedłużenie tyłu obudowy na łuk taśmy M.2 HAT+ [mm]
nvme_heatsink_extra_h = 18.0;         // Zapas wysokości na radiator NVMe [mm]
wall = 2.8;                           // Grubość ścianek bocznych [mm]
bottom_thick = 3.2;                   // Grubość dna (mieści gniazda pod nóżki) [mm]
top_thick = 2.8;                      // Grubość górnego sufitu [mm]
pcb_clearance = 0.6;                  // Luz wokół płytki PCB [mm]

// --- ŚRUBY M2.5 OD DOŁU (TYLKO 1.0 MM ŚCIANKI DO PŁYTKI PCB!) + NÓŻKI ---
// Całkowita wysokość od spodu obudowy do spodu płytki PCB wynosi: bottom_thick + standoff_h = 3.2 + 3.0 = 6.2 mm.
// Dodatkowe wycięcie pod łeb śruby M2.5 ma głębokość (6.2 - 1.0 = 5.2 mm),
// dzięki czemu między łbem śruby M2.5 a płytką PCB maliny zostaje DOKŁADNIE 1.0 mm ścianki!
m25_through_d = 2.75;                 // Przelot dla gwintu śruby M2.5 (przez 1.0 mm ścianki pod PCB)
m25_wall_to_pcb = 1.0;                // Grubość ścianki oddzielającej łeb śruby M2.5 od płytki PCB [mm]
m25_head_pocket_d = 5.4;              // Średnica dodatkowego wycięcia na łeb śruby M2.5 w kołku [mm]
foot_socket_d = 8.0;                  // Średnica szerszego gniazda od spodu pod wciskaną nóżkę [mm]
foot_socket_h = 2.2;                  // Głębokość gniazda w dnie obudowy pod czop nóżki [mm]
foot_air_gap_h = 5.0;                 // Wysokość nóżek (prześwit pod obudową na wlot powietrza) [mm]
foot_outer_d = 12.5;                  // Średnica zewnętrzna podstawy nóżki [mm]
foot_tol = 0.15;                      // Luz pasowania wciskanego czopa nóżki [mm]

// --- WYMIARY BAZOWE RASPBERRY PI 5 ---
pcb_l = 85.0;
pcb_w = 56.0;
pcb_thick = 1.6;
corner_r = 3.5;

// Kołki montażowe RPi 5 (poszerzone do 7.8 mm, aby wokół wycięcia 5.4 mm na łeb śruby została solidna ścianka!)
hole_dx = 58.0;
hole_dy = 49.0;
hole_offset = 3.5;
standoff_h = 3.0;                     // Wysokość kołka dystansowego nad dnem obudowy [mm]
standoff_od = 7.8;                    // Poszerzony kołek (mieści wewnątrz kieszeń 5.4 mm na łeb śruby M2.5)

// Wysokość bazowa do M.2 HAT+ i całkowite wymiary
hat_base_h = standoff_h + pcb_thick + 16.0 + 1.6; 
inner_l = pcb_l + 2 * pcb_clearance + rear_pcie_ext;
inner_w = pcb_w + 2 * pcb_clearance;
inner_h = hat_base_h + nvme_heatsink_extra_h;

outer_l = inner_l + 2 * wall;
outer_w = inner_w + 2 * wall;
outer_h = inner_h + bottom_thick + top_thick;

// Wymiary pełnowymiarowej nakładki (w rozmiarze obudowy)
badge_l = outer_l - 2 * badge_margin;
badge_w = outer_w - 2 * badge_margin;
badge_corner_r = corner_r + wall - badge_margin;

// Pozycja startowa płytki PCB (przesunięta o rear_pcie_ext od tylnej ścianki)
pcb_x0 = wall + pcb_clearance + rear_pcie_ext;
pcb_y0 = wall + pcb_clearance;
pcb_z0 = bottom_thick + standoff_h + pcb_thick;

// --- PODZIAŁ OBUDOWY I MOCNO OSADZONA PROWADNICA ---
split_z = pcb_z0 + 21.5;
lip_h = 4.0;                          // Wysokość prowadnicy wchodzącej w dolną obudowę [mm]
lip_thick = 2.4;                      // Grubość prowadnicy (2.4 mm)
lip_tol = 0.20;                       // Luz pasowania między prowadnicą a dolną ścianką [mm]
lip_wall_embed = 1.2;                 // Głębokość wtopienia prowadnicy w ściankę górnej obudowy [mm]

// Rozstaw słupków dystansowych nakładki logo
badge_pin_dx = badge_l - 16.0;
badge_pin_dy = badge_w - 16.0;

// ==============================================================================
// MODUŁY POMOCNICZE I KSZTAŁT LOGO 2D
// ==============================================================================

module rounded_box(l, w, h, r) {
    hull() {
        translate([r, r, 0]) cylinder(r=r, h=h);
        translate([l-r, r, 0]) cylinder(r=r, h=h);
        translate([r, w-r, 0]) cylinder(r=r, h=h);
        translate([l-r, w-r, 0]) cylinder(r=r, h=h);
    }
}

module fdm_slot_x(w_slot, len_y, h_slot) {
    chamfer = w_slot / 2;
    hull() {
        translate([0, 0, chamfer])
            cube([w_slot, len_y, max(0.1, h_slot - 2 * chamfer)]);
        translate([chamfer, 0, 0])
            cube([0.01, len_y, h_slot]);
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
            resize([logo_svg_target_w, 0], auto=true)
                import(file = logo_svg_file, center = true, dpi = 96);
                
            translate([0, - (logo_svg_target_w * 0.45) - 3.5])
                text("NAS // RPi5", size=3.2, font="Liberation Mono:style=Bold", halign="center", valign="center");
        }
    }
}

// ==============================================================================
// PEŁNOWYMIAROWA NAKŁADKA LOGO (W ROZMIARACH OBUDOWY, ODSTĘP 8 MM)
// ==============================================================================

module badge_mount_holes() {
    if (logo_type != "none") {
        cx = outer_l / 2;
        cy = outer_w / 2;
        for (dx = [-badge_pin_dx/2, badge_pin_dx/2]) {
            for (dy = [-badge_pin_dy/2, badge_pin_dy/2]) {
                translate([cx + dx, cy + dy, outer_h - badge_pin_depth])
                    cylinder(d = badge_pin_d + badge_pin_tol, h = badge_pin_depth + 1.0);
            }
        }
    }
}

module logo_badge_assembled() {
    cx = outer_l / 2;
    cy = outer_w / 2;
    badge_z0 = outer_h + logo_standoff_h;

    union() {
        difference() {
            translate([cx - badge_l/2, cy - badge_w/2, badge_z0])
                rounded_box(badge_l, badge_w, badge_thick, badge_corner_r);

            if (logo_type != "none") {
                translate([cx, cy, badge_z0 + badge_thick - logo_depth])
                    linear_extrude(height = logo_depth + 1.0)
                        logo_2d_shape();
            }
        }

        for (dx = [-badge_pin_dx/2, badge_pin_dx/2]) {
            for (dy = [-badge_pin_dy/2, badge_pin_dy/2]) {
                translate([cx + dx, cy + dy, 0]) {
                    translate([0, 0, outer_h])
                        cylinder(d1 = badge_pin_d + 2.8, d2 = badge_pin_d + 4.5, h = logo_standoff_h + 0.2);
                    translate([0, 0, outer_h - badge_pin_depth + 0.2])
                        cylinder(d1 = badge_pin_d - 0.5, d2 = badge_pin_d, h = 0.6);
                    translate([0, 0, outer_h - badge_pin_depth + 0.8])
                        cylinder(d = badge_pin_d, h = badge_pin_depth);
                }
            }
        }
    }
}

// ==============================================================================
// DWUSTOPNIOWE WYCIĘCIE POD NÓŻKĘ I ŚRUBĘ M2.5 (ŚCIANKA TYLKO 1.0 MM DO PCB!)
// ==============================================================================

module bottom_m25_and_foot_holes() {
    // Poziom Z, na którym opiera się spód płytki PCB maliny:
    pcb_bottom_z = bottom_thick + standoff_h;
    // Głębokość wycięcia pod łeb śruby M2.5 (zostawia dokładnie m25_wall_to_pcb = 1.0 mm ścianki do płytki!)
    screw_head_top_z = pcb_bottom_z - m25_wall_to_pcb;

    for (dx = [hole_offset, hole_offset + hole_dx]) {
        for (dy = [hole_offset, hole_offset + hole_dy]) {
            translate([pcb_x0 + dx, pcb_y0 + dy, 0]) {
                // 1. Szerokie gniazdo od spodu (d = 8.0 mm, h = 2.2 mm) pod wciskaną nóżkę
                translate([0, 0, -0.5])
                    cylinder(d = foot_socket_d, h = foot_socket_h + 0.5);

                // 2. DODATKOWE WYCIĘCIE NA ŁEB ŚRUBY M2.5 (d = 5.4 mm) sięgające w głąb kołka aż na 1.0 mm przed płytką PCB!
                translate([0, 0, -0.5])
                    cylinder(d = m25_head_pocket_d, h = screw_head_top_z + 0.5);

                // 3. Otwór przelotowy pod gwint M2.5 (d = 2.75 mm) przez pozostałą ściankę 1.0 mm pod płytką PCB
                translate([0, 0, -0.5])
                    cylinder(d = m25_through_d, h = pcb_bottom_z + 1.0);
            }
        }
    }
}

// Wycięcia portów w głównej skorupie
module port_cutouts() {
    translate([pcb_x0, pcb_y0, 0]) {
        // Przód (x = pcb_l): Ethernet i 2x podwójne USB
        translate([pcb_l - 2, 10.25 - 8.5, pcb_z0 - 0.5]) cube([wall + 10, 17.0, 14.8]);
        translate([pcb_l - 2, 29.0 - 7.8, pcb_z0 - 0.5]) cube([wall + 10, 15.6, 15.8]);
        translate([pcb_l - 2, 47.0 - 7.8, pcb_z0 - 0.5]) cube([wall + 10, 15.6, 15.8]);

        // Bok lewy (y = 0): USB-C (zasilanie) oraz 2x micro-HDMI
        translate([11.2 - 5.5, -wall - 5, pcb_z0 - 1.0]) cube([11.0, wall + 10, 6.2]);
        translate([25.8 - 5.5, -wall - 5, pcb_z0 - 1.0]) cube([(39.2 - 25.8) + 11.0, wall + 10, 6.5]);

        // Tył (x = 0, cofnięty o rear_pcie_ext od tylnej ścianki):
        // 1. Wycięcie na wyjęcie karty MicroSD
        hull() {
            translate([-1.0, 28.0 - 7.5, pcb_z0 - pcb_thick - 2.6])
                cube([3.0, 15.0, 3.8]);
            translate([-rear_pcie_ext - wall - 2, 28.0 - 10.0, pcb_z0 - pcb_thick - 3.0])
                cube([2.0, 20.0, 5.5]);
        }

        // 2. Kanał dostępu do przycisku zasilania (Power Button)
        hull() {
            translate([-1.0, 13.5 - 3.2, pcb_z0 - 0.5])
                cube([2.0, 6.4, 4.8]);
            translate([-rear_pcie_ext - wall - 2, 13.5 - 4.5, pcb_z0 - 1.0])
                cube([2.0, 9.0, 5.8]);
        }
    }
}

// Otwarte od góry wycięcia w przedniej ściance dolnej obudowy
module front_open_top_slots_for_bottom() {
    translate([pcb_x0, pcb_y0, 0]) {
        translate([pcb_l - 2, 10.25 - 8.5, pcb_z0 - 0.5]) cube([wall + 10, 17.0, split_z]);
        translate([pcb_l - 2, 29.0 - 7.8, pcb_z0 - 0.5]) cube([wall + 10, 15.6, split_z]);
        translate([pcb_l - 2, 47.0 - 7.8, pcb_z0 - 0.5]) cube([wall + 10, 15.6, split_z]);
    }
}

// Zamknięcia okienek na przedniej ściance górnej obudowy
module front_window_closures_for_top() {
    tol_w = 0.20;
    translate([pcb_x0, pcb_y0, 0]) {
        // 1. Zamknięcie okienka nad portem Ethernet
        eth_top_z = pcb_z0 - 0.5 + 14.8;
        translate([pcb_l + pcb_clearance, (10.25 - 8.5) + tol_w, eth_top_z])
            cube([wall, 17.0 - 2*tol_w, split_z - eth_top_z + 0.5]);

        // 2. Zamknięcie okienka nad środkowym portem USB
        usb_top_z = pcb_z0 - 0.5 + 15.8;
        translate([pcb_l + pcb_clearance, (29.0 - 7.8) + tol_w, usb_top_z])
            cube([wall, 15.6 - 2*tol_w, split_z - usb_top_z + 0.5]);

        // 3. Zamknięcie okienka nad prawym portem USB
        translate([pcb_l + pcb_clearance, (47.0 - 7.8) + tol_w, usb_top_z])
            cube([wall, 15.6 - 2*tol_w, split_z - usb_top_z + 0.5]);
    }
}

// ==============================================================================
// WENTYLACJA (BOCZNE SZCZELINY PŁYTSZE, ABY NIE ODCINAŁY PROWADNICY OD ŚCIANKI!)
// ==============================================================================
module ventilation_cuts() {
    slot_w = 2.2;
    slot_step = 5.0;

    // 1. BOCZNE ŻEBERKA:
    long_z_start = bottom_thick + 2.5;
    long_z_h = outer_h - top_thick - 3.5 - long_z_start;

    for (x = [14 : slot_step : outer_l - 14]) {
        // Prawa ścianka (y = outer_w - wall)
        translate([x, outer_w - wall - 0.4, long_z_start])
            fdm_slot_x(slot_w, wall + 0.8, long_z_h);

        // Lewa ścianka (y = 0)
        in_hdmi_usbc_zone = (x >= (pcb_x0 + 2.0)) && (x <= (pcb_x0 + 48.0));
        left_z_start = in_hdmi_usbc_zone ? (pcb_z0 + 8.5) : long_z_start;
        left_z_h = (outer_h - top_thick - 3.5) - left_z_start;

        translate([x, -0.4, left_z_start])
            fdm_slot_x(slot_w, wall + 0.8, left_z_h);
    }

    // 2. GÓRNE SZCZELINY (POD UNIESIONĄ O 8 MM NAKŁADKĄ)
    cx = outer_l / 2;
    for (x = [12 : 4.5 : outer_l - 12]) {
        near_pin_x = (abs(x - (cx - badge_pin_dx/2)) < 5.5) || (abs(x - (cx + badge_pin_dx/2)) < 5.5);
        if (!near_pin_x) {
            translate([x - 1.1, 10, outer_h - top_thick - 1])
                cube([2.2, outer_w - 20, top_thick + 2]);
        } else {
            translate([x - 1.1, (outer_w - (badge_pin_dy - 12)) / 2, outer_h - top_thick - 1])
                cube([2.2, badge_pin_dy - 12, top_thick + 2]);
        }
    }

    // 3. DOLNE SZCZELINY (TYLKO W DNIE DOLNEJ OBUDOWY)
    standoff_x1 = pcb_x0 + hole_offset;
    standoff_x2 = pcb_x0 + hole_offset + hole_dx;

    for (x = [12 : 5.5 : outer_l - 12]) {
        near_standoff = (abs(x + 1.2 - standoff_x1) < 7.5) || (abs(x + 1.2 - standoff_x2) < 7.5);
        y_margin = near_standoff ? 16.5 : 8.0;
        translate([x, y_margin, -1])
            cube([2.4, outer_w - 2 * y_margin, bottom_thick + 2]);
    }
}

// ==============================================================================
// BRYŁY GŁÓWNE (DÓŁ + GÓRA Z MOCNO ZINTEGROWANĄ PROWADNICĄ)
// ==============================================================================

module full_case_shell() {
    difference() {
        rounded_box(outer_l, outer_w, outer_h, corner_r + wall);
        translate([wall, wall, bottom_thick])
            rounded_box(inner_l, inner_w, inner_h, corner_r);
        port_cutouts();
        ventilation_cuts();
        badge_mount_holes();
    }
}

module bottom_part() {
    difference() {
        union() {
            intersection() {
                full_case_shell();
                cube([outer_l, outer_w, split_z]);
            }

            // Poszerzone (7.8 mm) kołki dystansowe pod Raspberry Pi 5
            for (dx = [hole_offset, hole_offset + hole_dx]) {
                for (dy = [hole_offset, hole_offset + hole_dy]) {
                    translate([pcb_x0 + dx, pcb_y0 + dy, bottom_thick]) {
                        cylinder(d=standoff_od, h=standoff_h);
                        cylinder(d1=standoff_od + 2.8, d2=standoff_od, h=1.6);
                    }
                }
            }
        }
        // 1. Otwarte od góry wycięcia z przodu (okienka domyka górna obudowa)
        front_open_top_slots_for_bottom();

        // 2. Dwustopniowe wycięcia od dołu: gniazdo nóżki (8.0 mm) + głębokie gniazdo na łeb śruby M2.5 (5.4 mm, ścianka 1 mm!)
        bottom_m25_and_foot_holes();
    }
}

// Prowadnica wewnętrzna mocno wtopiona w górną obudowę (1.2 mm w głąb ścianki + pełny pas styku + rampa 45°)
module fdm_angled_lip() {
    overlap_z = 2.0;
    ramp_h = lip_thick + lip_tol;

    difference() {
        union() {
            // 1. Dolna część prowadząca (poniżej split_z, z fazką wprowadzającą na samym dole)
            hull() {
                translate([wall + lip_tol, wall + lip_tol, split_z - lip_h + 0.8])
                    rounded_box(inner_l - 2*lip_tol, inner_w - 2*lip_tol, lip_h - 0.8 + 0.2, corner_r);
                translate([wall + lip_tol + 0.7, wall + lip_tol + 0.7, split_z - lip_h])
                    rounded_box(inner_l - 2*(lip_tol + 0.7), inner_w - 2*(lip_tol + 0.7), 0.1, max(0.5, corner_r - 0.7));
            }

            // 2. Przejście na styku split_z (ukośny uskok 45° wchodzący w głąb ścianki bocznej)
            hull() {
                translate([wall + lip_tol, wall + lip_tol, split_z - 0.2])
                    rounded_box(inner_l - 2*lip_tol, inner_w - 2*lip_tol, 0.2, corner_r);
                translate([wall - lip_wall_embed, wall - lip_wall_embed, split_z + 0.3])
                    rounded_box(inner_l + 2*lip_wall_embed, inner_w + 2*lip_wall_embed, overlap_z, corner_r + lip_wall_embed);
            }

            // 3. Rampa pod kątem 45° (wtopiona na 1.2 mm w ściankę boczną górnej obudowy)
            hull() {
                translate([wall - lip_wall_embed, wall - lip_wall_embed, split_z + overlap_z])
                    rounded_box(inner_l + 2*lip_wall_embed, inner_w + 2*lip_wall_embed, 0.2, corner_r + lip_wall_embed);
                translate([wall - lip_wall_embed, wall - lip_wall_embed, split_z + overlap_z + ramp_h])
                    rounded_box(inner_l + 2*lip_wall_embed, inner_w + 2*lip_wall_embed, 0.2, corner_r + lip_wall_embed);
            }
        }

        // Wydrążenie wewnętrzne prowadnicy
        union() {
            translate([wall + lip_tol + lip_thick, wall + lip_tol + lip_thick, split_z - lip_h - 1])
                rounded_box(inner_l - 2*(lip_tol + lip_thick), inner_w - 2*(lip_tol + lip_thick), lip_h + overlap_z + 1.1, max(0.5, corner_r - lip_thick));

            hull() {
                translate([wall + lip_tol + lip_thick, wall + lip_tol + lip_thick, split_z + overlap_z])
                    rounded_box(inner_l - 2*(lip_tol + lip_thick), inner_w - 2*(lip_tol + lip_thick), 0.1, max(0.5, corner_r - lip_thick));
                translate([wall, wall, split_z + overlap_z + ramp_h])
                    rounded_box(inner_l, inner_w, 0.1, corner_r);
            }
            translate([wall, wall, split_z + overlap_z + ramp_h - 0.05])
                rounded_box(inner_l, inner_w, outer_h, corner_r);
        }

        // Wycięcie prowadnicy wyłącznie na przedniej ściance przy oknach USB/LAN
        translate([pcb_x0 + pcb_l - 4, -5, split_z - lip_h - 2])
            cube([wall + 15, outer_w + 10, lip_h + overlap_z + ramp_h + 4]);
    }
}

module top_part() {
    union() {
        // 1. Krótsza górna skorupa
        intersection() {
            full_case_shell();
            translate([0, 0, split_z])
                cube([outer_l, outer_w, outer_h - split_z]);
        }
        // 2. Zamknięcia przednich okienek (USB i Ethernet) schodzące z górnej obudowy
        front_window_closures_for_top();

        // 3. Mocno wtopiona w ściankę prowadnica wewnętrzna pod kątem 45°
        fdm_angled_lip();
    }
}

// Pojedyncza nóżka wciskana w gniazdo 8.0 mm od spodu
module single_foot_for_print() {
    plug_d = foot_socket_d - foot_tol;
    plug_h = foot_socket_h - 0.2;

    difference() {
        union() {
            cylinder(d1 = foot_outer_d, d2 = foot_outer_d - 1.5, h = foot_air_gap_h);
            translate([0, 0, foot_air_gap_h])
                cylinder(d = plug_d, h = plug_h - 0.4);
            translate([0, 0, foot_air_gap_h + plug_h - 0.4])
                cylinder(d1 = plug_d, d2 = plug_d - 0.6, h = 0.4);
        }
        translate([0, 0, 2.0])
            cylinder(d = 5.4, h = foot_air_gap_h + plug_h);
    }
}

module feet_set_for_print() {
    for (i = [0 : 3]) {
        translate([i * (foot_outer_d + 5), 0, 0])
            single_foot_for_print();
    }
}

module feet_assembled() {
    for (dx = [hole_offset, hole_offset + hole_dx]) {
        for (dy = [hole_offset, hole_offset + hole_dy]) {
            translate([pcb_x0 + dx, pcb_y0 + dy, -foot_air_gap_h])
                single_foot_for_print();
        }
    }
}

module logo_badge_for_print() {
    translate([0, 0, outer_h + logo_standoff_h + badge_thick])
        rotate([180, 0, 0])
            logo_badge_assembled();
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
} else if (render_mode == "badge") {
    logo_badge_for_print();
} else if (render_mode == "feet") {
    feet_set_for_print();
} else if (render_mode == "both") {
    bottom_part();
    translate([0, outer_w * 2 + 10, outer_h])
        rotate([180, 0, 0])
            top_part();
} else if (render_mode == "all") {
    // 1. Podwyższony dół obudowy
    bottom_part();
    // 2. Krótsza góra obudowy (z zamknięciami przednich okienek i wtopioną prowadnicą)
    translate([0, outer_w * 2 + 10, outer_h])
        rotate([180, 0, 0])
            top_part();
    // 3. Pełnowymiarowa nakładka logo
    translate([0, outer_w * 2 + 18 + badge_w, 0])
        logo_badge_for_print();
    // 4. Komplet 4 wciskanych nóżek dystansowych
    translate([outer_l + 15, 10, 0])
        feet_set_for_print();
} else if (render_mode == "assembled") {
    bottom_part();
    color("DodgerBlue", 0.85) top_part();
    color("Crimson", 0.95) logo_badge_assembled();
    color("DimGray", 1.0) feet_assembled();
}
