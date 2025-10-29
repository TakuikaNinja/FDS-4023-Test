# FDS $4023 Test

This program tests/displays the FDS' behaviour of read-only registers when toggling bits in $4023.

NESdev forum post: https://forums.nesdev.org/viewtopic.php?t=26313

Hardware Recording from a Twin Famicom: https://youtu.be/rbvNSA2-kNI

## Usage

Simply load the program into an FDS, whether it be original hardware or on an emulator. 
$4023 = `%10000011` on startup/reset, bit 7 cannot be changed. (IYKYK)

### Interface

- $4023 state at top of screen.
- Hex dump of $4020-$409F below. 
  - This is updated in realtime, so actions such as ejecting/inserting the disk should be reflected here.

### Controls

- B toggles bit 1 of $4023 (sound registers).
- A toggles bit 0 of $4023 (timer IRQ & disk I/O registers).

### WARNING

Leaving bit 0 = 0 for extended periods on original hardware has a risk of corrupting PRG-RAM due to the DRAM refresh watchdog being disabled while in this state (research is ongoing). Although measures have been put in place to minimise the likelihood of corruption, it may be necessary to do a full power-cycle/reload should the program ever halt or otherwise fail to reset properly. 

## Building

The CC65 toolchain is required to build the program: https://cc65.github.io/
A simple `make` should then work.

## Acknowledgements

- `Jroatch-chr-sheet.chr` was converted from the following placeholder CHR sheet: https://www.nesdev.org/wiki/File:Jroatch-chr-sheet.chr.png
  - It contains tiles from Generitiles by Drag, Cavewoman by Sik, and Chase by shiru.
- `AccuracyCoin-Hex.chr` was taken from 100th_Coin's [AccuracyCoin](https://github.com/100thCoin/AccuracyCoin).
- Hardware testing was done using a Sharp Twin Famicom + [FDSKey](https://github.com/ClusterM/fdskey).
- The NESdev Wiki, Forums, and Discord have been a massive help. Kudos to everyone keeping this console generation alive!

