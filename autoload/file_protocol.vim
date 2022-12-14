function! file_protocol#edit() abort
  let expr = expand('<amatch>')
  let buf = bufnr('%')
  let info = s:parse(expr)
  let opts = printf('++ff=%s ++enc=%s ++%s', &fileformat, &fileencoding, &binary ? 'bin' : 'nobin')
  execute printf('keepalt keepjumps edit %s %s %s', opts, v:cmdarg, fnameescape(info.path))
  if bufname(buf) ==# expr
    execute printf('silent bwipeout! %d', buf)
  endif
  if has_key(info, 'column')
    execute printf('keepjumps normal! %dG%d|zv', info.line, info.column)
  elseif has_key(info, 'line')
    execute printf('keepjumps normal! %dGzv', info.line)
  endif
endfunction

function! file_protocol#read() abort
  let expr = expand('<amatch>')
  let info = s:parse(expr)
  let opts = printf('++ff=%s ++enc=%s ++%s', &fileformat, &fileencoding, &binary ? 'bin' : 'nobin')
  execute printf('read %s %s %s', opts, v:cmdarg, fnameescape(info.path))
endfunction

function! s:parse(bufname) abort
  let path = matchstr(a:bufname, '^file://\zs.*$')
  let m1 = matchlist(path, '^\(.*\):\(\d\+\):\(\d\+\)$')
  if !empty(m1)
    return {
          \ 'path': s:normpath(s:decodeURI(m1[1])),
          \ 'line': m1[2] + 0,
          \ 'column': m1[3] + 0,
          \}
  endif
  let m2 = matchlist(path, '^\(.*\):\(\d\+\)$')
  if !empty(m2)
    return {
          \ 'path': s:normpath(s:decodeURI(m2[1])),
          \ 'line': m2[2] + 0,
          \}
  endif
  return {'path': s:normpath(s:decodeURI(path))}
endfunction

" /home/john%20doe/README.md -> /home/john doe/README.md
function! s:decodeURI(uri) abort
  return substitute(a:uri, '%\([0-9a-fA-F]\{2}\)',
        \ { m -> nr2char(str2nr(m[1], 16)) }, 'g')
endfunction

if !has('win32')
  " /home/john/README.md -> /home/john/README.md
  function! s:normpath(path) abort
    return a:path
  endfunction
else
  " /C/Users/John/README.md  -> C:\Users\John\README.md
  " /C|/Users/John/README.md -> C:\Users\John\README.md
  " /C:/Users/John/README.md -> C:\Users\John\README.md
  " /C:\Users\John\README.md -> C:\Users\John\README.md
  function! s:normpath(path) abort
    let path = substitute(a:path, '^/\([a-zA-Z]\)[:|]\?[/\\]', '\1:/', '')
    return fnamemodify(path, ':gs?/?\\?')
  endfunction
endif
