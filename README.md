# DOS-8086-Space-Invaders
A classic game written in 8086 Assembly, built as a final project for the Gvahim Assembly class.

Based on the original Space Invaders game.

# Compile and run
Use a DOS emulator (like DOSBox, EMU8086) to compile and play the game.

Navigate to the game folder, then use TASM (Turbo Assembler) + TLink to compile the game:

`tasm /zi Space.asm`

`tlink /v Space.obj`

Then run it:

`Space.exe`

You can also run the game with a debug flag to show some debug prints:

`Space.exe -dbg`
