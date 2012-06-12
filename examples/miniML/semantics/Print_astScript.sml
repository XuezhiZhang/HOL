(* generated by Lem from print_ast.lem *)
open bossLib Theory Parse res_quanTheory
open finite_mapTheory listTheory pairTheory pred_setTheory integerTheory
open set_relationTheory sortingTheory stringTheory wordsTheory

val _ = new_theory "Print_ast"

open MiniMLTheory

(*open MiniML*)

(*val Num : Int.int -> num*)

(*val CHR : num -> string*)

(*val string_first : string -> string*)

(*val first_ord : string -> num*)

(*val (%) : num -> num -> num*)

val _ = Hol_datatype `
 token =
  WhitespaceT of num
| NewlineT 
| HashT | LparT | RparT | StarT | CommaT | ArrowT | DotsT | ColonT | SealT 
| SemicolonT | EqualsT | DarrowT | LbrackT | RbrackT | UnderbarT | LbraceT 
| BarT | RbraceT | AbstypeT | AndT | AndalsoT | AsT | CaseT | DatatypeT | DoT 
| ElseT | EndT | EqtypeT | ExceptionT | FnT | FunT | FunctorT | HandleT | IfT 
| InT | IncludeT | InfixT | InfixrT | LetT | LocalT | NonfixT | OfT | OpT 
| OpenT | OrelseT | RaiseT | RecT | SharingT | SigT | SignatureT | StructT 
| StructureT | ThenT | TypeT | ValT | WhereT | WhileT | WithT | WithtypeT 
| ZeroT 
| DigitT of string
| NumericT of string
| IntT of int
| HexintT of string
| WordT of string
| HexwordT of string
| RealT of string
| StringT of string
| CharT of string
| TyvarT of string
| AlphaT of string
| SymbolT of string
| LongidT of string

(* OCaml additions *)
  | MatchT | AmpampT | BarbarT | SemisemiT`;


 val num_to_string_defn = Hol_defn "num_to_string" `
 (num_to_string n acc =
  if n= 0 then
    acc
  else
    num_to_string (n DIV 10) (STRCAT (STRING (CHR  (n MOD 10+ 48)) "")  acc))`;

val _ = Defn.save_defn num_to_string_defn;

(*val int_to_string : bool -> Int.int -> string*)
val _ = Define `
 (int_to_string sml n =
  if n= & 0 then
    "0"
  else if int_gt n (& 0) then
    num_to_string (Num n) ""
  else STRCAT 
    (if sml then "~" else "-") ( num_to_string (Num ((int_sub) (& 0) n)) ""))`;


(*val spaces : num -> string -> string*)
 val spaces_defn = Hol_defn "spaces" `
 
(spaces n s =
  if (n:num)= 0 then
    s
  else STRCAT 
    " "  (spaces (n - 1) s))`;

val _ = Defn.save_defn spaces_defn;

