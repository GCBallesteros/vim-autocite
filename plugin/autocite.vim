" Bibtex citation autocompletion
"
" This code has been extracted and modified from the vim-latex plugin
" written by
"
" vim-latex: https://github.com/lervag/vim-latex
"
" Maintener: Guillem Ballesteros
" Email: guillem.ballesteros.garcia@gmail.com
"

function! autocite#init() " {{{1
  "
  " Check if bibtex is available
  "
  if !executable('bibtex')
    echom "Warning: bibtex completion not available"
    echom "         Missing executable: bibtex"
    let s:bibtex = 0
  endif

  setlocal omnifunc=autocite#Complete
endfunction


let g:autocite_complete_patterns = {
         \ 'bib':   '\C\a*\[cite:\_\s*[^:\]]*',
         \ 'bibnp': '\C\a*\[citenp:\_\s*[^:\]]*'
         \ }


function! autocite#Complete(findstart, base) " {{{0
  if a:findstart
    "
    " First call:  Find start of text to be completed
    "
    " Note: g:autocite_complete_patterns is a dictionary where the keys are the
    " types of completion and the values are the patterns that must match for
    " the given type.  Currently, it completes for asciidoc-bib citation
    " syntax. [cite:] and [citenp:]
    "
    let pos  = col('.') - 1
    let line = getline('.')[:pos-1]
    for [type, pattern] in items(g:autocite_complete_patterns)
      if line =~ pattern . '$'
        let s:completion_type = type
        while pos > 0
          if line[pos - 1] =~ ':\|,' || line[pos-2:pos-1] == ', '
            return pos
          else
            let pos -= 1
          endif
        endwhile
        return -2
      endif
    endfor
  else
    return autocite#bibtex(a:base)
  endif
endfunction

" Define auxiliary variables for completion
let s:bibtex = 1
let s:completion_type = ''


function! autocite#bibtex(regexp) " {{{1
  let res = []

  let s:type_length = 4
  for m in s:bibtex_search(a:regexp)
    let type = m['type']   == '' ? '[-]' : '[' . m['type']   . '] '
    let auth = m['author'] == '' ? ''    :       m['author'][:20] . ' '
    let year = m['year']   == '' ? ''    : '(' . m['year']   . ')'

    " Align the type entry and fix minor annoyance in author list
    let type = printf('%-' . s:type_length . 's', type)
    let auth = substitute(auth, '\~', ' ', 'g')
    let auth = substitute(auth, ',.*\ze', ' et al. ', '')

    let w = {
          \ 'word': m['key'],
          \ 'abbr': type . auth . year,
          \ 'menu': m['title']
          \ }

    call add(res, w)
  endfor

  return res
endfunction
" }}}1


" Define some auxiliary variables
let s:bstfile = expand('<sfile>:p:h') . '/vimcomplete'
let s:type_length = 0


function! s:bibtex_search(regexp) " {{{2
  let res = []

  " Find data from external bib files
  let bibfiles = join(s:bibtex_find_bibs(), ',')
  if bibfiles != ''
    " Define temporary files
    let tmp = {
          \ 'aux' : 'tmpfile.aux',
          \ 'bbl' : 'tmpfile.bbl',
          \ 'blg' : 'tmpfile.blg',
          \ }

    " Write temporary aux file
    call writefile([
          \ '\citation{*}',
          \ '\bibstyle{' . s:bstfile . '}',
          \ '\bibdata{' . bibfiles . '}',
          \ ], tmp.aux)

    " Create the temporary bbl file
    let exe = {}
    let exe.cmd = 'bibtex -terse ' . tmp.aux
    let exe.bg = 0
    call autocite#execute(exe)

    " Parse temporary bbl file
    let lines = split(substitute(join(readfile(tmp.bbl), "\n"),
          \ '\n\n\@!\(\s\=\)\s*\|{\|}', '\1', 'g'), "\n")

    for line in filter(lines, 'v:val =~ a:regexp')
      let matches = matchlist(line,
            \ '^\(.*\)||\(.*\)||\(.*\)||\(.*\)||\(.*\)')
      if !empty(matches) && !empty(matches[1])
        let s:type_length = max([s:type_length, len(matches[2]) + 3])
        call add(res, {
              \ 'key':    matches[1],
              \ 'type':   matches[2],
              \ 'author': matches[3],
              \ 'year':   matches[4],
              \ 'title':  matches[5],
              \ })
      endif
    endfor

    " Clean up
    call delete(tmp.aux)
    call delete(tmp.bbl)
    call delete(tmp.blg)
  endif

  return res
