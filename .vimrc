" SEARCHING IN FILES:
   "####################"

   " map vimgrep on F4, search for word under the cursor in all file recursively.
   " Do not jump, just populate quickfix tab
   " if file does not have extension, search in all file in current location
   " (warning, this can be very long)
map <F4> :execute 'vimgrep /'.expand('<cword>').'/gj **/*'.(expand("%:e")=="" ? "" : ".".expand("%:e"))  <Bar> cw<CR>

" this is really ugly and all, but I have not find something cool to search in
" multiple path with vimgrep.. so switching context mate
map <F5> :cd /home/dev/ouroboros/css/ <CR>
map <F6> :cd /home/dev/ouroboros/swint/ <CR>
map <F7> :cd /home/dev/ouroboros/cs_common/ <CR>

" shortcut // to search for visually selected text
vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR>

" shortcut to vimgrep on every file with a given extension
command -nargs=+ Vim :vimgrep // **/*.<args>


" Display line numbers on the left
set number

" Indentation settings for using 4 spaces instead of tabs.
" Do not change 'tabstop' from its default value of 8 with this setup.
set shiftwidth=4
set softtabstop=4
set expandtab