val _ = Define `
 (space_append s1 s2 =
  if s2= "" then
    s1
  else 
    let f =STRING (SUB ( s2,0)) "" in
      if (f= ")")\/ (f= " ")\/ (f= ",") then STRCAT 
    s1  s2
  else STRCAT 
    s1(STRCAT   " "  s2))`;


 val tok_to_string_defn = Hol_defn "tok_to_string" `

(tok_to_string sml NewlineT s =STRCAT  "\n"  s)
/\
(tok_to_string sml (WhitespaceT n) s = spaces n s)
/\
(tok_to_string sml (IntT i) s = space_append (int_to_string sml i) s)
/\
(tok_to_string sml (LongidT id) s = space_append id s)
/\
(tok_to_string sml (TyvarT tv) s = space_append (STRCAT "'"  tv) s)
/\
(tok_to_string sml AndT s =STRCAT  "and "  s)
/\
(tok_to_string sml AndalsoT s =STRCAT  "andalso "  s)
/\
(tok_to_string sml CaseT s =STRCAT  "case "  s)
/\
(tok_to_string sml DatatypeT s =STRCAT  "datatype "  s)
/\
(tok_to_string sml ElseT s =STRCAT  "else "  s)
/\
(tok_to_string sml EndT s =STRCAT  "end "  s)
/\
(tok_to_string sml FnT s =STRCAT  "fn "  s)
/\
(tok_to_string sml FunT s =STRCAT  "fun "  s)
/\
(tok_to_string sml IfT s =STRCAT  "if "  s)
/\
(tok_to_string sml InT s =STRCAT  "in "  s)
/\
(tok_to_string sml LetT s =STRCAT  "let "  s)
/\
(tok_to_string sml OfT s =STRCAT  "of "  s)
/\
(tok_to_string sml OpT s =STRCAT  "op "  s)
/\
(tok_to_string sml OrelseT s =STRCAT  "orelse "  s)
/\
(tok_to_string sml RecT s =STRCAT  "rec "  s)
/\
(tok_to_string sml ThenT s =STRCAT  "then "  s)
/\
(tok_to_string sml ValT s =STRCAT  "val "  s)
/\
(tok_to_string sml LparT s = 
  if s= "" then
    "("
  else if STRING (SUB ( s,0)) ""= "*" then STRCAT 
    "( "  s
  else STRCAT 
    "("  s)
/\
(tok_to_string sml RparT s = space_append ")" s)
/\
(tok_to_string sml CommaT s =STRCAT  ", "  s)
/\
(tok_to_string sml SemicolonT s =STRCAT  ";"  s)
/\
(tok_to_string sml BarT s =STRCAT  "| "  s)
/\
(tok_to_string sml EqualsT s =STRCAT  "= "  s)
/\
(tok_to_string sml DarrowT s =STRCAT  "=> "  s)
/\
(tok_to_string sml ArrowT s =STRCAT  "-> "  s)
/\
(tok_to_string sml StarT s =STRCAT  "* "  s)
/\
(tok_to_string sml MatchT s =STRCAT  "match "  s)
/\
(tok_to_string sml TypeT s =STRCAT  "type "  s)
/\
(tok_to_string sml WithT s =STRCAT  "with "  s)
/\
(tok_to_string sml AmpampT s =STRCAT  "&& "  s)
/\
(tok_to_string sml BarbarT s =STRCAT  "|| "  s)
/\
(tok_to_string sml SemisemiT s =STRCAT  ";;"  s)`;

val _ = Defn.save_defn tok_to_string_defn;

 val tok_list_to_string_defn = Hol_defn "tok_list_to_string" `
 
(tok_list_to_string sml [] = "")
/\
(tok_list_to_string sml (t::l) = 
  tok_to_string sml t (tok_list_to_string sml l))`;

val _ = Defn.save_defn tok_list_to_string_defn;

(*type 'a tree = L of 'a | N of 'a tree * 'a tree*)
val _ = Hol_datatype `
 tok_tree = L of token | N of tok_tree => tok_tree`;


(*val (^^) : forall 'a. 'a tree -> 'a tree -> 'a tree*)
(*val (^^) : tok_tree -> tok_tree -> tok_tree*)

(*val tree_to_list : forall 'a. 'a tree -> 'a list -> 'a list*)
(*val tree_to_list : tok_tree -> token list -> token list*)
 val tree_to_list_defn = Hol_defn "tree_to_list" `

(tree_to_list (L x) acc = x::acc)
/\
(tree_to_list (N x1 x2) acc = tree_to_list x1 (tree_to_list x2 acc))`;

val _ = Defn.save_defn tree_to_list_defn;

(* Should include "^", but I don't know how to get that into HOL, since
 * antiquote seem stronger than strings.  See the specification in
 * print_astProofsScript. *)
val _ = Define `
 (is_sml_infix s =
  let c =ORD (SUB ( s,0)) in
    if c< 65 (* "A" *) then
      if c< 60 (* "<" *) then
        (s= "*")\/
        (s= "+")\/ 
        (s= "-")\/
        (s= "/")\/
        (s= "::")\/ 
        (s= ":=")
      else
        (s= "<")\/ 
        (s= "<=")\/ 
        (s= "<>")\/
        (s= "=")\/ 
        (s= ">")\/ 
        (s= ">=")\/ 
        (s= "@")
    else
      if c< 109 (* "m" *) then
        if c< 100 then
          s= "before"
        else
          s= "div" 
      else
        if c< 111 then
          s= "mod"
        else
          s= "o")`;


