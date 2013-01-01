# Pix.

A game in DCPU-16 assembly inspired by Canabalt.

## Authors
Alyssa Bawgus, Jazmin Gonzalez-Rivero, Julian Ceipek, Riley Butler

----------------------

## Try It!
http://0x10co.de/ly99i

![Main Screen](https://raw.github.com/ryla/pix/master/screenshots/PixMain.png "Title Screen")
![Game Screen](https://raw.github.com/ryla/pix/master/screenshots/Pix.png "Game Screen")


## Introduction

Pix is a 16-bit computer game written in DCPU-16 assembly. The DCPU-16 assembly specification was developed by @notch (the creator of Minecraft) for his upcoming game, 0x10c. Because @notch's game has yet to be released and the specification is in flux, we decided to develop for the emulator available at [0x10co.de](http://0x10co.de).


## Gameplay

Due to the limitations of the processor and the time we had to develop the game, we decided to build a game with a very simple game mechanic. For inspiration, we turned to Canabalt, a one-button game in which the objective is to jump over gaps and obstacles and to survive as long as possible (the game is endless).

In Pix, you play a thief running on rooftops. In the spirit of Canabalt, the world is procedurally generated and the objective is to run as long as possible without falling to your doom.


## Limitations

The DCPU-16 specification does not currently provide audio support. However, it includes a simple monitor, the LEM1802, as a virtual hardware device. The monitor does not implement a sprite system and is designed to display text. To this end, each 4x8 pixel block can have no more than 2 colors (a foreground color and a background character). The screen is made up of 32x12 blocks (with up to 128 unique blocks) and can have up to 16 colors on the entire screen.

Consequently, Pix's gameplay only consists of jumping over gaps rather than obstacles, our game doesn't play music, and there are no background images aside from a static backdrop.

## Tools

Because of the limitations of the DCPU-16 specification, creating graphics for the emulator was very challenging. Consequently, we created a Python toolkit (pixarter.py) that allowed us to translate traditional image files into unique image tilesets and look-up tables that could be pasted into assembly directly. Writing these tools reduced the amount of time we needed to spend on the implementation of smooth animations by several orders of magnitude.


## Implementation

Pix uses the following virtual hardware devices that the emulator provides:
+ monitor
+ clock
+ keyboard

When the program starts, it enumerates all hardware devices on the system and identifies the addresses of the devices we need to use. 

The main game loop works using hardware interrupts triggered once every 1/60th of a second. This loop queries the state of the keyboard every frame to determine if the spacebar (the jump button) is depressed. Based on this state, the position of the player-controlled character, and the position of the buildings, the code writes graphics to a portion of the RAM reserved for memory.

A splash screen is displayed that activates the gameplay via a keyboard interrupt. After that, the buildings are generated with a pseudo-random number generator tuned to return playable distances. The thief avatar cycles through 3 frames of running animation and when the main loop receives a keyboard interrupt, the animation switches to the jumping animation subroutine. This cycles through 6 frames in a specific order and changes which tiles the thief is displayed on based on the frame number; i.e. at the peak of the jump (frame 6), the thief is displayed 2 blocks higher than in the running position.

Graphics are displayed by setting previously defined DATs that represent 8x4 pixel images that can be assembled into coherent pixel art. They are then displayed with the SET command that uses an encoded value representing the location where the DAT will be displayed and a 4 bit register which contains the information of which predefined tile is called with what foreground and background color. We used up all 128 available image tiles.