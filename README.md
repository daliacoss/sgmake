sgmake
======

sgmake is a script that allows you to run the sega genesis development kit (sgdk) compiler with custom metadata. if you were wondering how to replace the "SAMPLE PROGRAM" text that appears when playing your games in an emulator, this is one solution.

the compiled executable can be found at http://cosstropolis.com/toys/sgmake.zip - if you would prefer to compile from source, see below.

building from source
--------------------
1. dependencies: l-bia (http://files.luaforge.net/releases/l-bia/l-bia-0.2), sgdk (https://code.google.com/p/sgdk/)
2. `l-bia.exe sgmake.lua`
3. copy sgmake.exe to the root directory of a new sgdk project, or to a folder that your path variable points to (i prefer the latter option)

usage
-----
simply run sgmake from your project's root directory to compile the project.

sgmake will search for sgmake.ini in the project directory; this is where you set your metadata. if the ini file does not exist, sgmake will either create it for you or use default metadata values.

options
-------
-o myname.bin    : set output file name to name.bin  
-i myconfig.ini  : use myconfig.ini instead of sgmake.ini  
--no-ini         : do not use or create an ini file (overrides -i)  
--no-input       : do not ask user before creating (or ignoring) an ini file  