val _ = Define `
 (is_ocaml_infix s =
  let c =ORD (SUB ( s,0)) in
    if c< 65 then
      MEM s ["*"; "+"; "-"; "/"; "<"; "<="; "="; ">"; ">="]
    else 
      s= "mod")`;


(*val join_trees : forall 'a. 'a tree -> 'a tree list -> 'a tree*)
(*val join_trees : tok_tree -> tok_tree list -> tok_tree*)
 val join_trees_defn = Hol_defn "join_trees" `

(join_trees sep [x] = x)
/\
(join_trees sep (x::y::l) = N 
  x( N   sep  (join_trees sep (y::l))))`;

val _ = Defn.save_defn join_trees_defn;

 val lit_to_tok_tree_defn = Hol_defn "lit_to_tok_tree" `

(lit_to_tok_tree sml (Bool T) = L (LongidT "true"))
/\
(lit_to_tok_tree sml (Bool F) = L (LongidT "false"))
/\
(lit_to_tok_tree sml (IntLit n) = L (IntT n))`;

val _ = Defn.save_defn lit_to_tok_tree_defn;

val _ = Define `
 (var_to_tok_tree sml v =
  if sml/\ is_sml_infix v then N (
    L OpT) ( L (LongidT v))
  else if ~  sml/\ is_ocaml_infix v then N (
    L LparT)( N  ( L (LongidT v)) ( L RparT))
  else
    L (LongidT v))`;


 val pat_to_tok_tree_defn = Hol_defn "pat_to_tok_tree" `

(pat_to_tok_tree sml (Pvar v) = var_to_tok_tree sml v)
/\
(pat_to_tok_tree sml (Plit l) = lit_to_tok_tree sml l)
/\
(pat_to_tok_tree sml (Pcon c []) = var_to_tok_tree sml c)
/\
(pat_to_tok_tree sml (Pcon c ps) = N (
  L LparT)( N  ( var_to_tok_tree sml c)( N  ( 
    L LparT)( N  ( join_trees (L CommaT) (MAP (pat_to_tok_tree sml) ps))( N  (
    L RparT) ( L RparT))))))`;

val _ = Defn.save_defn pat_to_tok_tree_defn;

val _ = Define `
 (inc_indent i = 
  if (i:num)< 30 then
    i+ 2
  else
    i)`;


