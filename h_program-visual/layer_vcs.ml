(* Yoann Padioleau
 *
 * Copyright (C) 2010 Facebook
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

open Common 

(*****************************************************************************)
(* Prelude *)
(*****************************************************************************)

(* 
 * todo? not sure how to transform those strings below in types so that more
 * checking is done at compile-time. We could define some AuthorMoreThan20
 * constructors but we will need to write some boilerplate code
 * to transform those constructors into strings (which are used
 * for the "legend" menu in codemap and the pfff-web UI).
 * Moreover there will be no guarentees that functions like
 * property_of_nb_authors covers the whole spectrum of constructors.
 * One good thing we would get is that in the layer generation
 * we could not generate property that do not exist (right now
 * it's easy to make a typo in the string and the compiler will not
 * complain).
 *)

(*****************************************************************************)
(* Types and constants *)
(*****************************************************************************)

let properties_nb_authors = [
  "authors > 40", "MediumPurple";
  "authors > 20", "red3";
  "authors > 10", "red1";
  "authors > 5", "orange";
  "authors = 5", "yellow";
  "authors = 4", "YellowGreen";
  "authors = 3", "green";
  "authors = 2", "aquamarine3";
  "authors = 1", "cyan";

  (* empty files *)
  "authors = 0", "white";
]

let properties_age = [
  "age > 5 years", "blue";
  "age > 3 years", "DeepSkyBlue1";
  "age > 1 year",  "cyan";
  "age > 6 months", "aquamarine3";
  "age > 3 months", "green";
  "age > 2 months", "YellowGreen";
  "age > 1 month", "yellow";
  "age > 2 weeks", "orange";
  "age > 1 week", "red1";
  "age last week", "red3";

  (* empty files *)
  "no info", "white";
]

let property_of_nb_authors n =
  match n with
  | _ when n > 40 -> "authors > 40"
  | _ when n > 20 -> "authors > 20"
  | _ when n > 10 -> "authors > 10"
  | _ when n > 5 -> "authors > 5"
  | _ when n <= 5 -> spf "authors = %d" n
  | _ -> raise Impossible

let property_of_age (Common.Days n) =
  match n with
  | _ when n > 5 * 365 -> "age > 5 years"
  | _ when n > 3 * 365 -> "age > 3 years"
  | _ when n > 1 * 365 -> "age > 1 year"
  | _ when n > 6 * 30 -> "age > 6 months"
  | _ when n > 3 * 30 -> "age > 3 months"
  | _ when n > 2 * 30 -> "age > 2 months"
  | _ when n > 1 * 30 -> "age > 1 month"
  | _ when n > 2 * 7 -> "age > 2 weeks"
  | _ when n > 1 * 7 -> "age > 1 week"
  | _ -> "age last week"
  
(*****************************************************************************)
(* Main entry point *)
(*****************************************************************************)
let gen_nbauthors_layer dir ~output =
  let dir = Common.realpath dir in

  let files = Common.files_of_dir_or_files_no_vcs_nofilter [dir] in
  (* filter the cached annotation files generated by Git.annotate below *)
  let files = files +> Common.exclude (fun f -> 
    f =~ ".*.git_annot$"
  ) in

  let layer = { Layer_code.
     files = files +> Common.index_list_and_total +> 
      List.map (fun (file, i, total) ->
        pr2 (spf "processing: %s (%d/%d)" file i total);

        let readable_file = Common.filename_without_leading_path dir file in
        
        let annots = Git.annotate 
          ~basedir:dir ~use_cache:true 
          ~use_dash_C:false (* too slow *)
          readable_file
        in
        let nbauthors = 
          annots +> Array.to_list 
          (* don't count the first entry which is the annotation for line 0
           * which is a dummy value. See git.ml
           *)
          +> List.tl 
          +> List.map (fun (_version, Lib_vcs.Author s, _data) -> s)
          +> Common.uniq
          +> List.length
        in
        let property = property_of_nb_authors nbauthors in

        readable_file,
        { Layer_code.
          (* don't display anything at the line microlevel *)
          micro_level = [];

          macro_level = [property, 1.];
        }
      );
      kinds = properties_nb_authors;
  }
  in
  pr2 ("generating layer in " ^ output);
  Layer_code.save_layer layer output


let gen_age_layer dir ~output =
  let dir = Common.realpath dir in

  let files = Common.files_of_dir_or_files_no_vcs_nofilter [dir] in
  (* filter the cached annotation files generated by Git.annotate below *)
  let files = files +> Common.exclude (fun f -> 
    f =~ ".*.git_annot$"
  ) in

  let layer = { Layer_code.
     files = files +> Common.index_list_and_total +> 
      List.map (fun (file, i, total) ->
        pr2 (spf "processing: %s (%d/%d)" file i total);

        let readable_file = Common.filename_without_leading_path dir file in
        
        let annots = Git.annotate 
          ~basedir:dir ~use_cache:true 
          ~use_dash_C:false (* too slow *)
          readable_file
        in

        let annots = 
          annots +> Array.to_list 
           (* don't count the first entry which is the annotation for
            * line 0 which is a dummy value. See git.ml
            *)
           +> List.tl 
        in

        let property = 
          match annots with
          | [] -> "no info"
          | xs ->
           (* could also decide to use the average date of the file instead *)
           let max_date_dmy = 
            xs
            +> List.map (fun (_version, Lib_vcs.Author _, date_dmy) -> date_dmy)
            +> Common.maximum_dmy
           in
           pr2_gen max_date_dmy;
           let now_dmy = 
             Common.today () 
             +> Common.floattime_to_unixtime +> Common.unixtime_to_dmy 
           in
           
           let age_in_days = 
             Common.rough_days_between_dates max_date_dmy now_dmy
           in
           pr2_gen age_in_days;

           property_of_age age_in_days
        in

        readable_file,
        { Layer_code.
          (* don't display anything at the line microlevel for now.
           * could display the age of each line.
           *)
          micro_level = [];

          macro_level = [property, 1.];
        }
      );
      kinds = properties_age;
  }
  in
  pr2 ("generating layer in " ^ output);
  Layer_code.save_layer layer output


(*****************************************************************************)
(* Actions *)
(*****************************************************************************)

let actions () = [
  "-gen_nbauthors_layer", " <git dir> <layerfile>",
  Common.mk_action_2_arg (fun dir output -> gen_nbauthors_layer dir ~output);
  "-gen_age_layer", " <git dir> <layerfile>",
  Common.mk_action_2_arg (fun dir output -> gen_age_layer dir ~output);
]
