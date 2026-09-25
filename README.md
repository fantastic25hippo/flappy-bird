# Flappy Bird in Bend

A Flappy Bird clone written in pure [Bend](https://bend-lang.com) (not the official Flappy Bird).

Built using Bend's 2D windowed application framework (`App.run`), custom software quadtree rasterization (`Image` / `Pix` / `Qua`), dynamic difficulty staging, and procedural cloud parallax.

## Prerequisites

- **Bend Compiler:** Bend 2.0+ (`bend`)
- **C Compiler:** Clang (`clang`) and X11 development headers (`libx11-dev`) for native GUI windowing

## Build

From this directory, compile the native ELF binary using Bend:

```bash
bend main.bend -o flappy
```

## Run

```bash
./flappy
```

The game runs in a 512x512 window.

## Controls

- **Space:** Start the game from Ready screen; flap wings upward during play
- **R:** Restart the game when dead (Game Over screen)
- **Esc:** Quit the game (or close the window)