val _ = Define `
 (newline indent = N ( 
  L NewlineT) ( L (WhitespaceT indent)))`;


 val exp_to_tok_tree_defn = Hol_defn "exp_to_tok_tree" `

(exp_to_tok_tree sml indent (Raise r) =
  if sml then N (
    L LparT)( N  ( L (LongidT "raise"))( N  ( L (LongidT "Bind")) ( L RparT)))
  else N (
    L LparT)( N  ( L (LongidT "raise"))( N  ( 
      L LparT)( N  ( L (LongidT "Match_failure"))( N  ( 
        L LparT)( N  ( L (LongidT "string_of_bool"))( N  ( L (LongidT "true"))( N  ( 
        L CommaT)( N  (
        L (IntT (& 0)))( N  ( L CommaT)( N  ( L (IntT (& 0)))( N  ( L RparT)( N  (
      L RparT) (
    L RparT))))))))))))))
/\
(exp_to_tok_tree sml indent (Lit l) =
  lit_to_tok_tree sml l)
/\
(exp_to_tok_tree sml indent (Con c []) =
  var_to_tok_tree sml c)
/\
(exp_to_tok_tree sml indent (Con c es) = N (
  L LparT)( N  (
  var_to_tok_tree sml c)( N  ( 
  L LparT)( N  (
  join_trees (L CommaT) (MAP (exp_to_tok_tree sml indent) es))( N  ( 
  L RparT) ( L RparT))))))
/\
(exp_to_tok_tree sml indent (Var v) =
  var_to_tok_tree sml v)
/\
(exp_to_tok_tree sml indent (Fun v e) = N (
  newline indent)( N  (
  L LparT)( N  
  (if sml then L FnT else L FunT)( N  (
  var_to_tok_tree sml v)( N   
  (if sml then L DarrowT else L ArrowT)( N   
  (exp_to_tok_tree sml (inc_indent indent) e) ( 
  L RparT)))))))
/\
(exp_to_tok_tree sml indent (App Opapp e1 e2) = N (
  L LparT)( N  
  (exp_to_tok_tree sml indent e1)( N   
  (exp_to_tok_tree sml indent e2) ( 
  L RparT))))
/\
(exp_to_tok_tree sml indent (App Equality e1 e2) = N (
  L LparT)( N  
  (exp_to_tok_tree sml indent e1)( N  ( 
  L EqualsT)( N   
  (exp_to_tok_tree sml indent e2) ( 
  L RparT)))))
/\
(exp_to_tok_tree sml indent (App (Opn o0) e1 e2) =
  let s = (case o0 of
      Plus => "+"
    | Minus => "-"
    | Times => "*"
    | Divide => if sml then "div" else "/"
    | Modulo => "mod"
  )
  in N (
    L LparT)( N  
    (exp_to_tok_tree sml indent e1)( N  ( 
    L (LongidT s))( N   
    (exp_to_tok_tree sml indent e2) ( 
    L RparT)))))
/\
(exp_to_tok_tree sml indent (App (Opb o') e1 e2) =
  let s = (case o' of
      Lt => "<"
    | Gt => ">"
    | Leq => "<="
    | Geq => ">"
  )
  in N (
    L LparT)( N  
    (exp_to_tok_tree sml indent e1)( N  ( 
    L (LongidT s))( N   
    (exp_to_tok_tree sml indent e2) ( 
    L RparT)))))
/\
(exp_to_tok_tree sml indent (Log lop e1 e2) = N (
  L LparT)( N  
  (exp_to_tok_tree sml indent e1)( N   
  (if lop= And then 
     if sml then L AndalsoT else L AmpampT
   else 
     if sml then L OrelseT else L BarbarT)( N  
  (exp_to_tok_tree sml indent e2) ( 
  L RparT)))))
/\
(exp_to_tok_tree sml indent (If e1 e2 e3) = N (
  newline indent)( N  (
  L LparT)( N  (
  L IfT)( N  
  (exp_to_tok_tree sml indent e1)( N  ( 
  newline indent)( N  (
  L ThenT)( N  
  (exp_to_tok_tree sml (inc_indent indent) e2)( N  (
  newline indent)( N  (
  L ElseT)( N  
  (exp_to_tok_tree sml (inc_indent indent) e3) ( 
  L RparT)))))))))))
/\
(exp_to_tok_tree sml indent (Mat e pes) = N (
  newline indent)( N  (
  L LparT)( N  
  (if sml then L CaseT else L MatchT)( N   
  (exp_to_tok_tree sml indent e)( N   
  (if sml then L OfT else L WithT)( N  (
  newline (inc_indent (inc_indent indent)))( N  (
  join_trees ( N (newline (inc_indent indent)) ( L BarT)) 
               (MAP (pat_exp_to_tok_tree sml (inc_indent indent)) pes)) ( 
  L RparT))))))))
/\
(exp_to_tok_tree sml indent (Let v e1 e2) = N (
  newline indent)( N  
  (if sml then N ( L LetT) ( L ValT) else N ( L LparT) ( L LetT))( N  ( 
  var_to_tok_tree sml v)( N  ( 
  L EqualsT)( N  
  (exp_to_tok_tree sml indent e1)( N  ( 
  newline indent)( N  (
  L InT)( N  
  (exp_to_tok_tree sml (inc_indent indent) e2)  
  (if sml then N ( newline indent) ( L EndT) else L RparT)))))))))
/\
(exp_to_tok_tree sml indent (Letrec funs e) = N (
  newline indent)( N  
  (if sml then N ( L LetT) ( L FunT) else N ( L LparT) ( L RecT))( N  ( 
  join_trees ( N (newline indent) ( L AndT)) 
               (MAP (fun_to_tok_tree sml indent) funs))( N  ( 
  newline indent)( N  (
  L InT)( N  
  (exp_to_tok_tree sml indent e)  
  (if sml then N ( newline indent) ( L EndT) else L RparT)))))))
/\
(pat_exp_to_tok_tree sml indent (p,e) = N (
  pat_to_tok_tree sml p)( N   
  (if sml then L DarrowT else L ArrowT) 
  (exp_to_tok_tree sml (inc_indent (inc_indent indent)) e)))
/\
(fun_to_tok_tree sml indent (v1,v2,e) = N (
  var_to_tok_tree sml v1)( N  (
  var_to_tok_tree sml v2)( N  ( 
  L EqualsT) 
  (exp_to_tok_tree sml (inc_indent indent) e))))`;

