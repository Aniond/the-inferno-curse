# 3D HD Engine Foundation

The current foundation target is a 3D HD / HD-2D style Godot 4.6 project:

- Forward Plus renderer with D3D12 on Windows.
- 1280x720 internal viewport with kept aspect ratio.
- Orthographic `Camera3D` aimed at a 3D tavern scene.
- `CharacterBody3D` player movement on the XZ plane with billboarded sprite animation.
- Dark medieval palette using material emission, warm torch lights, and a `WorldEnvironment`.
- Jolt Physics for 3D collision.

Keep this phase focused on engine setup and traversal feel. Avoid expanding combat,
quests, inventory, or authored story content until the 3D foundation is stable and
committed.
