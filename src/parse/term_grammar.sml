structure term_grammar :> term_grammar =
struct

open HOLgrammars GrammarSpecials

  type ppstream = Portable.ppstream

type nthy_rec = {Name : string, Thy : string}

  type block_info = PP.break_style * int
  datatype rule_element = TOK of string | TM
  datatype pp_element =
    PPBlock of pp_element list * block_info |
    EndInitialBlock of block_info | BeginFinalBlock of block_info |
    HardSpace of int | BreakSpace of (int * int) |
    RE of rule_element | LastTM | FirstTM
  (* these last two only used internally *)

    datatype PhraseBlockStyle =
      AroundSameName | AroundSamePrec | AroundEachPhrase | NoPhrasing
    datatype ParenStyle =
      Always | OnlyIfNecessary | ParoundName | ParoundPrec

  fun rule_elements0 acc pplist =
    case pplist of
      [] => acc
    | ((RE x) :: xs) => rule_elements0 (acc @ [x]) xs
    | (PPBlock(pels, _) :: xs) => rule_elements0 (rule_elements0 acc pels) xs
    | ( _ :: xs) => rule_elements0 acc xs
  val rule_elements = rule_elements0 []


  fun rels_ok [TOK _] = true
    | rels_ok (TOK _ :: TM :: xs) = rels_ok xs
    | rels_ok (TOK _ :: xs) = rels_ok xs
    | rels_ok _ = false

  fun pp_elements_ok pplist = let
    fun check_em toplevel eibs_ok els =
      case els of
        [] => true
      | (x::xs) => let
        in
          case x of
            LastTM => false
          | FirstTM => false
          | EndInitialBlock _ =>
              toplevel andalso eibs_ok andalso check_em true true xs
          | BeginFinalBlock _ => toplevel andalso check_em true false xs
          | PPBlock(els, _) =>
              check_em false false els andalso check_em toplevel eibs_ok xs
          | _ => check_em toplevel eibs_ok xs
        end
  in
    rels_ok (rule_elements pplist) andalso check_em true true pplist
  end




fun reltoString (TOK s) = s
  | reltoString TM = "TM"

type rule_record = {term_name : string,
                    elements : pp_element list,
                    preferred : bool,
                    block_style : PhraseBlockStyle * block_info,
                    paren_style : ParenStyle}

fun update_rr_pref b
  {term_name, elements, preferred, block_style, paren_style} =
  {term_name = term_name, elements = elements, preferred = b,
   block_style = block_style, paren_style = paren_style}

datatype binder = LAMBDA | BinderString of string | TypeBinderString of string
datatype prefix_rule = STD_prefix of rule_record list
                     | BINDER of binder list
datatype suffix_rule = STD_suffix of rule_record list
                     | TYPE_annotation
                     | TYPE_application
datatype infix_rule =
         STD_infix of rule_record list * associativity
       | RESQUAN_OP
       | VSCONS
       | FNAPP of rule_record list

type listspec =
  {separator : pp_element list, leftdelim : pp_element list,
   rightdelim : pp_element list, cons : string, nilstr : string,
   block_info : block_info}

datatype grammar_rule =
         PREFIX of prefix_rule
       | SUFFIX of suffix_rule
       | INFIX of infix_rule
       | CLOSEFIX of rule_record list
       | LISTRULE of listspec list

type overload_info = Overload.overload_info
type parser_info = (string,unit) Binarymap.dict

type printer_info =
  ({Name:string,Thy:string},term_pp_types.userprinter) Binarymap.dict
type special_info = {type_intro : string,
                     type_lbracket : string,
                     type_rbracket : string,
                     lambda : string,
                     type_lambda : string,
                     endbinding : string,
                     restr_binders : (binder * string) list,
                     res_quanop : string}


datatype grammar = GCONS of
  {rules : (int option * grammar_rule) list,
   specials : special_info,
   numeral_info : (char * string option) list,
   overload_info : overload_info,
   user_additions : {parsers : parser_info, printers : printer_info}}