val _ = Defn.save_defn exp_to_tok_tree_defn;

 val type_to_tok_tree_defn = Hol_defn "type_to_tok_tree" `

(type_to_tok_tree (Tvar tn) =
  L (TyvarT tn))
/\
(type_to_tok_tree (Tapp ts tn) =
  if ts= [] then
    L (LongidT tn)
  else N (
    L LparT)( N  (
    join_trees (L CommaT) (MAP type_to_tok_tree ts))( N  ( L RparT) ( 
    L (LongidT tn)))))
/\
(type_to_tok_tree (Tfn t1 t2) = N (
  L LparT)( N   (type_to_tok_tree t1)( N  ( L ArrowT)( N   (type_to_tok_tree t2) ( 
  L RparT)))))
/\
(type_to_tok_tree Tnum =
  L (LongidT "int"))
/\
(type_to_tok_tree Tbool =
  L (LongidT "bool"))`;

val _ = Defn.save_defn type_to_tok_tree_defn;

val _ = Define `
 (variant_to_tok_tree sml (c,ts) =
  if ts= [] then
    var_to_tok_tree sml c 
  else N (
    var_to_tok_tree sml c)( N  ( L OfT) ( 
    join_trees (L StarT) (MAP type_to_tok_tree ts))))`;


(*val typedef_to_tok_tree : bool -> num -> tvarN list * typeN * (conN * t list) list -> token tree*)
(*val typedef_to_tok_tree : bool -> num -> tvarN list * typeN * (conN * t list) list -> tok_tree*)
val _ = Define `
 (typedef_to_tok_tree sml indent (tvs, name, variants) = N 
  (if tvs= [] then 
     L (LongidT name)
   else N ( 
     L LparT)( N  ( 
     join_trees (L CommaT) (MAP (\ tv . L (TyvarT tv)) tvs))( N  ( 
     L RparT) (
     L (LongidT name)))))( N  ( 
  L EqualsT)( N  (
  newline (inc_indent (inc_indent indent))) (
  join_trees ( N (newline (inc_indent indent)) ( L BarT)) 
               (MAP (variant_to_tok_tree sml) variants)))))`;


 val dec_to_tok_tree_defn = Hol_defn "dec_to_tok_tree" `
 
(dec_to_tok_tree sml indent (Dlet p e) = N 
  (if sml then L ValT else L LetT)( N  (
  pat_to_tok_tree sml p)( N  ( 
  L EqualsT)( N  (
  exp_to_tok_tree sml (inc_indent indent) e) 
  (if sml then L SemicolonT else L SemisemiT)))))
/\
(dec_to_tok_tree sml indent (Dletrec funs) = N 
  (if sml then L FunT else N ( L LetT) ( L RecT))( N  ( 
  join_trees ( N (newline indent) ( L AndT)) 
             (MAP (fun_to_tok_tree sml indent) funs)) 
  (if sml then L SemicolonT else L SemisemiT)))
/\
(dec_to_tok_tree sml indent (Dtype types) = N 
  (if sml then L DatatypeT else L TypeT)( N  ( 
  join_trees ( N (newline indent) ( L AndT)) 
             (MAP (typedef_to_tok_tree sml indent) types)) 
  (if sml then L SemicolonT else L SemisemiT)))`;

val _ = Defn.save_defn dec_to_tok_tree_defn;

val _ = Define `
 (dec_to_sml_string d = 
  tok_list_to_string T (tree_to_list (dec_to_tok_tree T 0 d) []))`;

val _ = Define `
 (dec_to_ocaml_string d = 
  tok_list_to_string F (tree_to_list (dec_to_tok_tree F 0 d) []))`;

val _ = export_theory()

