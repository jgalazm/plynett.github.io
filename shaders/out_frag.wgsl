struct FragmentOutput {
    @location(0) color: vec4<f32>,
};

struct Globals {
    colorVal_max: f32,
    colorVal_min: f32,
    colorMap_choice: i32,
    surfaceToPlot: i32,
    showBreaking: i32,
    IsOverlayMapLoaded: i32,
    scaleX: f32,
    scaleY: f32,
    offsetX: f32,
    offsetY: f32,
    dx: f32,
    dy: f32,
    WIDTH: i32,
    HEIGHT: i32,
    rotationAngle_xy: f32,
    shift_x: f32,
    shift_y: f32,
    forward: f32,
    canvas_width_ratio: f32,
    canvas_height_ratio: f32,
    delta: f32,
    CB_show: i32,
    CB_xbuffer_uv: f32,
    CB_xstart_uv: f32,
    CB_width_uv: f32,
    CB_ystart: i32,
    CB_label_height: i32,
    base_depth: f32,
    NumberOfTimeSeries: i32,
    time: f32,
    west_boundary_type: i32,
    east_boundary_type: i32,
    south_boundary_type: i32,
    north_boundary_type: i32, 
    designcomponent_Fric_Coral: f32,
    designcomponent_Fric_Oyser: f32,
    designcomponent_Fric_Mangrove: f32,
    designcomponent_Fric_Kelp: f32,
    designcomponent_Fric_Grass: f32,
    designcomponent_Fric_Scrub: f32,
    designcomponent_Fric_RubbleMound: f32,
    designcomponent_Fric_Dune: f32,
    designcomponent_Fric_Berm: f32,
    designcomponent_Fric_Seawall: f32,
};

@group(0) @binding(0) var<uniform> globals: Globals;

@group(0) @binding(1) var etaTexture: texture_2d<f32>;
@group(0) @binding(2) var bottomTexture: texture_2d<f32>;
@group(0) @binding(3) var txMeans: texture_2d<f32>;
@group(0) @binding(4) var txWaveHeight: texture_2d<f32>; 
@group(0) @binding(5) var txBaseline_WaveHeight: texture_2d<f32>; 
@group(0) @binding(6) var txBottomFriction: texture_2d<f32>; 
@group(0) @binding(7) var txNewState_Sed: texture_2d<f32>; 
@group(0) @binding(8) var erosion_Sed: texture_2d<f32>; 
@group(0) @binding(9) var txBotChange_Sed: texture_2d<f32>; 
@group(0) @binding(10) var txDesignComponents: texture_2d<f32>; 
@group(0) @binding(11) var txOverlayMap: texture_2d<f32>;
@group(0) @binding(12) var txDraw: texture_2d<f32>;
@group(0) @binding(13) var textureSampler: sampler;
@group(0) @binding(14) var txTimeSeries_Locations: texture_2d<f32>;
@group(0) @binding(15) var txBreaking: texture_2d<f32>;  
@group(0) @binding(16) var txSamplePNGs: texture_2d_array<f32>;


fn calculateChangeEta(x_global: f32, y_global: f32, dx: f32, amplitude: f32, thetap: f32) -> f32 {
    var change_eta: f32 = 0.0;
    let directions: array<f32, 7> = array<f32, 7>(-25.0, -20.0, -10.0, 0.0, 10.0, 20.0, 25.0); // Directions in degrees
    let pi: f32 = 3.141592653589793;

    // Convert directions to radians for math functions
    for (var i: i32 = 0; i < 7; i = i + 1) {
        let dirRad: f32 = (thetap + directions[i]) * pi / 180.0; // Direction in radians

        // Loop through wavelengths
        for (var j: f32 = 0.2; j <= 1.0; j = j + 0.2) {
            let wavelength: f32 = 10.*min(dx,2.0) * j;
            let k: f32 = 2.0 * pi / wavelength; // Wave number
            let w: f32 = pow(9.81 * k, 0.5);

            // Calculate wave vector components
            let kx: f32 = cos(dirRad) * k;
            let ky: f32 = sin(dirRad) * k;

            // Calculate position in direction of wave vector
            let x: f32 = x_global * cos(dirRad) + y_global * sin(dirRad);

            // Add sine wave contribution to change_eta
            change_eta = change_eta + amplitude * sin(k * x + w * globals.time);
        }
    }

    return change_eta;
}



@fragment
fn fs_main(@location(1) uv: vec2<f32>) -> FragmentOutput {
    var out: FragmentOutput;
    
    let maxWave = globals.colorVal_max;
    let minWave = globals.colorVal_min;
    
    let bottom = textureSample(bottomTexture, textureSampler, uv).b;
    var waves = textureSample(etaTexture, textureSampler, uv).r;  // free surface elevation
    var color_rgb: vec3<f32>;


    if (bottom + globals.delta >= waves) {
        // dry 

        // r = 0, g=bathymetry, b=flag is 1 if dry
        color_rgb = vec3<f32>(0.0, bottom / globals.base_depth, 1.0);
    } else {
        // wet
        var wavePosition = f32((waves - minWave) / (maxWave - minWave));

        // r = wave, g=bathymetry, b = flag is 0 if wet
        let color_wave = vec3<f32>(wavePosition, bottom, 0.0);
        color_rgb = color_wave;

    }

    out.color = vec4<f32>(color_rgb, 1.0); // Normal shader output
    
    return out;
}
