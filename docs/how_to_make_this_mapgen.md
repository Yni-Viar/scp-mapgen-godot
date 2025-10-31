# How to make this map generator
## Creating environment

At first, you'll need 2D AStar pathfinding.
There is built-in AStar in Godot, but in other engines, you'll need third-party solutions.

## Creating basic map generator

How the map generator works:
1. room at the center of zone always exist.
2. while generator runs out of room amount (variable set by developer):
    1. Generator creates room at random point.
    2. Generator connects it with central room by AStar pathfinding and fills rooms.

![Example image](./imgs/map_generator_tutorial/generic_algorithm.gif)

## Adding support for large rooms.

1. Define large rooms in your resource file.
2. For endrooms, we'll need a check in initial generation algorithm.
3. For other type of rooms, we'll check amount of space.

![Example image with endroom](./imgs/map_generator_tutorial/algorithm_large_rooms.gif)