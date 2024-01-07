# F256 two to the power of eleven

This is an implementation of a well known puzzle game in which the player has to create
a tile with the value two to the power of eleven or 2048 on a playing field of four by
four cells. Use the cursor keys, the joystick in port 1 or an SNES pad in the first socket 
to move the tiles in the cells in one direction up, down, left or right. When two equal 
tiles "collide" during that movement they merge to a tile with a value twice of the original 
tiles. The game is won if a tile with the value two to the power of eleven is created in the 
playfield.

Press F1 during the game to return to the start screen. The release contains the file `f256_2048.bin`
which should be loaded via `bload` to address `$2500` from where it can be started by `call $2500`.

# Building the software

You will need `64tass` to assemble the program from source. Use `make` to build the software and
`make upload` to assemble the software and upload it to your machine using `FnxMgr`. You may have
to change the port name from `/dev/ttyUSB0` to the value that fits your machine.
 
# Ideas which may be implemented

- Undo feature
- Saving a high score list
- Implement a screen which describes the game
- Use sprites or tiles to draw the playing field