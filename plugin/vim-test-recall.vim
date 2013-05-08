
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" SWITCH BETWEEN TEST AND PRODUCTION CODE
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! OpenTestAlternate()
  let new_file = AlternateForCurrentFile()
  exec ':e ' . new_file
endfunction

function! AlternateForCurrentFile()
  let current_file = expand("%")
  let new_file = current_file
  let in_spec = match(current_file, '^spec/') != -1
  let in_feature = match(current_file, '\.feature$') != -1
  let in_step_def = match(current_file, '^features/step_definitions/') != -1
  let going_to_spec = !in_spec
  let in_app = match(current_file, '\<controllers\>') != -1 || match(current_file, '\<models\>') != -1 || match(current_file, '\<views\>') != -1

  if in_feature
    " go to step defs file
    " features/choose_plan.feature
    let new_file = substitute(new_file, '\.feature$', '_steps.rb', '')
    " features/choose_plan_steps.rb
    let new_file = substitute(new_file, 'features/', 'features/step_definitions/', '')
    " features/step_definitions/choose_plan_steps.rb
  elseif in_spec
    " go to implementation file
    let new_file = substitute(new_file, 'erb_spec\.rb$', 'erb', '')
    let new_file = substitute(new_file, '_spec\.rb$', '.rb', '')
    let new_file = substitute(new_file, '^spec/', '', '')
    if in_app
      let new_file = 'app/' . new_file
    end
  elseif in_step_def
    " go to feature file
    " features/step_definitions/choose_plan_steps.rb
    let new_file = substitute(new_file, '_steps\.rb$', '.feature', '')
    " features/step_definitions/choose_plan.feature
    let new_file = substitute(new_file, 'step_definitions/', '', '')
    " features/choose_plan.feature
  else
    " go to spec file
    if in_app
      let new_file = substitute(new_file, '^app/', '', '')
    end
    let new_file = substitute(new_file, '\.rb$', '_spec.rb', '')
    let new_file = substitute(new_file, '\.erb$', '\.erb_spec.rb', '')
    let new_file = 'spec/' . new_file
  endif

  return new_file
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" RUNNING TESTS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Test Runner that I started messing arround with for use in MacVim so that I
" could have the tests run and use the AnsiEsc plugin to interpret the ansi
" color codes output by the test commands. This is only necessary because
" MacVim does not run in a terminal their for the terminal isn't there to
" interpret the ansi color codes. Also note this oppens a new scratch buffer
" to put the test output into. It does this because I couldn't figure out how
" to tie AnsiEsc into the :! execution path.
function! BufferedRunTests(filename)
  enew
  setlocal modifiable
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
  nnoremap <buffer> <enter> :bd<CR>
  exec ":silent! AnsiEsc"

  if match(a:filename, '\.feature') != -1
      if filereadable("zeus.json")
        exec ":!zeus cucumber " . a:filename
      elseif filereadable("script/features")
        exec ":!script/features " . a:filename
      else
        exec ":!bundle exec cucumber " . a:filename
      end
  else
      if filereadable("zeus.json")
          exec ":silent read !zeus test --color --tty " . a:filename . " 2>&1"
      elseif filereadable("script/test")
          exec ":!script/test " . a:filename
      elseif filereadable("Gemfile")
        " :cexpr system('bundle exec rspec --color '.a:filename.' 2>&1')
          exec ":silent! read !bundle exec rspec --color --tty " . a:filename . " 2>&1"
      else
        " :cexpr system('rspec --color '.a:filename.' 2>&1')
          exec ":silent! read !rspec --color --tty " . a:filename . " 2>&1"
      end
  end
  setlocal nomodifiable
endfunction

