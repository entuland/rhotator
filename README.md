# Rhotator Screwdriver (rhotator)

A different twist at Minetest screwdriving.

Developed and tested on Minetest 0.4.16 - try in other versions at your own risk :)

If you like my contributions you may consider reading http://entuland.com/en/support-entuland

WIP MOD forum thread: https://forum.minetest.net/viewtopic.php?f=9&t=20321

A silly, incomplete and unscripted video presentation of this mod: https://youtu.be/ESTJ9FYGHh4

# Dependencies

A thin wrapper around a very useful library to deal with Matrices:

[matrix] https://github.com/entuland/lua-matrix

# Main features

- for `facedir` and `colorfacedir` nodes:
  - rotate any  node in a predictable manner regardless its current rotation
  - **rotation memory**: optionally, place any new node with the same rotation as the last rotated node (see [Chat commands](#chat-commands) section)

- for `wallmounted` and `colorwallmounted` nodes:
  - cycle through valid rotations in the same way as the built-in screwdriver would

# Why yet another screwdriver?

The default screwdriver included in minetest_game, as well as any other screwdriver mod I have found, operate differently depending on the node's direction and rotation. This means that any given click on a node may produce different results which you cannot predict at a glance, unless you're perfectly aware of where the node's main axis is pointing to.

The Rhotator Screwdriver uses a different approach: the direction and orientation of the node make absolutely no difference.

These are the factors that affect the results of a click:

- the face you point at
- where on that face you point
- what button you click
- whether or not you hold down the sneak key

You will always be able to predict exactly the effect of the Rhotator Screwdriver.

Four consecutive clicks of the same button on the same position will always bring the node back to its original direction / orientation - or even less clicks, if you use the sneak key to invert the rotation direction.

### Why is it called "Rhotator" and not "Rotator"?

In mathematics the greek letter *Rho* is used to indicate some stuff associated to certain types of matrices. Since I'm using matrices to compute the various rotations in the game I thought about including it in the mod's name to reduce the chance of naming conflicts.

# Appearance

Here you can see the Rhotator Screwdriver along with the Testing Cube.

*The testing cube is just an addition to help practicing with this screwdriver.*

The Rhotator Screwdriver will rotate ANY node where `paramtype2` has any of these values: `facedir, colorfacedir, wallmounted, colorwallmounted`.

The latter two types are handled exactly as the built-in screwdriver of `minetest_game` handles them.

![Preview](/screenshots/preview.png)

# Usage

This is the behavior of the default `rhotator:screwdriver` tool:

- a right click will rotate the face you're pointing in clockwise direction
  - the arrow in the Testing Cube shows how the face will rotate when right-clicked
  - `RT` in the tool stands for `rotate`
  - hold the sneak key down while clicking to rotate counter-clockwise

- a left click will rotate the node as if you "pushed" the closest edge you're pointing at
  - the colored edges in the Testing Cube indicate the color of the face you'll see when left-clicking near that edge
  - `PS` in the tool stands for `push`
  - hold the sneak key down while clicking to "pull" instead of "pushing"

(an alternative `rhotator:screwdriver_alt` tool is available with a sligthly different recipe, the buttons swapped and a corresponding texture with `RT` and `PS` swapped as well)

The `push` interaction area is not limited to the edges you can see in the Testing Cube. In reality you can click anywhere in a triangle like this (highlighted here just for convenience, you won't see anything like this in the game):

![Interaction triangle](/screenshots/interaction-triangle.png)

# Non-full nodes

Nodes that don't occupy a full cube (such as slabs and stairs) can still be rotated properly, it's enough that you pay attention to the direction of the part you're pointing at - the "stomp" parts of the stairs, for example, will behave as the "top" face, the "rise" parts will behave as the "front" face. With the Rhotator Screwdriver there never really is a "top" or a "front" or whatever: the only thing that matters is the face you're pointing at.

# Crafting

Rhotator Screwdriver: a stick and a copper ingot;

![Rhotator Screwdriver crafting](/screenshots/rhotator-recipe.png)

Rhotator Screwdriver Alt: two sticks and a copper ingot;

![Rhotator Screwdriver Alt crafting](/screenshots/rhotator-alt-recipe.png)

Rhotator Testing Cube: a Rhotator Screwdriver and any wool block

![Rhotator Testing Cube crafting](/screenshots/rhotator-cube-recipe.png)

Recipes can be customized by editing the `custom.recipes.lua` file that gets created in the mods' root folder upon first run.

# Chat commands

- `rhotator` shows available commands
- `rhotator memory` shows current placement memory flag (on or off)
- `rhotator memory on` enable placement memory
- `rhotator memory off` disable placement memory

Rotation memory starts off by default, it gets stored and recalled for each player between different sessions and between server restarts.

# Usage feedback

An HUD message will show usage feedback, in particular it will inform about nodes that aren't currently supported.

Here are possible messages you can receive:

- Rotated pointed face clockwise
- Rotated pointed face counter-clockwise
- Pushed closest edge
- Pulled closest edge
- Cannot rotate node with paramtype2 == glasslikeliquidlevel
- Unsupported node type: modname:nodename
- Wallmounted node rotated with default screwdriver behavior

plus some more messages warning about protected areas or rotations performed or prevented by custom on_rotate() handlers.
