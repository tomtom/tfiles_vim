" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @GIT:         http://github.com/tomtom/vimtlib/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" GetLatestVimScripts: 0 0 tfiles.vim

if &cp || exists("loaded_tfiles")
    finish
endif
let loaded_tfiles = 1

let s:save_cpo = &cpo
set cpo&vim


" :display: :Tfiles[!] [--rescan] [--glob=GLOB_PATTERN] [--dir=DIR] GLOB_FILTERS
" By default, :Tfiles caches file lists as determined by GLOB_PATTERN, 
" which defaults to "**". If a bang "!" or the `--rescan` 
" argument are gives, the disk is rescanned.
command! -nargs=* -bang -bar -complete=customlist,tfiles#CComplete Tfiles call tfiles#Find([<f-args>], !empty("<bang>"))


let &cpo = s:save_cpo
unlet s:save_cpo
