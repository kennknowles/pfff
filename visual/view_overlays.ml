(*s: view_overlays.ml *)
(*s: Facebook copyright *)
(* Yoann Padioleau
 * 
 * Copyright (C) 2010-2012 Facebook
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * version 2.1 as published by the Free Software Foundation, with the
 * special exception on linking described in file license.txt.
 * 
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the file
 * license.txt for more details.
 *)
(*e: Facebook copyright *)
open Common
(* floats are the norm in graphics *)
open Common.ArithFloatInfix

module F = Figures
module T = Treemap
module CairoH = Cairo_helpers

module Flag = Flag_visual
open Model2
module Controller = Controller2
module Style = Style2

open Figures (* for the fields *)
module M = Model2

(*****************************************************************************)
(* Prelude *)
(*****************************************************************************)

(* This module mainly modifies the dw.overlay cairo surface. It also
 * triggers the refresh_da which triggers itself the expose event
 * which triggers the View2.assemble_layers composition of dw.pm with
 * dw.overlay
 *)

(*****************************************************************************)
(* The overlays *)
(*****************************************************************************)

(* ---------------------------------------------------------------------- *)
(* The current filename *)
(* ---------------------------------------------------------------------- *)

(*s: draw_label_overlay *)
let draw_label_overlay ~cr_overlay ~dw ~x ~y r =

  let txt = r.T.tr_label in

  let readable_txt = 
    if dw.root = txt (* when we are fully zoomed on one file *)
    then "root"
    else 
      Common.filename_without_leading_path dw.root txt in

  let readable_txt =
    if String.length readable_txt > 25
    then 
      let dirs = Filename.dirname readable_txt +> Common.split "/" in
      let file = Filename.basename readable_txt in
      spf "%s/.../%s" (List.hd dirs) file
    else readable_txt
  in

  Cairo.select_font_face cr_overlay "serif" 
    Cairo.FONT_SLANT_NORMAL Cairo.FONT_WEIGHT_NORMAL;
  Cairo.set_font_size cr_overlay Style2.font_size_filename_cursor;
      
  let extent = CairoH.text_extents cr_overlay readable_txt in
  let tw = extent.Cairo.text_width in
  let th = extent.Cairo.text_height in

  let refx = x - tw / 2. in
  let refy = y in

  CairoH.fill_rectangle ~cr:cr_overlay 
    ~x:(refx + extent.Cairo.x_bearing) ~y:(refy + extent.Cairo.y_bearing)
    ~w:tw ~h:(th * 1.2)
    ~color:"black"
    ~alpha:0.5
    ();

  Cairo.move_to cr_overlay refx refy;
  Cairo.set_source_rgba cr_overlay 1. 1. 1.    1.0;
  CairoH.show_text cr_overlay readable_txt;
  
  (*
  Cairo.set_source_rgb cr_overlay 0.3 0.3 0.3;
  Cairo.move_to cr_overlay x y;
  Cairo.line_to cr_overlay (x + 10.) (y + 10.);
  Cairo.stroke cr_overlay;
  *)
  ()
(*e: draw_label_overlay *)
(* ---------------------------------------------------------------------- *)
(* The current rectangles *)
(* ---------------------------------------------------------------------- *)

(*s: draw_rectangle_overlay *)
let draw_rectangle_overlay ~cr_overlay ~dw (r, middle, r_englobing) =
  Cairo.save cr_overlay;
  View_mainmap.zoom_pan_scale_map cr_overlay dw;
  CairoH.draw_rectangle_figure ~cr:cr_overlay ~color:"white" r.T.tr_rect;

  CairoH.draw_rectangle_figure
    ~cr:cr_overlay ~color:"blue" r_englobing.T.tr_rect;
  Draw_labels.draw_treemap_rectangle_label_maybe 
    ~cr:cr_overlay ~color:(Some "red") ~zoom:dw.zoom r_englobing;

  middle +> Common.index_list_1 +> List.iter (fun (r, i) ->
    let color = 
      match i with
      | 1 -> "grey70"
      | 2 -> "grey40"
      | _ -> spf "grey%d" (max 1 (50 -.. (i *.. 10)))
    in
    CairoH.draw_rectangle_figure
      ~cr:cr_overlay ~color r.T.tr_rect;
    Draw_labels.draw_treemap_rectangle_label_maybe 
      ~cr:cr_overlay ~color:(Some color) ~zoom:dw.zoom r;
  );
    
  Cairo.restore cr_overlay;
  ()
