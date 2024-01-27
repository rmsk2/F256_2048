# F256 two to the power of eleven

This is an implementation of a well known puzzle game in which the player has
to create a tile with the value two to the power of eleven or 2048 on a 
playing field of four by four cells. Use the cursor keys, the joystick in 
port 1 or an SNES pad in the first socket to move the tiles in the cells in
one of the directions up, down, left or right. When two equal tiles "collide" during
that movement they merge to a tile with a value twice that of the original tiles. 
The game is won if a tile with the value two to the power of eleven is 
created in the playfield. Press F1 during the game to return to the start screen. 

The release contains the file `f256_2048.pgz` which can be started by `/- f256_2048.pgz` 
from the BASIC prompt if the file is stored on drive 0, i.e. the SD card in the F256's 
card slot.

# Building the software

You will need `64tass`, a python interpreter and GNU make to assemble the program from source. 
Use `make` to build the software and `make upload` to assemble the software and upload it to your 
machine using `FnxMgr`. `FnxMgr` should start the program after uploading it, but if that does not
work press the reset button. After the reset the program starts. You may have to change the port name 
from `/dev/ttyUSB0` to the value that fits your machine. The target `pgz` can be used to build a 
PGZ file.
 
# Ideas which may be implemented

- We will see