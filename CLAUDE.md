  ## 1. Planning (PLAN.md)                                                                                                     
  - `PLAN.md` is the single source of truth. Phases are listed at start; only the **current** phase has detailed tasks.        
  - **Phase end**: Mark done with ✅, then expand next phase in-place in `PLAN.md`.                                            
  - **Bug fix / Refactor**: Skip `PLAN.md`. **New feature**: Append description to `PLAN.md` before implementing.              
                                                                                                                               
  ## 2. Checkpoint (Crucial — Do NOT Skip)                                                                                     
  - At end of every phase: summarize work, generate a **Manual Verification Checklist** (UI/UX and business logic flows, not   
  automated tests), and **WAIT for 瑞 to approve** before proceeding.                                                          
                                                                                                                             
  ## 3. Code Standards                                                                                                         
  - **File Headers**: Every source file must begin with a comment block: Summary / Exports+IO / Execution Flow / Design Notes.
  - **Module READMEs**: In major directories: Responsibility / Data Flow / Architecture diagram / Key decisions.               
  - **Test First**: Business logic must have entries in `TESTS.md`. Run all tests before checkpoint.                           
                                                                                                                               
  ## 4. Communication                                                                                                          
  - Always address the user as **瑞** at the start of every reply.                                                             
  - Be concise: Action + Object + Result.                                                                                      