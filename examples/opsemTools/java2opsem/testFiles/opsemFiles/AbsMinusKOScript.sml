(* This file has been generated by java2opSem from /home/helen/Recherche/hol/HOL/examples/opsemTools/java2opsem/testFiles/javaFiles/AbsMinusKO.java*)


open HolKernel Parse boolLib
stringLib IndDefLib IndDefRules
finite_mapTheory relationTheory
newOpsemTheory
computeLib bossLib;

val _ = new_theory "AbsMinusKO";

(* Method absMinusKO*)
val MAIN_def =
  Define `MAIN =
    RSPEC
    (\state.
      T)
      (Seq
        (Assign "result" (Const 0))
        (Seq
          (Assign "k"
            (Const 0)
          )
          (Seq
            (Cond 
              (LessEq 
                (Var "i")
                (Var "j")
              )
              (Assign "k"
                (Plus 
                  (Var "k")
                  (Const 1)
                )
              )
              Skip
            )
            (Seq
              (Cond 
                (And 
                  (Equal 
                    (Var "k")
                    (Const 1)
                  )
                  (Not (Equal 
                    (Var "i")
                    (Var "j")
                  ))
                )
                (Assign "result"
                  (Sub 
                    (Var "j")
                    (Var "i")
                  )
                )
                (Assign "result"
                  (Sub 
                    (Var "j")
                    (Var "i")
                  )
                )
              )
              (Assign "Result"
                (Var "result")
              )
            )
          )
        )
      )
    (\state1 state2.
      ((((ScalarOf (state1 ' "i")<ScalarOf (state1 ' "j")))) ==> (((ScalarOf (state2 ' "Result")=ScalarOf (state1 ' "j")-ScalarOf (state1 ' "i")))))/\((((ScalarOf (state1 ' "i")>=ScalarOf (state1 ' "j")))) ==> (((ScalarOf (state2 ' "Result")=ScalarOf (state1 ' "i")-ScalarOf (state1 ' "j"))))))
    `

  val _ = export_theory();