(*e: draw_rectangle_overlay *)
(* ---------------------------------------------------------------------- *)
(* The selected rectangles *)
(* ---------------------------------------------------------------------- *)

(*s: draw_searched_rectangles *)
let draw_searched_rectangles ~cr_overlay ~dw =
  Cairo.save cr_overlay;
  View_mainmap.zoom_pan_scale_map cr_overlay dw;

  dw.current_searched_rectangles +> List.iter (fun r ->
    CairoH.draw_rectangle_figure ~cr:cr_overlay 
      ~color:"yellow" r.T.tr_rect
  );
  (* 
   * would also like to draw not matching rectangles
   * bug the following code is too slow on huge treemaps. 
   * Probably because it is doing lots of drawing and alpha
   * computation.
   *
   * old:
   * let color = Some "grey3" in
   * Draw.draw_treemap_rectangle ~cr:cr_overlay 
   * ~color ~alpha:0.3
   * r
   *)
  Cairo.restore cr_overlay;
  ()
(*e: draw_searched_rectangles *)

(* ---------------------------------------------------------------------- *)
(* The magnifying glass *)
(* ---------------------------------------------------------------------- *)

(*s: zoomed_surface_of_rectangle *)
let _hmemo_surface = Hashtbl.create 101
let zoomed_surface_of_rectangle dw r =
  Common.memoized _hmemo_surface (r.T.tr_label, dw.zoom) (fun () ->

  let user_rect = View_mainmap.device_to_user_area dw in
  
  let sur =
    Cairo.surface_create_similar (CairoH.surface_of_pixmap dw.pm)
      (* subtle: can not use dw.width or dw.height here because at
       * the zoom level we will proceed, the whole file would probably not
       * feel on the full screen. If it does not fit, then having a too
       * small surface mean parts of the rendering of the file will not
       * be stored.
       *)
      Cairo.CONTENT_COLOR_ALPHA 9000 9000;
  in
  let cr = Cairo.create sur in

  (* simplify the drawing context, draw on 0 x 0 a rectangle that itself
   * starts at 0 x 0
   *)
  let dw' = { dw with 
    zoom = dw.zoom * Style.zoom_factor_incruste_mode; (* CONFIG *)
    xtrans = 0.; ytrans = 0.;
  } 
  in
  View_mainmap.zoom_pan_scale_map cr dw';
  (* a normalized rectangle that starts at 0 x 0 *)
  let rect = r.T.tr_rect in
  let rect' = { 
    F.p = { F. x = 0.; y = 0.;};
    F.q = { F. x = F.rect_width rect; y = F.rect_height rect;};
  }
  in
  let r' = { r with T.tr_rect = rect' } in

  let user_width = F.rect_width rect in
  let user_height = F.rect_height rect in

  let device_width  = CairoH.user_to_device_distance_x cr user_width in
  let device_height = CairoH.user_to_device_distance_y cr user_height in
  (* now have on the surface the same thing we would have got if we had
   * zoomed a lot.
   *)

  let context = context_of_drawing dw in
  let context = { context with Model2.nb_rects_on_screen = 1 } in

  Draw_macrolevel.draw_treemap_rectangle 
    ~cr ~alpha:0.9 r';
  Draw_microlevel.draw_treemap_rectangle_content_maybe 
    ~cr ~context ~clipping:user_rect r';

  sur, device_width, device_height
  )