" This is another variation of test runner that I was playing around with
" just to see if I would like this type of dev/test workflow. When the tests
" are run it opens the scratch buffer in a pane and outputs the test run
" there. Then if tests are run again it simply updates that buffer. The
" concept behind this workflow was simply that there was a persistent pane up
" with the test output all the time, unless you explicitly closed it of
" course. This was intended to be used in the terminal, not in MacVim.
function! PersistetBufferRunTests(filename)
    " :w
    let winnr = bufwinnr('^_drew_run_tests_output$')
    if ( winnr >= 0 )
      execute winnr . 'wincmd w'
      setlocal modifiable
      execute 'normal ggdG'
    else
      botright new _drew_run_tests_output
      setlocal modifiable
      setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
      exec ":silent! AnsiEsc"
    endif
    :silent !echo;echo;echo;echo;echo;echo;echo;echo;echo;echo
    :silent !echo;echo;echo;echo;echo;echo;echo;echo;echo;echo
    :silent !echo;echo;echo;echo;echo;echo;echo;echo;echo;echo
    :silent !echo;echo;echo;echo;echo;echo;echo;echo;echo;echo
    :silent !echo;echo;echo;echo;echo;echo;echo;echo;echo;echo
    :silent !echo;echo;echo;echo;echo;echo;echo;echo;echo;echo
    if match(a:filename, '\.feature') != -1
        if filereadable("zeus.json")
          exec ":!zeus cucumber " . a:filename
        elseif filereadable("script/features")
          exec ":!script/features " . a:filename
        else
          exec ":!bundle exec cucumber " . a:filename
        end
    else
        if filereadable("zeus.json")
            exec ":!zeus test " . a:filename
        elseif filereadable("script/test")
            exec ":!script/test " . a:filename
        elseif filereadable("Gemfile")
          " :cexpr system('bundle exec rspec --color '.a:filename.' 2>&1')
            exec ":silent! read !bundle exec rspec --color --tty " . a:filename . " 2>&1"
        else
          " :cexpr system('rspec --color '.a:filename.' 2>&1')
            exec ":silent! read !rspec --color --tty " . a:filename . " 2>&1"
        end
    end
    setlocal nomodifiable
endfunction

function! RunCucumberTest(filename)
  if executable("spring")
    exec ":!spring cucumber " . a:filename
  elseif filereadable("zeus.json")
    exec ":!zeus cucumber " . a:filename
  elseif filereadable("script/features")
    exec ":!script/features " . a:filename
  else
    exec ":!bundle exec cucumber " . a:filename
  end
endfunction

function! RunRSpecTest(filename)
  if executable("spring")
    exec ":!spring rspec --color " . a:filename
  elseif filereadable("zeus.json")
    exec ":!zeus test --color " . a:filename
  elseif filereadable("script/test")
    exec ":!script/test " . a:filename
  elseif filereadable("Gemfile")
    exec ":!bundle exec rspec --color " . a:filename
  else
    exec ":!rspec --color " . a:filename
  end
endfunction

function! RunTests(filename)
  :w
  if match(a:filename, '\.feature') != -1
    call RunCucumberTest(a:filename)
  else
    call RunRSpecTest(a:filename)
  end
endfunction

function! StoreCurrentFileAsTestFile()
  let t:grb_test_file=@%
endfunction

function! StoreCurrentLineNumAsTestLineNum()
  let t:grb_test_line=line('.')
endfunction

function! RemoveTestLineNum()
  if exists("t:grb_test_line")
    unlet t:grb_test_line
  end
endfunction

function! RunNearestTest()
  let in_test_file = match(expand("%"), '\(.feature\|_spec.rb\)$') != -1
  if in_test_file
    call StoreCurrentFileAsTestFile()
    call StoreCurrentLineNumAsTestLineNum()
  elseif !exists("t:grb_test_file") || !exists("t:grb_test_line")
    return
  end
  call RunTests(t:grb_test_file . ":" . t:grb_test_line)
endfunction

function! RunTestsInCurrentFile()
  call RunTests(expand("%"))
endfunction

function! RunAllTestsInCurrentTestFile()
  let in_test_file = match(expand("%"), '\(.feature\|_spec.rb\)$') != -1
  if in_test_file
    call StoreCurrentFileAsTestFile()
    call RemoveTestLineNum()
  elseif !exists("t:grb_test_file")
    return
  end
  call RunTests(t:grb_test_file)
endfunction

function! RunAllRSpecTests()
  call RunTests('spec/')
endfunction

function! RunAllCucumberFeatures()
  call RunCucumberTest("")
endfunction

function! RunWipCucumberFeatures()
  call RunCucumberTest("--profile wip")
endfunction
