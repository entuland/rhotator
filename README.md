# Rhotator Screwdriver (rhotator)

A different twist at Minetest screwdriving.

Developed and tested on Minetest 0.4.16 - try in other versions at your own risk :)

If you like my contributions you may consider reading http://entuland.com/en/support-entuland

WIP MOD forum thread: https://forum.minetest.net/viewtopic.php?f=9&t=20321

# Why yet another screwdriver?

The default screwdriver included in minetest_game, as well as any other screwdriver mod I have found, operate differently depending on the node's direction and rotation. This means that any given click on a node may produce different results which you cannot predict at a glance.

The Rhotator Screwdriver uses a different approach: the direction and orientation of the node make absolutely no difference.

These are the factors that affect the results of a click:

- the face you point at
- where on that face you point
- what button you click
- whether or not you hold down the sneak key

You will always be able to predict exactly the effect of the Rhotator Screwdriver.

Four consecutive clicks of the same button on the same position will always bring the node back to its original direction / orientation.

### Why is it called "Rhotator" and not "Rotator"?

In mathematics, the greek letter *Rho* is used to indicate some stuff associated to certain types of matrices. Since I'm using matrices to compute the various rotations in the game I thought about including it in the mod's name to reduce the chance of naming conflicts.

# Appearance

Here you can see the Rhotator Screwdriver along with the Testing Cube.

*The testing cube is just an addition to help practicing with this screwdriver.*

The Rhotator Screwdriver will rotate ANY node where `paramtype2 == "facedir"`

More node types will be supported in the future.

![Preview](/screenshots/preview.png)

# Usage

Pretty simple:

- a right click will rotate the face you're pointing in clockwise direction
  - the arrow in the Testing Cube shows how the face will rotate when right-clicked
  - `RT` in the tool stands for `rotate`
  - hold the sneak key down while clicking to rotate counter-clockwise

- a left click will rotate the node as if you "pushed" the closest edge you're pointing at
  - the colored edges in the Testing Cube indicate the color of the face you'll see when left-clicking near that edge
  - `PS` in the tool stands for `push`
  - hold the sneak key down while clicking to "pull" instead of "pushing"

The left-click interaction area is not limited to the edges you can see in the Testing Cube. In reality you can click anywhere in a triangle like this (highlighted here just for convenience, you won't see anything like this in the game):

![Interaction triangle](/screenshots/interaction-triangle.png)

# Non-full nodes

Nodes that don't occupy a full cube (such as slabs and stairs) can still be rotated properly, it's enough that you pay attention to the direction of the part you're pointing at - the "stomp" parts of the stairs will behave as the "top" face, the "rise" parts will behave as the "front" face. With the Rhotator Screwdriver there never really is a "top" or a "front" or whatever: the only thing that matters is the face you're pointing at.

# Crafting

Rhotator Screwdriver: a stick and a copper ingot;

![Screwdriver crafting](/screenshots/screwdriver-crafting.png)

Rhotator Testing Cube: a Rhotator Screwdriver and any wool block

![Testing cube crafting](/screenshots/testcube-crafting.png)

# Usage feedback

An HUD message will show usage feedback, in particular it will inform you about nodes that aren't currently supported.

Here are possible messages you can receive:

- Rotated pointed face clockwise (right click)
- Rotated pointed face counter-clockwise (sneak + right click)
- Pushed closest edge (left click)
- Pulled closest edge (sneak + left click)
- Cannot rotate node with paramtype2 == glasslikeliquidlevel
- Unsupported node type: modname:nodename

plus some more messages warning about protected areas or rotations performed or prevented by custom on_rotate() handlers.
