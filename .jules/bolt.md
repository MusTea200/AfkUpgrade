## 2024-10-11 - Batching UI Updates During AFK Catch-up
**Learning:** Signal emissions (e.g., UI updates via `inventory_changed`) and console `print()` statements executed during O(N) offline progress calculation loops will severely bottleneck the main thread and freeze the game, specially when catching up on hours of AFK time.
**Action:** When implementing offline progression or heavy calculation loops, always pass a `silent=true` flag to underlying state managers to batch modifications, and execute a single manual UI update signal after the loop completes.
