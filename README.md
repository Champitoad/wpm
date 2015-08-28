# wpm

**`wpm`** is a command-line wallpaper manager written in Bash, designed primarily for the GNOME desktop environment. However, the commands used to get/set the current wallpaper can be modified in *.wpm/cmd.sh*.

## Usage

**`wpm`** can be used in 4 different modes, each one having his own options, in an Archlinux's `pacman` flavoured command syntax.

Independantly of those modes, **`wpm`** works with a list of one or more wallpapers, and runs either in normal or daemon mode, possibly with the **`-R`** option to randomize the selection.

#### Normal mode (no specific option)

Simply set the current wallpaper to the first wallpaper of the list.

#### Daemon mode (**-D** option)

The program runs indefinitely, looping over the list and changing the current wallpaper an every fixed amount of time given in milliseconds in argument (default set to 6 minutes). Will stop if another instance of the program in daemon mode has started.

### Synopsis

```
wpm    -Mf         "<wallpaper>..."     [-R]    [-D [<delay>]]  
wpm    -Md         "<directory>..."     [-R]    [-D [<delay>]]  
wpm    -C[s|r]     [<wallpaper_list>]   [-R]    [-D [<delay>]]  
wpm    -L[p|n|s    [<wallpaper_list>]]  [-R]    [-D [<delay>]]  
wpm    -I[f|d]
```

### Manual mode (-M option)

Create the list of wallpapers with the paths of the quoted list given in argument.

**`-f`** : Loads one or more image files (list order equal to argument order)  
**`-d`** : Loads one or more directories filled exclusively with image files (list order equal to argument order, with alphabetical order per directory)  

### Custom mode (-C option)

Without options, loads the list of wallpapers contained within the file given in argument (default set to *.wpm/custom.wpl*).
The list must contain one absolute path to a wallpaper per line.

**`-s`** : Appends the current wallpaper to the end of the custom list  
**`-r`** : Removes the current wallpaper from the custom list  

### Last mode (-L option)

Without options, loads the list used by the last instance of **`wpm`** (stored in *.wpm/last.wpl*).

**`-p`** : Loads the **n**th wallpaper preceding the current (if existing) in the list, with **n** given in argument (default set to 1)
**`-n`** : Loads the **n**th wallpaper following the current (if existing) in the list, with **n** given in argument (default set to 1)
**`-s`** : Save the list in the file passed in argument (default set to *.wpm/custom.wpl*)

### Info mode (-I option)

Gives various wallpapers related informations.

**`-f`** : Prints current wallpaper path  
**`-d`** : Prints current wallpaper's directory path  

### Examples

Load a random wallpaper within ~/Images/Wallpapers/ :  
`wpm -Md ~/Images/Wallpapers/ -R`

Load the custom wallpaper list and change wallpaper every 10 minutes :  
`wpm -CD 10000`

Replace the default custom list by the last list :  
`wpm -Ls`
