" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-03-04
" @Revision:    74


if !exists('g:loaded_tlib') || g:loaded_tlib < 122
    runtime plugin/tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 122
        echoerr 'tlib >= 1.22 is required'
        finish
    endif
endif

TLet g:tfiles#world = {
            \ 'type': 'm',
            \ 'query': 'Select files',
            \ 'scratch': '__tfiles__',
            \ 'return_agent': 'tlib#agent#ViewFile',
            \ 'pick_last_item': 0,
            \ 'key_handlers': [
            \   {'key':  4,  'agent': 'tfiles#AgentDeleteFile',            'key_name': '<c-d>', 'help': 'Delete file(s)'},
            \   {'key': 19,  'agent': 'tlib#agent#EditFileInSplit',        'key_name': '<c-s>', 'help': 'Edit files (split)'},
            \   {'key': 22,  'agent': 'tlib#agent#EditFileInVSplit',       'key_name': '<c-v>', 'help': 'Edit files (vertical split)'},
            \   {'key': 20,  'agent': 'tlib#agent#EditFileInTab',          'key_name': '<c-t>', 'help': 'Edit files (new tab)'},
            \   {'key': 23,  'agent': 'tlib#agent#ViewFile',               'key_name': '<c-w>', 'help': 'View file in window'},
            \   {'key': 21,  'agent': 'tfiles#AgentRenameFile',            'key_name': '<c-u>', 'help': 'Rename file(s)'},
            \   {'key': 3,   'agent': 'tlib#agent#CopyItems',              'key_name': '<c-c>', 'help': 'Copy file name(s)'},
            \   {'key': 11,  'agent': 'tfiles#AgentCopyFile',              'key_name': '<c-k>', 'help': 'Copy file(s)'},
            \   {'key':  2,  'agent': 'tfiles#AgentBatchRenameFile',       'key_name': '<c-b>', 'help': 'Batch rename file(s)'},
            \   {'key': 9,   'agent': 'tlib#agent#ShowInfo',               'key_name': '<c-i>', 'help': 'Show info'},
            \   {'key': 28,  'agent': 'tlib#agent#ToggleStickyList',       'key_name': '<c-\>', 'help': 'Toggle sticky'},
            \   {'key': 07,  'agent': 'tfiles#AgentOpenFile',              'key_name': '<c-g>', 'help': 'Open file with system viewer'},
            \ ],
            \ }
" \ 'scratch_vertical': (&lines > &co),
" \ 'display_format': 'tselectfiles#FormatEntry(world, %s)',
" \ 'filter_format': 'tselectfiles#FormatFilter(world, %s)',
" \ {'key': 18,  'agent': 'tselectfiles#AgentReset'},
" \   {'key':  7,  'agent': 'tselectfiles#Grep',                 'key_name': '<c-g>', 'help': 'Run vimgrep on selected files'},
" \   {'key': 24,  'agent': 'tselectfiles#AgentHide',            'key_name': '<c-x>', 'help': 'Hide some files'},
" \   {'key': 126, 'agent': 'tselectfiles#AgentSelectBackups',   'key_name': '~',     'help': 'Select backup(s)'},
            " \   {'key': 16,  'agent': 'tselectfiles#AgentPreviewFile',     'key_name': '<c-p>', 'help': 'Preview file'},


let s:cache = {}

function! tfiles#Find(args, ...) abort "{{{3
    let opts = tlib#arg#GetOpts(a:args, {})
    TVarArg ['rescan', get(opts, 'rescan', 0)]
    let cwd = getcwd()
    let dir = get(opts, 'dir', cwd)
    let glob = get(opts, 'glob', '**')
    if dir !=# cwd
        let glob = tlib#file#Join([dir, glob])
    endif
    let id = printf('%s|%s', dir, glob)
    Tlibtrace 'tfiles', rescan, glob, id
    let files = tlib#cache#ValueFromName('tfiles', id, function('tfiles#Glob'), rescan ? -1 : 0, [glob])
    " if rescan || !has_key(s:cache, id)
    "     let files = tlib#cache#ValueFromName('tfiles', id, function('tfiles#Glob'), 0, [glob])
    "     let s:cache[id] = files
    " else
    "     let files = s:cache[id]
    " endif
    let glob_patterns = get(opts, '__rest__', [])
    let rx_patterns = map(copy(glob_patterns), 'glob2regpat(v:val)')
    let files1 = copy(files)
    if !empty(rx_patterns)
        for rx_pattern in rx_patterns
            let files1 = filter(files1, 'v:val =~ rx_pattern')
        endfor
    endif
    let w = tlib#World#New(g:tfiles#world)
    let w.working_dir = dir
    call w.Set_display_format('filename')
    let w.base = files1
    let cfiles = map(copy(files1), 'tlib#file#Canonic(v:val)')
    let cbufname = tlib#file#Canonic(expand('%:p'))
    let ldir = len(dir)
    if strpart(cbufname, 0, ldir) ==# dir
        let cbufname = cbufname[ldir : -1]
        let cbufname = substitute(cbufname, '^[\/]', '', '')
    endif
    let bidx = index(cfiles, cbufname)
    if bidx != -1
        let w.initial_index = bidx + 1
    endif
    let fs = tlib#input#ListW(w)
endf


function! tfiles#Glob(glob) abort "{{{3
    let files = glob(a:glob, 0, 1)
    let files = tlib#file#FilterFiles(files, {'all': 0, 'type': 'f'})
    return files
endf


