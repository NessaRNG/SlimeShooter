shader_type canvas_item;

// Grass texture (the atlas PNG)
uniform sampler2D grass_tex : filter_nearest;

// Camera world position (updated every frame from GDScript)
uniform vec2 cam_pos = vec2(0.0, 0.0);

// Viewport size in pixels
uniform vec2 screen_size = vec2(1920.0, 1080.0);

// World units per tile (TILE_PX * TILE_SCALE)
uniform float tile_world_size = 48.0;

// The UV region for the chosen grass tile within the atlas
uniform vec2 tile_uv_origin = vec2(0.0, 0.0);   // top-left UV
uniform vec2 tile_uv_size   = vec2(0.25, 0.25); // size in UV space

void fragment() {
	// UV goes 0..1 over the full-screen quad
	// Convert to world position based on camera center
	vec2 world_pos = cam_pos + (UV - vec2(0.5)) * screen_size;

	// Fractional tile coordinate (0..1 within one tile), perfectly continuous
	vec2 tile_frac = fract(world_pos / tile_world_size);

	// Sample the selected grass tile region
	vec2 tex_uv = tile_uv_origin + tile_frac * tile_uv_size;
	COLOR = texture(grass_tex, tex_uv);
}
