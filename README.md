
pcgen-rules
===========

pcgen-rules is an attempt to extract the rules and data from [PCGen](http://pcgen.sourceforge.net/01_overview.php) and make them more accessible to other programs.

You will need the PCGen data files in a separate directory. Edit the `Makefile` accordingly if you use a directory other than `data/`.

Currently the code just parses .pcc and .lst files; this is very much a work in progress.

To pretty-format the output:

```
cabal install pretty-show
```

This module is **not** listed as a dependency. Rather, you run it as a shell command:

```
./pcgen-rules test1.pcc | ppsh
```