endfunction

function! s:bibtex_find_bibs() " {{{1
  let bibfiles = []

  "
  " Search for added bibliographies in current file
  " * Parse lines searching for bibtexfile:my_bib.bib
  " The recommended usage is adding a commented line
  " in the document e.g.
  " // bibtexfile:my_bib.bib
  "
  " * This also removes the .bib extensions
  "
  if g:autocite_search_in_doc
    let re_bibs = '"\\(bibtexfile:\\)\\@<=.\\+"'
    let find_bib_lines = 'v:val =~ "bibtexfile:"'

    let lines = readfile(expand("%"))
    let bib_in_doc=map(filter(copy(lines), find_bib_lines),
                   \ 'matchstr(v:val, ' . re_bibs . ')')

    for line in bib_in_doc
        let bibfiles += map(split(line, ','), 'v:val')
    endfor

    " Check if specified bibliographies point to a valid file
    let bibfiles = filter(bibfiles, 'filereadable(v:val)')
  endif


  "
  " Search for bibliographies in the directory where
  " the document is stored.
  "
  if g:autocite_search_in_dir
    let bibs_in_dir = split(globpath(fnamemodify(expand("%:p"), ":h"), '*.bib'), '\n')
    let bibfiles = bibfiles + bibs_in_dir
  endif

  return bibfiles
endfunction

" }}}1


function! autocite#execute(exe) " {{{1
  " Execute the given command on the current system.  Wrapper function to make
  " it easier to run on both windows and unix.
  "
  " The command is given in the argument exe, which should be a dictionary with
  " the following entries:
  "
  "   exe.cmd     String          String that contains the command to run
  "   exe.bg      0 or 1          Run in background or not
  "   exe.silent  0 or 1          Show output or not
  "   exe.null    0 or 1          Send output to /dev/null
  "   exe.wd      String          Run command in provided working directory
  "
  " Only exe.cmd is required.
  "

  " Check and parse arguments
  if !has_key(a:exe, 'cmd')
    echoerr "Error in latex#util#execute!"
    echoerr "Argument error, exe.cmd does not exist!"
    return
  endif
  let bg     = has_key(a:exe, 'bg')     ? a:exe.bg     : 1
  let silent = has_key(a:exe, 'silent') ? a:exe.silent : 1
  let null   = has_key(a:exe, 'null')   ? a:exe.null   : 1

  " Change directory if wanted
  if has_key(a:exe, 'wd')
    let pwd = getcwd()
    execute 'lcd ' . a:exe.wd
  endif

  " Set up command string based on the given system
  if has('win32')
    if bg
      let cmd = '!start /b ' . a:exe.cmd
    else
      let cmd = '!' . a:exe.cmd
    endif
    if null
      let cmd .= ' >nul'
    endif
  else
    let cmd = '!' . a:exe.cmd
    if null
      let cmd .= ' &>/dev/null'
    endif
    if bg
      let cmd .= ' &'
    endif
  endif

  if silent
    silent execute cmd
  else
    execute cmd
  endif

  " Return to previous working directory
  if has_key(a:exe, 'wd')
    execute 'lcd ' . pwd
  endif

  if !has("gui_running")
    redraw!
  endif
endfunction
" }}}1

" vim: fdm=marker