fun specials (GCONS G) = #specials G
fun numeral_info (GCONS G) = #numeral_info G
fun overload_info (GCONS G) = #overload_info G
fun known_constants (GCONS G) = Overload.known_constants (#overload_info G)
fun grammar_rules (GCONS G) = map #2 (#rules G)
fun rules (GCONS G) = (#rules G)
fun user_additions (GCONS G) = #user_additions G

fun fupdate_rules f (GCONS{rules, specials, numeral_info, overload_info,
                           user_additions}) =
  GCONS{rules = f rules, specials = specials, numeral_info = numeral_info,
        overload_info = overload_info, user_additions = user_additions}
fun fupdate_specials f (GCONS{rules, specials, numeral_info, overload_info,
                              user_additions}) =
  GCONS {rules = rules, specials = f specials, numeral_info = numeral_info,
         overload_info = overload_info, user_additions = user_additions}
fun fupdate_numinfo f (GCONS {rules, specials, numeral_info, overload_info,
                              user_additions}) =
  GCONS {rules = rules, specials = specials, numeral_info = f numeral_info,
         overload_info = overload_info, user_additions = user_additions}

fun mfupdate_overload_info f (GCONS g) = let
  val {rules, specials, numeral_info, overload_info, user_additions} = g
  val (new_oinfo,result) = f overload_info
in
  (GCONS{rules = rules, specials = specials, numeral_info = numeral_info,
         overload_info = new_oinfo, user_additions = user_additions},
   result)
end
fun fupdate_overload_info f g =
  #1 (mfupdate_overload_info (fn oi => (f oi, ())) g)

fun mfupdate_user_additions f (GCONS g) = let
  val {rules, specials, numeral_info, overload_info, user_additions} = g
  val (new_uadds, result) = f user_additions
in
  (GCONS {rules = rules, specials = specials, numeral_info = numeral_info,
          overload_info = overload_info, user_additions = new_uadds},
   result)
end
fun fupdate_user_additions f g =
  #1 (mfupdate_user_additions (fn ua => (f ua, ())) g)

fun add_user_printer (k,v) g =
  fupdate_user_additions
  (fn {parsers,printers} => {parsers = parsers,
                             printers = Binarymap.insert(printers,k,v)})
  g
fun remove_user_printer k g = let
  open Lib infix ##
  fun pp_update bmap =
    (I ## SOME) (Binarymap.remove(bmap,k))
    handle Binarymap.NotFound => (bmap, NONE)
  fun ua_update {parsers,printers} = let
    val (newprinters, result) = pp_update printers
  in
    ({parsers = parsers, printers = newprinters}, result)
  end
in
  mfupdate_user_additions ua_update g
end

fun user_printers g = #printers (user_additions g)


fun update_restr_binders rb
  {lambda, endbinding, type_intro, restr_binders, res_quanop} =
  {lambda = lambda, endbinding = endbinding, type_intro = type_intro,
         restr_binders = rb, res_quanop = res_quanop}

fun fupdate_restr_binders f
  {lambda, type_lambda, endbinding, type_intro, type_lbracket, type_rbracket, restr_binders, res_quanop} =
  {lambda = lambda, type_lambda = type_lambda, endbinding = endbinding,
   type_intro = type_intro, type_lbracket = type_lbracket, type_rbracket = type_rbracket,
   restr_binders = f restr_binders, res_quanop = res_quanop}

fun map_rrfn_rule f r =
  case r of
    PREFIX (STD_prefix rlist) => PREFIX (STD_prefix (map f rlist))
  | PREFIX (BINDER _) => r

  | INFIX (STD_infix (rlist, a)) => INFIX (STD_infix (map f rlist, a))
  | INFIX RESQUAN_OP => r
  | INFIX (FNAPP rlist) => INFIX (FNAPP (map f rlist))
  | INFIX VSCONS => r

  | SUFFIX (STD_suffix rlist) => SUFFIX (STD_suffix (map f rlist))
  | SUFFIX TYPE_annotation => r
  | SUFFIX TYPE_application => r

  | CLOSEFIX rlist => CLOSEFIX (map f rlist)
  | LISTRULE _ => r

fun fupdate_rule_by_term t f r = let
  fun over_rr (rr:rule_record) = if #term_name rr = t then f rr else rr
in
  map_rrfn_rule over_rr r
end

fun fupdate_rule_by_termtok {term_name, tok} f r = let
  fun over_rr (rr:rule_record) =
    if #term_name rr = term_name andalso
      List.exists (fn e => e = TOK tok) (rule_elements (#elements rr)) then
      f rr
    else
      rr
in
  map_rrfn_rule over_rr r
end

fun fupdate_rulelist f rules = map (fn (p,r) => (p, f r)) rules
fun fupdate_prulelist f rules = map f rules


fun binder_to_string (G:grammar) b =
  case b of
    LAMBDA => #lambda (specials G)
  | BinderString s => s
  | TypeBinderString s => s

fun binders (G: grammar) = let
  fun binders0 [] acc = acc
    | binders0 ((_, x)::xs) acc = let
      in
        case x of
          PREFIX (BINDER sl) => binders0 xs (map (binder_to_string G) sl @ acc)
        | _ => binders0 xs acc
      end
in
  binders0 (rules G) []
end

fun resquan_op (G: grammar) = #res_quanop (specials G)

fun update_assoc (item as (k,v)) alist =
  case alist of
    [] => [item]
  | (first as (k1,v1))::rest => if k = k1 then item::rest
                                else first::update_assoc item rest

fun associate_restriction G (b, s) =
  fupdate_specials (fupdate_restr_binders (update_assoc (b, s))) G

fun is_binder G = let val bs = binders G in fn s => Lib.mem s bs end

datatype stack_terminal =
  STD_HOL_TOK of string | BOS | EOS | Id  | TypeColon | TypeTok | TypeListTok |
  EndBinding | VS_cons | ResquanOpTok

fun STtoString (G:grammar) x =
  case x of
    STD_HOL_TOK s => s
  | BOS => "<beginning of input>"
  | EOS => "<end of input>"
  | VS_cons => "<gap between varstructs>"
  | Id => "<identifier>"
  | TypeColon => #type_intro (specials G)
  | TypeTok => "<type>"
  | TypeListTok => "<type list>"
  | EndBinding => #endbinding (specials G) ^ " (end binding)"
  | ResquanOpTok => #res_quanop (specials G)^" (res quan operator)"

(* gives the "wrong" lexicographic order, but is more likely to
   resolve differences with one comparison because types/terms with
   the same name are rare, but it's quite reasonable for many
   types/terms to share the same theory *)
fun nthy_compare ({Name = n1, Thy = thy1}, {Name = n2, Thy = thy2}) =
  case String.compare(n1, n2) of
    EQUAL => String.compare(thy1, thy2)
  | x => x


val stdhol : grammar =
  GCONS
  {rules = [(SOME 0, PREFIX (BINDER [LAMBDA,TypeBinderString "\\:"])),
            (SOME 4, INFIX RESQUAN_OP),
            (SOME 5, INFIX VSCONS),
            (SOME 450,
             INFIX (STD_infix([{term_name = recupd_special,
                                elements = [RE (TOK ":=")],
                                preferred = false,
                                block_style = (AroundEachPhrase,
                                                (PP.CONSISTENT, 0)),
                                paren_style = OnlyIfNecessary},
                               {term_name = recfupd_special,
                                elements = [RE (TOK "updated_by")],
                                preferred = false,
                                block_style = (AroundEachPhrase,
                                                (PP.CONSISTENT, 0)),
                                paren_style = OnlyIfNecessary},
                               {term_name = recwith_special,
                                elements = [RE (TOK "with")],
                                preferred = false,
                                block_style = (AroundEachPhrase,
                                                (PP.CONSISTENT, 0)),
                                paren_style = OnlyIfNecessary}], RIGHT))),
            (SOME 1000, SUFFIX TYPE_annotation),
            (SOME 1200, SUFFIX TYPE_application),
            (SOME 2000, INFIX (FNAPP [])),
            (SOME 2500,
             INFIX (STD_infix ([{term_name = recsel_special,
                                 elements = [RE (TOK ".")],
                                 preferred = false,
                                 block_style = (AroundEachPhrase,
                                                (PP.CONSISTENT, 0)),
                                 paren_style = OnlyIfNecessary}], LEFT))),
            (NONE,
             CLOSEFIX [{term_name = bracket_special,
                        elements = [RE (TOK "("), RE TM, RE (TOK ")")],
                        preferred = false,
                        (* these two elements here will not actually
                         ever be looked at by the printer *)
                        block_style = (AroundEachPhrase, (PP.CONSISTENT, 0)),
                        paren_style = Always}]),
            (NONE,
             LISTRULE [{separator = [RE (TOK ";"), BreakSpace(1,0)],
                        leftdelim = [RE (TOK "<|")],
                        rightdelim = [RE (TOK "|>")],
                        block_info = (PP.INCONSISTENT, 0),
                        cons = reccons_special, nilstr = recnil_special}])],
   specials = {lambda = "\\", type_lambda = "\\:",
               type_intro = ":", endbinding = ".",
               type_lbracket = "[:", type_rbracket = ":]",
               restr_binders = [], res_quanop = "::"},
   numeral_info = [],
   overload_info = Overload.null_oinfo,
   user_additions = {parsers = Binarymap.mkDict String.compare,
                     printers = Binarymap.mkDict nthy_compare}
   }

fun first_tok [] = raise Fail "Shouldn't happen parse_term 133"
  | first_tok (RE (TOK s)::_) = s
  | first_tok (_ :: t) = first_tok t

local
  open stmonad
  infix >>
  fun add x acc = (x::acc, ())
  fun specials_from_elm [] = ok
    | specials_from_elm ((TOK x)::xs) = add x >> specials_from_elm xs
    | specials_from_elm (TM::xs) = specials_from_elm xs
  val mmap = (fn f => fn args => mmap f args >> ok)
  fun rule_specials G r = let
    val rule_specials = rule_specials G
  in
    case r of
      PREFIX(STD_prefix rules) =>
        mmap (specials_from_elm o rule_elements o #elements) rules
    | PREFIX (BINDER b) =>
        mmap add (map (binder_to_string G) b)
    | SUFFIX(STD_suffix rules) =>
        mmap (specials_from_elm o rule_elements o #elements) rules
    | SUFFIX TYPE_annotation  => add (#type_intro (specials G))
    | SUFFIX TYPE_application => add (#type_lbracket (specials G)) >>
                                 add (#type_rbracket (specials G))
    | INFIX(STD_infix (rules, _)) =>
        mmap (specials_from_elm o rule_elements o #elements) rules
    | INFIX RESQUAN_OP => ok
    | INFIX (FNAPP rlst) =>
        mmap (specials_from_elm o rule_elements o #elements) rlst
    | INFIX VSCONS => ok
    | CLOSEFIX rules =>
        mmap (specials_from_elm o rule_elements o #elements) rules
    | LISTRULE rlist => let
        fun process (r:listspec) =
          add (first_tok (#separator r)) >>
          add (first_tok (#leftdelim r)) >>
          add (first_tok (#rightdelim r))
      in
        mmap process rlist
      end
  end
in
  fun grammar_tokens G = let
    fun gs (G:grammar) = mmap (rule_specials G o #2) (rules G)
    val (all_specials, ()) = gs G []
  in
    Lib.mk_set all_specials
  end
  fun rule_tokens G r = Lib.mk_set (#1 (rule_specials G r []))
end

(* turn a rule element list into a list of std_hol_toks *)
val rel_list_to_toklist =
  List.mapPartial (fn TOK s => SOME (STD_HOL_TOK s) | _ => NONE)

(* right hand elements of suffix and closefix rules *)
fun find_suffix_rhses (G : grammar) = let
  fun select (SUFFIX TYPE_annotation) = [[TypeTok]]
    | select (SUFFIX TYPE_application) = [[STD_HOL_TOK (#type_rbracket (specials G))]]
    | select (SUFFIX (STD_suffix rules)) = let
      in
        map (rel_list_to_toklist o rule_elements o #elements) rules
        end
    | select (CLOSEFIX rules) =
        map (rel_list_to_toklist o rule_elements o #elements) rules
    | select (LISTRULE rlist) =
        map (fn r => [STD_HOL_TOK (first_tok (#rightdelim r))]) rlist
    | select _ = []
  val suffix_rules = List.concat (map (select o #2) (rules G))
in
  Id :: map List.last suffix_rules
end

fun find_prefix_lhses (G : grammar) = let
  fun select x = let
  in
    case x of
      PREFIX (STD_prefix rules) =>
        map (rel_list_to_toklist o rule_elements o #elements) rules
    | PREFIX (BINDER sl) =>
        map (fn b => [STD_HOL_TOK (binder_to_string G b)]) sl
    | CLOSEFIX rules =>
        map (rel_list_to_toklist o rule_elements o #elements) rules
    | (LISTRULE rlist) =>
        map (fn r => [STD_HOL_TOK (first_tok (#leftdelim r))]) rlist
    | _ => []
  end
  val prefix_rules = List.concat (map (select o #2) (rules G))
in
  Id :: map hd prefix_rules
end

fun compatible_listrule (G:grammar) arg = let
  val {separator, leftdelim, rightdelim} = arg
  fun recurse rules =
    case rules of
      [] => NONE
    | ((_, rule)::rules) => let
      in
        case rule of
          LISTRULE rlist => let
            fun check [] = NONE
              | check ((r:listspec)::rs) = let
                  val rule_sep = first_tok (#separator r)
                  val rule_left = first_tok (#leftdelim r)
                  val rule_right = first_tok (#rightdelim r)
                in
                  if rule_sep = separator andalso rule_left = leftdelim andalso
                    rule_right = rightdelim then
                    SOME {cons = #cons r, nilstr = #nilstr r}
                  else
                    check rs
                end
            val result = check rlist
          in
            if isSome result then result else  recurse rules
          end
        | _ => recurse rules
      end
in
  recurse (rules G)
end


fun aug_compare (NONE, NONE) = EQUAL
  | aug_compare (_, NONE) = LESS
  | aug_compare (NONE, _) = GREATER
  | aug_compare (SOME n, SOME m) = Int.compare(n,m)

fun priv_a2string a =
  case a of
    LEFT => "LEFT"
  | RIGHT => "RIGHT"
  | NONASSOC => "NONASSOC"

fun merge_rules (r1, r2) =
  case (r1, r2) of
    (SUFFIX (STD_suffix sl1), SUFFIX (STD_suffix sl2)) =>
      SUFFIX (STD_suffix (Lib.union sl1 sl2))
  | (SUFFIX TYPE_annotation, SUFFIX TYPE_annotation) => r1
  | (SUFFIX TYPE_application, SUFFIX TYPE_application) => r1
  | (PREFIX (STD_prefix pl1), PREFIX (STD_prefix pl2)) =>
      PREFIX (STD_prefix (Lib.union pl1 pl2))
  | (PREFIX (BINDER b1), PREFIX (BINDER b2)) =>
      PREFIX (BINDER (Lib.union b1 b2))
  | (INFIX VSCONS, INFIX VSCONS) => INFIX VSCONS
  | (INFIX(STD_infix (i1, a1)), INFIX(STD_infix(i2, a2))) =>
      if a1 <> a2 then
        raise GrammarError
          ("Attempt to have differently associated infixes ("^
           priv_a2string a1^" and "^priv_a2string a2^") at same level")
      else
        INFIX(STD_infix(Lib.union i1 i2, a1))
  | (INFIX RESQUAN_OP, INFIX RESQUAN_OP) => INFIX(RESQUAN_OP)
  | (INFIX (FNAPP rl1), INFIX (FNAPP rl2)) => INFIX (FNAPP (Lib.union rl1 rl2))
  | (INFIX (STD_infix(i1, a1)), INFIX (FNAPP rl1)) =>
      if a1 <> LEFT then
        raise GrammarError
                ("Attempting to merge function application with non-left" ^
                 " associated infix")
      else INFIX (FNAPP (Lib.union i1 rl1))
  | (INFIX (FNAPP _), INFIX (STD_infix _)) => merge_rules (r2, r1)
  | (CLOSEFIX c1, CLOSEFIX c2) => CLOSEFIX (Lib.union c1 c2)
  | (LISTRULE lr1, LISTRULE lr2) => LISTRULE (Lib.union lr1 lr2)
  | _ => raise GrammarError "Attempt to have different forms at same level"

fun optmerge r NONE = SOME r
  | optmerge r1 (SOME r2) = SOME (merge_rules (r1, r2))

(* the listrule and closefix rules don't have precedences and sit at the
   end of the list.  When merging grammars, we will have a list of possibly
   intermingled closefix and listrule rules to look at, we want to produce
   just one closefix and one listrule rule for the final grammar *)

(* This allows for reducing more than just two closefix and listrules, but
   when merging grammars with only one each, this shouldn't eventuate *)
fun resolve_nullprecs listrule closefix rules =
  case rules of
    [] => let
    in
      case (listrule, closefix) of
        (NONE, NONE) => [] (* should never really happen *)
      | (SOME lr, NONE) => [(NONE, lr)]
      | (NONE, SOME cf) => [(NONE, cf)]
      | (SOME lr, SOME cf) => [(NONE, lr), (NONE, cf)]
    end
  | (_, r as LISTRULE _)::xs =>
    resolve_nullprecs (optmerge r listrule) closefix xs
  | (_, r as CLOSEFIX _)::xs =>
    resolve_nullprecs listrule (optmerge r closefix) xs
  | _ => raise Fail "resolve_nullprecs: can't happen"


fun resolve_same_precs rules =
  case rules of
    [] => []
  | [x] => [x]
  | ((p1 as SOME _, r1)::(rules1 as (p2, r2)::rules2)) => let
    in
      if p1 <> p2 then
        (p1, r1)::(resolve_same_precs rules1)
      else let
        val merged_rule = merge_rules (r1, r2)
          handle GrammarError s =>
            raise GrammarError (s ^ "(" ^Int.toString (valOf p1)^")")
      in
        (p1, merged_rule) :: resolve_same_precs rules2
      end
    end
  | ((NONE, _)::_) => resolve_nullprecs NONE NONE rules


infix Gmerge
(* only merges rules, keeps rest as in g1 *)
fun ((g1:grammar) Gmerge (g2:(int option * grammar_rule) list)) = let
  val g0_rules =
    Listsort.sort (fn (e1,e2) => aug_compare(#1 e1, #1 e2))
    (rules g1 @ g2)
  val g_rules =  resolve_same_precs g0_rules
in
  fupdate_rules (fn _ => g_rules) g1
end

fun null_rule r =
  case r of
    SUFFIX (STD_suffix slist) => null slist
  | PREFIX (STD_prefix slist) => null slist
  | PREFIX (BINDER slist) => null slist
  | INFIX (STD_infix(slist, _)) => null slist
  | CLOSEFIX slist => null slist
  | LISTRULE rlist => null rlist
  | _ => false

fun map_rules f G = let
  fun recurse r =
    case r of
      [] => []
    | ((prec, rule)::rules) => let
        val newrule = f rule
        val rest = recurse rules
      in
        if null_rule newrule then rest else (prec, newrule)::rest
      end
in
  fupdate_rules recurse G
end


fun remove_form s rule = let
  fun rr_ok (r:rule_record) = #term_name r <> s
  fun lr_ok (ls:listspec) = #cons ls <> s andalso #nilstr ls <> s
  fun stringbinder LAMBDA = false
    | stringbinder (BinderString s0) = s0 = s
    | stringbinder (TypeBinderString s0) = s0 = s
in
  case rule of
    SUFFIX (STD_suffix slist) => SUFFIX (STD_suffix (List.filter rr_ok slist))
  | INFIX (STD_infix(slist, assoc)) =>
      INFIX(STD_infix (List.filter rr_ok slist, assoc))
  | PREFIX (STD_prefix slist) => PREFIX (STD_prefix (List.filter rr_ok slist))
  | PREFIX (BINDER slist) =>
      PREFIX (BINDER (List.filter (not o stringbinder) slist))
  | CLOSEFIX slist => CLOSEFIX (List.filter rr_ok slist)
  | LISTRULE rlist => LISTRULE (List.filter lr_ok rlist)
  | _ => rule
end


fun remove_tok {term_name, tok} r = let
  fun rels_safe rels = not (List.exists (fn e => e = TOK tok) rels)
  fun rr_safe ({term_name = s, elements,...}:rule_record) =
    s <> term_name orelse rels_safe (rule_elements elements)
in
  case r of
    SUFFIX (STD_suffix slist) =>
      SUFFIX (STD_suffix (List.filter rr_safe slist))
  | INFIX(STD_infix (slist, assoc)) =>
      INFIX (STD_infix (List.filter rr_safe slist, assoc))
  | PREFIX (STD_prefix slist) =>
      PREFIX (STD_prefix (List.filter rr_safe slist))
  | CLOSEFIX slist => CLOSEFIX (List.filter rr_safe slist)
  | LISTRULE rlist => let
      fun lrule_ok (r:listspec) =
        (#cons r <> term_name andalso #nilstr r <> term_name)  orelse
        (first_tok (#leftdelim r) <> tok andalso
         first_tok (#rightdelim r) <> tok andalso
         first_tok (#separator r) <> tok)
    in
      LISTRULE (List.filter lrule_ok rlist)
    end
  | _ => r
end

fun remove_standard_form G s = map_rules (remove_form s) G
fun remove_form_with_tok G r = map_rules (remove_tok r) G


datatype rule_fixity =
  Infix of associativity * int | Closefix | Suffix of int | TruePrefix of int
fun rule_fixityToString f =
  case f of
    Infix(a,i) => "Infix("^assocToString a^", "^Int.toString i^")"
  | Closefix => "Closefix"
  | Suffix p => "Suffix "^Int.toString p
  | TruePrefix p => "TruePrefix "^Int.toString p


fun clear_prefs_for s =
  fupdate_rules
  (fupdate_rulelist (fupdate_rule_by_term s (update_rr_pref false)))


fun add_rule G0 {term_name = s, fixity = f, pp_elements,
                 paren_style, block_style} = let
  val _ =  pp_elements_ok pp_elements orelse
                 raise GrammarError "token list no good"
  val G1 = clear_prefs_for s G0
  val rr = {term_name = s, elements = pp_elements, preferred = true,
            paren_style = paren_style, block_style = block_style}
  val new_rule =
    case f of
      Infix (a,p) => (SOME p, INFIX(STD_infix([rr], a)))
    | Suffix p => (SOME p, SUFFIX (STD_suffix [rr]))
    | TruePrefix p => (SOME p, PREFIX (STD_prefix [rr]))
    | Closefix => (NONE, CLOSEFIX [rr])
in
  G1 Gmerge [new_rule]
end

fun add_grule G0 r = G0 Gmerge [r]

fun add_binder G0 (s, prec) =
  G0 Gmerge [(SOME prec, PREFIX (BINDER [BinderString s]))]

fun add_listform G lrule = let
  fun ok_el e =
      case e of
        EndInitialBlock _ => false
      | BeginFinalBlock _ => false
      | RE TM => false
      | LastTM => false
      | FirstTM => false
      | _ => true
  fun check_els els =
      case List.find (not o ok_el) els of
        NONE => ()
      | SOME s => raise GrammarError "Invalid pp_element in listform"
  fun is_tok (RE (TOK _)) = true
    | is_tok _ = false
  fun one_tok pps =
    if length (List.filter is_tok pps) = 1 then ()
    else raise GrammarError "Must have exactly one TOK in listform elements"
  val {separator, leftdelim, rightdelim, ...} = lrule
  val _ = app check_els [separator, leftdelim, rightdelim]
in
  G Gmerge [(NONE, LISTRULE [lrule])]
end

fun prefer_form_with_tok (G0:grammar) (r as {term_name,tok}) = let
  val G1 = clear_prefs_for term_name G0
in
  fupdate_rules
  (fupdate_rulelist
   (fupdate_rule_by_termtok r (update_rr_pref true))) G1
end

fun set_associativity_at_level G (p, ass) =
  fupdate_rules
  (fupdate_prulelist
   (fn (p', r) =>
    if isSome p' andalso p = valOf p' then
      (p', (case r of
             INFIX(STD_infix(els, _)) => INFIX (STD_infix(els, ass))
           | _ => r))
    else
      (p', r))) G

fun find_partial f [] = NONE
  | find_partial f (x::xs) = let
    in
      case f x of
        NONE => find_partial f xs
      | y => y
    end

fun get_precedence (G:grammar) s = let
  val rules = rules G
  fun check_rule (p, r) = let
    fun elmem s [] = false
      | elmem s (({elements, ...}:rule_record)::xs) =
      Lib.mem (TOK s) (rule_elements elements) orelse elmem s xs
  in
    case r of
      INFIX(STD_infix (elms, assoc)) =>
        if elmem s elms then SOME(Infix(assoc, valOf p))
        else NONE
    | PREFIX(STD_prefix elms) =>
          if elmem s elms then SOME (TruePrefix (valOf p))
          else NONE
    | SUFFIX (STD_suffix elms) => if elmem s elms then SOME (Suffix (valOf p))
                                  else NONE
    | CLOSEFIX elms => if elmem s elms then SOME Closefix else NONE
    | _ => NONE
  end
in
  find_partial check_rule rules
end

fun update_assoc (k,v) alist = let
    val (_, newlist) = Lib.pluck (fn (k', _) => k' = k) alist
  in
    (k,v)::newlist
  end handle _ => (k,v)::alist


fun check c =
  if Char.isAlpha c then Char.toLower c
  else raise GrammarError "Numeric type suffixes must be letters"

fun add_numeral_form G (c, stropt) =
  fupdate_numinfo (update_assoc (check c, stropt)) G

fun give_num_priority G c = let
  val realc = check c
  fun update_fn alist = let
    val (oldval, rest) = Lib.pluck (fn (k,_) => k = realc) alist
  in
    oldval::rest
  end handle _ => raise GrammarError "No such numeral type in grammar"
in
  fupdate_numinfo update_fn G
end

fun remove_numeral_form G c =
  fupdate_numinfo (List.filter (fn (k,v) => k <> (check c))) G

fun merge_specials S1 S2 = let
  val {type_intro = typ1, type_lbracket = tylbk1, type_rbracket = tyrbk1,
       lambda = lam1, type_lambda = tylam1, endbinding = end1,
       restr_binders = res1, res_quanop = resq1} = S1
  val {type_intro = typ2, type_lbracket = tylbk2, type_rbracket = tyrbk2,
       lambda = lam2, type_lambda = tylam2, endbinding = end2,
       restr_binders = res2, res_quanop = resq2} = S2
in
  if typ1 = typ2 andalso tylbk1 = tylbk2 andalso tyrbk1 = tyrbk2 andalso
     lam1 = lam2 andalso tylam1 = tylam2 andalso end1 = end2 andalso resq1 = resq2
  then
    {type_intro = typ1, type_lbracket = tylbk1, type_rbracket = tyrbk1,
     lambda = lam1, type_lambda = tylam1, endbinding = end1,
     restr_binders = Lib.union res1 res2, res_quanop = resq1}
  else
    raise GrammarError "Specials in two grammars don't agree"
end

fun merge_bmaps typestring keyprinter m1 m2 = let
  (* m1 takes precedence - arbitrarily *)
  fun foldfn (k,v,newmap) =
    (if isSome (Binarymap.peek(newmap, k)) then
       Feedback.HOL_WARNING "term_grammar" "merge_grammars"
       ("Merging "^typestring^" has produced a clash on key "^keyprinter k)
     else
       ();
     Binarymap.insert(newmap,k,v))
in
  Binarymap.foldl foldfn m2 m1
end

fun merge_user_additions u1 u2 = let
  val {parsers = ps1, printers = pp1} = u1
  val {parsers = ps2, printers = pp2} = u2
  fun print_nthy {Name,Thy} = Name^"$"^Thy
in
  {parsers  = merge_bmaps "user parsers"  (fn x => x) ps1 ps2,
   printers = merge_bmaps "user printers" print_nthy  pp1 pp2}
end;


fun merge_grammars (G1:grammar, G2:grammar) :grammar = let
  val g0_rules =
    Listsort.sort (fn (e1,e2) => aug_compare(#1 e1, #1 e2))
    (rules G1 @ rules G2)
  val newrules = resolve_same_precs g0_rules
  val newspecials = merge_specials (specials G1) (specials G2)
  val new_numinfo = Lib.union (numeral_info G1) (numeral_info G2)
  val new_oload_info =
    Overload.merge_oinfos (overload_info G1) (overload_info G2)
  val new_uadds = merge_user_additions (user_additions G1) (user_additions G2)
in
  GCONS {rules = newrules, specials = newspecials, numeral_info = new_numinfo,
         overload_info = new_oload_info, user_additions = new_uadds}
end

(* ----------------------------------------------------------------------
 * Prettyprinting grammars
 * ---------------------------------------------------------------------- *)

datatype ruletype_info = add_prefix | add_suffix | add_both | add_nothing

fun prettyprint_grammar pstrm (G :grammar) = let
  open Portable
  val {add_string, add_break, begin_block, end_block,
       add_newline,...} = with_ppstream pstrm

  fun pprint_rr m (rr:rule_record) = let
    val rels = rule_elements (#elements rr)
    val (pfx, sfx) =
      case m of
        add_prefix => ("", " TM")
      | add_suffix => ("TM ", "")
      | add_both => ("TM ", " TM")
      | add_nothing => ("", "")
    fun special_case s =
      if s = bracket_special then "just parentheses, no term produced"
      else if s = recsel_special then "record field selection"
      else if s = recupd_special then "record field update"
      else if s = recfupd_special then "functional record update"
      else if s = recwith_special then "record update"
      else s

    val tmid_suffix0 = "  ["^ special_case (#term_name rr)^"]"
    val tmid_suffix =
      case rels of
        [TOK s] => if s <> #term_name rr then tmid_suffix0 else ""
      | _ => tmid_suffix0
  in
    begin_block INCONSISTENT 2;
    add_string pfx;
    pr_list (fn (TOK s) => add_string ("\""^s^"\"") | TM => add_string "TM")
            (fn () => add_string " ") (fn () => ()) rels;
    add_string sfx;
    add_string tmid_suffix;
    end_block ()
  end


  fun pprint_rrl (m:ruletype_info) (rrl : rule_record list) = let
  in
    begin_block INCONSISTENT 0;
    pr_list (pprint_rr m) (fn () => add_string " |")
            (fn () => add_break(1,0)) rrl;
    end_block ()
  end

  fun print_binder b = let
    val bname0 =
      case b of
        LAMBDA => #lambda (specials G)
      | BinderString s => s
      | TypeBinderString s => s
    val bname = "\"" ^ bname0 ^ "\""
    val endb = "\"" ^ #endbinding (specials G) ^ "\""
  in
    add_string (bname ^ " <..binders..>  " ^ endb ^ " TM")
  end


  fun print_binderl bl = let
  in
    begin_block INCONSISTENT 0;
    pr_list print_binder (fn () => add_string " |")
            (fn () => add_break (1,0)) bl;
    end_block()
  end


  fun pprint_grule (r: grammar_rule) =
    case r of
      PREFIX (STD_prefix rrl) => pprint_rrl add_prefix rrl
    | PREFIX (BINDER blist) => print_binderl blist
    | SUFFIX (STD_suffix rrl) => pprint_rrl add_suffix rrl
    | SUFFIX TYPE_annotation => let
        val type_intro = #type_intro (specials G)
      in
        add_string ("TM \""^type_intro^"\" TY  (type annotation)")
      end
    | SUFFIX TYPE_application => let
        val type_lbracket = #type_lbracket (specials G)
        val type_rbracket = #type_rbracket (specials G)
      in
        add_string ("TM \""^type_lbracket^"\" TY, ..., TY \""^type_rbracket^"\"  (type application)")
      end
    | INFIX (STD_infix (rrl, a)) => let
        val assocstring =
          case a of
            LEFT => "L-"
          | RIGHT => "R-"
          | NONASSOC => "non-"
      in
        begin_block CONSISTENT 0;
        pprint_rrl add_both rrl;
        add_break (3,0);
        add_string ("("^assocstring^"associative)");
        end_block()
      end
    | INFIX RESQUAN_OP => let
        val rsqstr = #res_quanop (specials G)
      in
        add_string ("TM \""^rsqstr^
                    "\" TM (restricted quantification operator)")
      end
    | CLOSEFIX rrl => pprint_rrl add_nothing rrl
    | INFIX (FNAPP rrl) => let
      in
        begin_block CONSISTENT 0;
        add_string "TM TM  (function application) |";
        add_break(1,0);
        pprint_rrl add_both rrl;
        add_break(3,0);
        add_string ("(L-associative)");
        end_block()
      end
    | INFIX VSCONS => add_string "TM TM  (binder argument concatenation)"
    | LISTRULE lrs => let
        fun pr_lrule ({leftdelim, rightdelim, separator, ...}:listspec) =
          add_string ("\""^first_tok leftdelim^"\" ... \""^
                      first_tok rightdelim^
                      "\"  (separator = \""^ first_tok separator^"\")")
      in
        begin_block CONSISTENT 0;
        pr_list pr_lrule (fn () => add_string " |")
                         (fn () => add_break(1,0)) lrs;
        end_block ()
      end

  fun print_whole_rule (intopt, rule) = let
    val precstr0 =
      case intopt of
        NONE => ""
      | SOME n => "("^Int.toString n^")"
    val precstr = StringCvt.padRight #" " 7 precstr0
  in
    begin_block CONSISTENT 0;
    add_string precstr;
    add_string "TM  ::=  ";
    pprint_grule rule;
    end_block()
  end
  fun uninteresting_overload (k,r:Overload.overloaded_op_info) =
    length (#actual_ops r) = 1 andalso
    #Name (hd (#actual_ops r)) = k andalso
    length (Term.decls k) = 1
  fun print_overloading oinfo0 =
    if List.all uninteresting_overload oinfo0 then ()
    else let
      open Lib infix ##
      fun nblanks n = String.implode (List.tabulate(n, (fn _ => #" ")))
      val oinfo1 = List.filter (not o uninteresting_overload) oinfo0
      val oinfo = Listsort.sort (String.compare o (#1 ## #1)) oinfo1
      val max =
        List.foldl (fn (oi,n) => Int.max(String.size (#1 oi),
                                         n))
        0
        oinfo
      fun pr_ov (overloaded_op,
                (r as {actual_ops,...}:Overload.overloaded_op_info)) =
       let
        fun pr_name (r:Overload.const_rec) =
          case Term.decls (#Name r) of
            [] => raise Fail "term_grammar.prettyprint: should never happen"
          | [_] => #Name r
          | _ => (#Thy r) ^ "$" ^ (#Name r)
      in
        begin_block INCONSISTENT 0;
        add_string (overloaded_op^
                    nblanks (max - String.size overloaded_op)^
                    " -> ");
        add_break(1,2);
        begin_block INCONSISTENT 0;
        pr_list (add_string o pr_name) (fn () => ()) (fn () => add_break (1,0))
                actual_ops;
        end_block();
        end_block()
      end
    in
      add_newline();
      add_string "Overloading:";
      add_break(1,2);
      begin_block CONSISTENT 0;
      pr_list pr_ov (fn () => ()) add_newline oinfo;
      end_block ()
    end
  fun print_user_printers {printers, parsers} = let
    fun sort ({Name = n1, Thy = t1}, {Name = n2, Thy = t2}) =
        case String.compare (t1,t2) of
          EQUAL => String.compare (n1, n2)
        | x => x
    fun print_type {Name,Thy} = add_string (Thy^"$"^Name)
  in
    if Binarymap.numItems printers = 0 then ()
    else
      (add_newline();
       add_string "User printing functions exist for:";
       add_newline();
       add_string "  ";
       begin_block INCONSISTENT 0;
       pr_list print_type (fn () => ()) (fn () => add_break(1,0))
               (Listsort.sort sort (map #1 (Binarymap.listItems printers)));
       end_block())
  end

in
  begin_block CONSISTENT 0;
  (* rules *)
  pr_list print_whole_rule (fn () => ()) (fn () => add_break (1,0)) (rules G);
  add_newline();
  (* known constants *)
  add_string "Known constants:";
  add_break(1,2);
  begin_block INCONSISTENT 0;
  pr_list add_string (fn () => ()) (fn () => add_break(1,0))
                     (Listsort.sort String.compare (known_constants G));
  end_block ();
  (* overloading *)
  print_overloading (Overload.oinfo_ops (overload_info G));
  print_user_printers (user_additions G);
  end_block ()
end


end; (* struct *)
