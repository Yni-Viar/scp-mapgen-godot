# SCP Facility-like map generator
## About

SCP-like facility map generator
[How to use?](./docs/how_to_use.md)

[Room pack tutorial](./docs/runtime_loader.md)

[SCP: Containment Procedures uses this map generator](https://github.com/Yni-Viar/scp-containmentprocedures)

## Other editions

[CLI version](https://github.com/Yni-Viar/scp-mapgen-cli)

[Unreal Engine Version](https://github.com/Yni-Viar/grid-mapgen-ue)

Unity (Coming soon...)


## License?
- Code - [MIT License](/LICENSE.MIT)
  - If your project is licensed under CC-BY-SA 3.0, CC-BY-SA 4.0 or GPL 3 (e.g. *SCP - Containment Breach* remake), the Author grants You permission to relicense the code under mentioned licenses.
- Assets - [CC-BY 4.0](/LICENSE.ASSETS), since we got independent from SCP content.

## What works:
- [x] Random generation (NOT Layout based)
- [x] Door support (currently only in 3D version)
- [x] Modular.
- [x] Randomized door + assign specific door to a room
- [x] Checkpoint support *Note, that these checkpoints work differently from Containment Breach ones*
- [x] Many zone support (both in x and y directions) (currently, there is a limit of 512 rooms in a single generator node, you can increase it in code, but this may affect the performance (especcialy in 3D))
- [x] Variable room spawn, based on room chance / guaranteed spawn.
- [x] Seamless double rooms *(All non-endroom types supported since v10)*

*[See MapGen comparison for more information](./docs/scp-mapgen-comparison.md)*

## Changelog
### v.10.1.0 (2025.12.26)
- No generic map generation changes (except now room scene root can be every node3d), but...
- Added room previewer, which can load room packs.
### v.10.0.0 (2025.12.25)
- Double room overhaul - Double room creation became easier + supported also Room2C and Room3
### v.9.1.0 (2025.09.29)
- Fixed some rooms could not spawn due to unduplicated resources.
- Fixed double rooms spawn.
### v.9.0.0 (2025.07.31)
- Added support for double rooms (currently only for hallways and X-shaped crossrooms, and only as single rooms)
- Remove outdated 2D frontend (you can create your own 2D frontend, based on 8.x code)
### v.8.1.0 (2025.05.11)
- Single rooms (but not large) are also affected by room chance. *(3D version only!!!)*
- Improved MapGen 3D frontend code.
### v.8.0.0 (2025.04.24)
- Finally added checkpoints!
- Room can have a specific door set (as seen in *SCP: Secret Lab 14.0 and newer*)
- Reworked better zone generator again (it was reverted to brevious behavior, but without hanging (tried multiple seeds))
- Separated MapGeneration core from 2D and 3D version, making it more portable. Now 2D and 3D frontend are representing only room spawn, while core backend does all.
### v.7.3.0 (2025.04.23)
- Fixed a generation error when generating many-zone facility (especially, when zone amount was >= 4).
### v.7.2.0 (2025.03.31)
- Add 2D version
- Add editor icons
- Fix bug, where MapGen could not connect on X axis more than once (which lead to disconnected generation)
### v.7.1.0 (2024.12.18)
- Fixed too straigh map generation by created toggleable *Better map generation* parameter. Now the map generation looks like a SCP: Containment Breach one
- Added documentation
- Replaced SCP: Site Online rooms with cubes (for better visibility of generation)
### v.7.0.0 (2024.11.29)
- Zones can be horizontal, not just vertical.
- Added support for room resources in map gen (e.g. for map gen HUD)
### v.6.2.0 (2024.11.06)
- More straight corridors! - changed the heuristic, how map is generated.
### v.6.1.0 (2024.11.06)
- Added more types of large rooms (previously only endrooms were supported)
### v.6.0.0 (2024.11.05)
- Added SCP-CB like large room support (no more using a hack)
### v.5.1.0 (2024.11.03)
- Add support for custom doors, as seen in *SCP: Secret Lab 14.0*
- Removed SCP-CB rooms (Research, or Entrance zone)