let draw_zoomed_overlay ~cr_overlay ~user ~dw ~x ~y r =

  let percent_x = 
    (user.Cairo.x - r.T.tr_rect.p.F.x) / F.rect_width r.T.tr_rect in
  let percent_y = 
    (user.Cairo.y - r.T.tr_rect.p.F.y) / F.rect_height r.T.tr_rect in
  
  let zoomed_surface, zoomed_device_width, zoomed_device_height = 
    zoomed_surface_of_rectangle dw r
  in
  Cairo.set_operator cr_overlay Cairo.OPERATOR_OVER;
  (* old:
     Cairo.set_source_surface cr_overlay zoomed_surface (x - 100.) (y - 100.);
     Cairo.paint cr_overlay;
  *)
  (* see http://cairographics.org/FAQ/#paint_from_a_surface *)
  let dest_x = (x + 20.) in
  let dest_y = (y + 20.) in
  let width = float_of_int dw.width / 2.5 in
  let height = float_of_int dw.height / 2.5 in
  let source_x = 
    Common.borne
      ~min:0. ~max:(zoomed_device_width - width)
      ((percent_x * zoomed_device_width) - 140.)
  in
  let source_y = 
    Common.borne
      ~min:0. ~max:(zoomed_device_height - height)
      ((percent_y * zoomed_device_height) - 30.)
  in

  pr2 (spf "at x%%= %.3f, y%% = %.3f, zoom_w = %.3f, zoom_h = %.3f" 
          percent_x percent_y
          zoomed_device_width
          zoomed_device_height
  );

  Cairo.set_source_surface cr_overlay zoomed_surface
    (dest_x -. source_x) (dest_y -. source_y);
  Cairo.rectangle cr_overlay dest_x dest_y width height;
  Cairo.fill cr_overlay;
  ()
(*e: zoomed_surface_of_rectangle *)

(*****************************************************************************)
(* Assembling overlays *)
(*****************************************************************************)

(*s: motion_refresher *)
(* todo: deadclock   M.locked (fun () ->    ) dw.M.model.m *)
let motion_refresher ev dw () =
  let cr_overlay = Cairo.create dw.overlay in
  CairoH.clear cr_overlay;

  let x = GdkEvent.Motion.x ev in
  let y = GdkEvent.Motion.y ev in

  let pt = { Cairo. x = GdkEvent.Motion.x ev; y = GdkEvent.Motion.y ev;} in
  let user = View_mainmap.with_map dw (fun cr -> Cairo.device_to_user cr pt) in

  let r_opt = find_rectangle_at_user_point dw user in
  r_opt +> Common.do_option (fun (r, middle, r_englobing) ->
    let txt = r.T.tr_label in
    !Controller._statusbar_addtext txt;
    
    draw_label_overlay ~cr_overlay ~dw ~x ~y r;
    draw_rectangle_overlay ~cr_overlay ~dw (r, middle, r_englobing);
    
    if dw.dw_settings.draw_searched_rectangles;
    then
        draw_searched_rectangles ~cr_overlay ~dw;
    
    Controller.current_r := Some r;
    
    (* it has been computed, use it then *)
    if Hashtbl.mem _hmemo_surface (r.T.tr_label, dw.zoom) &&
      dw.in_zoom_incruste
    then
      draw_zoomed_overlay ~cr_overlay ~user ~dw ~x ~y r;
      
  );
  !Controller._refresh_da ();
  false


let motion_notify (da, da2) dw ev =

  !Controller.current_motion_refresher +> Common.do_option (fun x ->
    GMain.Idle.remove x;
  );

  let dw = !dw in

  let x = GdkEvent.Motion.x ev in
  let y = GdkEvent.Motion.y ev in
  pr2 (spf "motion: %f, %f" x y);

  if dw.in_dragging then begin

    let deltax = x -. dw.drag_pt.Cairo.x in
    let deltay = y -. dw.drag_pt.Cairo.y in
    
    let deltax_user = 
      View_mainmap.with_map dw 
        (fun cr -> CairoH.device_to_user_distance_x cr deltax)
    in
    let deltay_user = 
      View_mainmap.with_map dw 
        (fun cr -> CairoH.device_to_user_distance_y cr deltay)
    in
    
    dw.xtrans <- dw.xtrans +. deltax_user;
    dw.ytrans <- dw.ytrans +. deltay_user;
    
    dw.drag_pt <- { Cairo.x = x ; Cairo.y = y } ;
    
    GtkBase.Widget.queue_draw da#as_widget;
    GtkBase.Widget.queue_draw da2#as_widget;
  
    true
  end else begin
    Controller.current_motion_refresher := 
      Some (Gui.gmain_idle_add ~prio:100 (motion_refresher ev dw));
    true
  end
(*e: motion_refresher *)

(*s: idle *)
let idle dw () = 
  let dw = !dw in

  (*pr2 "idle";*)
  !Controller.current_r +> Common.do_option (fun r ->
    (* will compute and cache *)
    if dw.in_zoom_incruste 
    then zoomed_surface_of_rectangle dw r +> ignore;
  );
  true
(*e: idle *)


(*e: view_overlays.ml *)
