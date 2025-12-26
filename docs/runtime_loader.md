# Runtime loader
## File structure
For runtime load, you need a ZIP file with folders in this format
```
|- room_pack.zip
|  |- Room1
|  |- Room1Single
|  |- Room1SingleLarge
|  |- Room2
|  |- Room2Single
|  |- Room2SingleLarge
|  |- Room2c
|  |- Room2cSingle
|  |- Room2cSingleLarge
|  |- Room3
|  |- Room3Single
|  |- Room3SingleLarge
|  |- Room4
|  |- Room4Single
```
Put your GLTF/GLB files into folders (Room1, Room2, Room2c, Room3, Room4 should have at least 1 gltf/glb file!)

## Loading files
Click `Load room pack`, select your room pack zip archive with structure, mentioned above, load for a while, and you are ready to preview your room generation.

## Limitations

As of 10.1, there is no support for:
- Checkpoints and zones more than one.
- Doors and double rooms are pre-defined.