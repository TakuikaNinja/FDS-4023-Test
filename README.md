# FDS $4023 Test

This program tests/displays the FDS' behaviour of read-only registers when toggling bits in $4023.

NESdev forum post: soon

Hardware Recording from a Twin Famicom: soon

## Usage

Simply load the program into an FDS, whether it be original hardware or on an emulator. 
$4023 = `%10000011` on startup/reset, bit 7 cannot be changed. (IYKYK)

Interface:
- $4023 state at top of screen.
- Hex dump of $4020-$409F below.

Controls:
- B toggles bit 1 of $4023 (sound registers).
- A toggles bit 0 of $4023 (timer IRQ & disk I/O registers).

## Building

The CC65 toolchain is required to build the program: https://cc65.github.io/
A simple `make` should then work.

## Acknowledgements

- `Jroatch-chr-sheet.chr` was converted from the following placeholder CHR sheet: https://www.nesdev.org/wiki/File:Jroatch-chr-sheet.chr.png
  - It contains tiles from Generitiles by Drag, Cavewoman by Sik, and Chase by shiru.
- `AccuracyCoin-Hex.chr` was taken from 100th_Coin's [AccuracyCoin](https://github.com/100thCoin/AccuracyCoin).
- Hardware testing was done using a Sharp Twin Famicom + [FDSKey](https://github.com/ClusterM/fdskey).
- The NESdev Wiki, Forums, and Discord have been a massive help. Kudos to everyone keeping this console generation alive!

