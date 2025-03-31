# scp-mapgen
## About
 SCP-CB-like facility map generator
 [How to use?](/docs/how_to_use.md)


## License?
- Code - [BSD-2 license with patent exception](/LICENSE.CODE).
  - If your project is licensed under CC-BY-SA 3.0, CC-BY-SA 4.0 or GPL 3 (e.g. *SCP - Containment Breach* remake), the Author grants You permission to relicense the code under mentioned licenses.
- Assets - [CC-BY 4.0](/LICENSE.ASSETS), since we got independent from SCP content.

## Changelog
### v.7.2.0 (2024.03.31)
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