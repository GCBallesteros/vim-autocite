# vim-autocite
## Introduction
After deciding to move from LaTex to to [Asciidoc](https://github.com/asciidoc/asciidoc)
for my document writing I found myself without the quasimagical auto completion
of citations from [vim-latex](https://github.com/lervag/vim-latex).

Autocite extracts that functionality from vim-latex and makes
it easily accesible for other file extensions.

Currently it only works for .txt documents with the [Asciidoc-bib](https://github.com/petercrlane/asciidoc-bib)
convention for citations.

## Pathogen Installation
    cd ~/.vim/bundle
    git clone git://github.com/gcballesteros/vim-autocite

## Usage
Bibliography (*.bib) files are searched for by default in the
 directory where the document being edited is stored. Bibliography files can also be included by adding to the
document commented lines such as:
```
// bibtexfile:/full/path/to/my/bibliography/my_bib.bib
```

Once vim-autocite is capable of finding your bibliography
files you only have to start writing your citation with
the [Asciidoc-bib](https://github.com/petercrlane/asciidoc-bib)
conventions:
```
[cite:]
[citenp:]
```

after the colon write some clue and \<Control-X\>\<Control-O\> to
trigger the autocompletion menu. A clue may be the last name of
an author, part of the title or bibtex label for the article.

## Configuration
vim-autocite defines two global variables:
- Enable/Disable the search of bibfiles in the directory of the edited file
     (default: 1)

     ```
     let g:autocite_search_in_dir=1
     ```
- Enable/Disable the search of bibfiles specified inside the document
     with ```bibtexfile:``` (default: 1)

     ```
     let g:autocite_search_in_doc=1
     ```


## Feature Request
If you would like vim-autocite to work on other filetypes or citation labels ask for it.

## Acknowledgements
The core of the script has been scavenged from [vim-latex](https://github.com/lervag/vim-latex) so vim-autocite
wouldn't be possible without Karl Yngve Lervag.

Any bugs have been introduced by me, please let me know if it doesn't work as expected.

## Dependencies
Vim-autocite requires that bibtex is installed.

