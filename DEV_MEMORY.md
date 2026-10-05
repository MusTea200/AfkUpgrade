# DEV_MEMORY - Project Memory & Architecture

## Architecture Summary
- **Engine**: Godot 4 (GDScript)
- **Theme**: 2D, modern paper aesthetic, gathering/incremental AFK game.
- **Core Loop**: Tasks have cycle times, required inputs, and output yields. Offline progress is capped at 24 hours.
- **Security**: Progress relies on `TimeManager` syncing UTC time via HTTPS (worldtimeapi.org).
- **CI/CD**: Android APK builds are automated via GitHub Actions (`build-apk.yml`). No web wrappers (Capacitor) are used; we rely on Godot native exports.

## Defensive Programming (Runtime Fixes & Prevention)
- **Array Typing (`available_tasks`)**: Fixed strict typing issues. In Godot 4, modifying arrays or assigning them must strictly match the `Array[Type]` format or use `append_array`. Replaced direct assignment with typed assignment or iteration to prevent `Invalid assignment of property or key` errors.
- **UI Null Reference Safety**: Added strict `is_instance_valid(node)` and `node != null` checks around all `Label.text` assignments and UI updates in `Main.gd`. Ensure nodes are fully initialized in the tree before assigning values, preventing crashes like `Invalid assignment of property or key 'text' with value of type 'String' on a base object of type 'null instance'`.
- **Node Lifecycle Constraints**: Enforced defensive coding by verifying nodes exist before modifying their visual properties, specially after scene swaps or hot-reloads.

## Future Math & Progression Plans
- **Gathering Scaling**: Implement a base multiplier curve (e.g., $Yield = Base \times Level^{1.2}$) for task progression.
- **Dynamic Task Limits**: Create a leveling system that increases max offline AFK time from 2 hours up to 24 hours as the player upgrades.
- **Resource Sinks**: Introduce a global "Prestige" or "Evolution" mechanism to dump massive amounts of resources for a permanent multiplier (game loop restart with meta-progression).

## Performance & Innovations
- **Visual Feedback**: Add juiciness (Tween animations, floating text for gathered resources) upon task cycle completion.
- **Efficient Pooling**: Switch from instantiating generic labels in the inventory UI to an object pool or `ItemList` for better memory usage during long sessions.
- **Anti-Cheat Layer**: Store a rolling hash of the save file to detect manual tampering of the `user://save_game.json` file.