let s:tfiles_args = {
            \ 'help': ':Tfiles',
            \ 'trace': 'tfiles',
            \ 'values': {
            \   'glob': {'type': 1},
            \   'rescan': {'type': -1},
            \ },
            \ }
            " \ 'flags': {
            " \ },


function! tfiles#CComplete(ArgLead, CmdLine, CursorPos) abort "{{{3
    let words = tlib#arg#CComplete(s:tfiles_args, a:ArgLead)
    if !empty(a:ArgLead)
    endif
    return sort(words)
endf


function! tfiles#AgentDeleteFile(world, selected)
    call a:world.CloseScratch()
    let s:delete_this_file_default = ''
    for file in a:selected
        call s:DeleteFile(file)
    endfor
    return s:ResetInputList(a:world)
endf


function! s:DeleteFile(file)
    let doit = input('Really delete file '. string(a:file) .'? (y/N) ', s:delete_this_file_default)
    echo
    if doit ==? 'y'
        if doit ==# 'Y'
            let s:delete_this_file_default = 'y'
        endif
        call delete(a:file)
        echom 'Delete file: '. a:file
        let bn = bufnr(a:file)
        if bn != -1 && bufloaded(bn)
            let doit = input('Delete corresponding buffer '. bn .' too? (y/N) ')
            if doit ==? 'y'
                exec 'bdelete '. bn
            endif
        endif
    endif
endf


function! s:ConfirmCopyMove(query, src, dest)
    echo
    echo 'From: '. a:src
    echo 'To:   '. a:dest
    let ok = input(a:query .'(y/n) ', 'y')
    echo
    return ok[0] ==? 'y'
endf


function! s:RenameFile(file, name, confirm)
    if a:name != '' && (!a:confirm || s:ConfirmCopyMove('Rename now?', a:file, a:name))
        call rename(a:file, a:name)
        echom 'Rename file "'. a:file .'" -> "'. a:name
        if bufloaded(a:file)
            exec 'buffer! '. bufnr('^'. a:file .'$')
            exec 'file! '. tlib#arg#Ex(a:name)
            echom 'Rename buffer: '. a:file .' -> '. a:name
        endif
    endif
endf


function! tfiles#AgentRenameFile(world, selected)
    let s:rename_this_file_pattern = ''
    let s:rename_this_file_subst   = ''
    call a:world.CloseScratch()
    for file in a:selected
        let name = input('Rename "'. file .'" to: ', file)
        echo
        call s:RenameFile(file, name, 0)
    endfor
    return s:ResetInputList(a:world)
endf


function! tfiles#AgentBatchRenameFile(world, selected)
    let pattern = input('Rename pattern (whole path): ')
    if pattern != ''
        echo 'Pattern: '. pattern
        let subst = input('Rename substitution: ')
        if subst != ''
            call a:world.CloseScratch()
            for file in a:selected
                let name = substitute(file, pattern, subst, 'g')
                call s:RenameFile(file, name, 1)
            endfor
        endif
    endif
    echo
    return s:ResetInputList(a:world)
endf


function! s:RenameFile(file, name, confirm)
    if a:name != '' && (!a:confirm || s:ConfirmCopyMove('Rename now?', a:file, a:name))
        call rename(a:file, a:name)
        echom 'Rename file "'. a:file .'" -> "'. a:name
        if bufloaded(a:file)
            exec 'buffer! '. bufnr('^'. a:file .'$')
            exec 'file! '. tlib#arg#Ex(a:name)
            echom 'Rename buffer: '. a:file .' -> '. a:name
        endif
    endif
endf


function! tfiles#AgentRenameFile(world, selected)
    let s:rename_this_file_pattern = ''
    let s:rename_this_file_subst   = ''
    call a:world.CloseScratch()
    for file in a:selected
        let name = input('Rename "'. file .'" to: ', file)
        echo
        call s:RenameFile(file, name, 0)
    endfor
    return s:ResetInputList(a:world)
endf

function! tfiles#AgentBatchRenameFile(world, selected)
    let pattern = input('Rename pattern (whole path): ')
    if pattern != ''
        echo 'Pattern: '. pattern
        let subst = input('Rename substitution: ')
        if subst != ''
            call a:world.CloseScratch()
            for file in a:selected
                let name = substitute(file, pattern, subst, 'g')
                call s:RenameFile(file, name, 1)
            endfor
        endif
    endif
    echo
    return s:ResetInputList(a:world)
endf


function! s:ResetInputList(world) abort "{{{3
    unlet! s:cache[a:world.working_dir]
    return a:world
endf


function! s:CopyFile(src, dest, confirm)
    if a:src != '' && a:dest != '' && (!a:confirm || s:ConfirmCopyMove('Copy now?', a:src, a:dest))
        let fc = readfile(a:src, 'b')
        if writefile(fc, a:dest, 'b') == 0
            echom 'Copy file "'. a:src .'" -> "'. a:dest
        else
            echom 'Failed: Copy file "'. a:src .'" -> "'. a:dest
        endif
    endif
endf


function! tfiles#AgentCopyFile(world, selected)
    for file in a:selected
        let name = input('Copy "'. file .'" to: ', file)
        echo
        call s:CopyFile(file, name, 0)
    endfor
    return s:ResetInputList(a:world)
endf


function! tfiles#AgentOpenFile(world, selected) abort "{{{3
    for file in a:selected
        call tlib#sys#OpenWithSystemViewer(file)
    endfor
    let a:world.state = 'exit'
    return a:world
endf

