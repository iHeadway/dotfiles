// CRT emulation

// Define map for PS input
struct PSInput {
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
};

// The terminal graphics as a texture
Texture2D iChannel0 : register(t0);
SamplerState sampler0 : register(s0);

// Terminal settings such as the resolution of the texture
cbuffer PixelShaderSettings : register(b0) {
    float iTime;        // Time (dynamic)
    float2 iResolution; // Screen resolution (dynamic)
};

// Settings
#define CURVE 13.0, 11.0
#define COLOR_FRINGING_SPREAD 1.0
#define GHOSTING_SPREAD 0.75
#define GHOSTING_STRENGTH 1.0
#define DARKEN_MIX 0.4
#define VIGNETTE_SPREAD 0.3
#define VIGNETTE_BRIGHTNESS 6.4
#define TINT 0.93, 1.00, 0.96
#define SCAN_LINES_STRENGTH 0.15
#define SCAN_LINES_VARIANCE 0.35
#define SCAN_LINES_PERIOD 4.0
#define APERTURE_GRILLE_STRENGTH 0.2
#define APERTURE_GRILLE_PERIOD 2.0
#define FLICKER_STRENGTH 0.05
#define FLICKER_FREQUENCY 15.0
#define NOISE_CONTENT_STRENGTH 0.15
#define NOISE_UNIFORM_STRENGTH 0.03
#define BLOOM_SPREAD 8.0
#define BLOOM_STRENGTH 0.04
#define FADE_FACTOR 0.55

// Constants
#define PI 3.1415926535897932384626433832795

// Function to apply curve effect
float2 transformCurve(float2 uv) {
    uv = (uv - 0.5) * 2.0;
    uv.xy *= 1.0 + pow((abs(float2(uv.y, uv.x)) / float2(CURVE)), float2(2.0));
    uv = (uv / 2.0) + 0.5;
    return uv;
}

// Main shader function
float4 main(PSInput pin) : SV_TARGET {
    // Get texture coordinates
    float2 uv = pin.uv;

    // Apply curve effect
    uv = transformCurve(uv);

    // Sample base color
    float4 fragColor;
    fragColor.r = iChannel0.Sample(sampler0, float2(uv.x + 0.0003 * COLOR_FRINGING_SPREAD, uv.y + 0.0003 * COLOR_FRINGING_SPREAD)).x;
    fragColor.g = iChannel0.Sample(sampler0, float2(uv.x + 0.0000 * COLOR_FRINGING_SPREAD, uv.y - 0.0006 * COLOR_FRINGING_SPREAD)).y;
    fragColor.b = iChannel0.Sample(sampler0, float2(uv.x - 0.0006 * COLOR_FRINGING_SPREAD, uv.y + 0.0000 * COLOR_FRINGING_SPREAD)).z;
    fragColor.a = iChannel0.Sample(sampler0, uv).a;

    // Add ghosting effect
    fragColor.r += 0.04 * GHOSTING_STRENGTH * iChannel0.Sample(sampler0, GHOSTING_SPREAD * float2(+0.025, -0.027) + uv.xy).x;
    fragColor.g += 0.02 * GHOSTING_STRENGTH * iChannel0.Sample(sampler0, GHOSTING_SPREAD * float2(-0.022, -0.020) + uv.xy).y;
    fragColor.b += 0.04 * GHOSTING_STRENGTH * iChannel0.Sample(sampler0, GHOSTING_SPREAD * float2(-0.020, -0.018) + uv.xy).z;

    // Darken colors
    fragColor.rgb = lerp(fragColor.rgb, fragColor.rgb * fragColor.rgb, DARKEN_MIX);

    // Vignette effect
    fragColor.rgb *= VIGNETTE_BRIGHTNESS * pow(uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), VIGNETTE_SPREAD);

    // Tint colors
    fragColor.rgb *= float3(TINT);

    // Scan lines effect
    fragColor.rgb *= lerp(
        1.0,
        SCAN_LINES_VARIANCE / 2.0 * (1.0 + sin(2 * PI * uv.y * iResolution.y / SCAN_LINES_PERIOD)),
        SCAN_LINES_STRENGTH
    );

    // Aperture grille effect
    int aperture_grille_step = int(8 * fmod(pin.pos.x, APERTURE_GRILLE_PERIOD) / APERTURE_GRILLE_PERIOD);
    float aperture_grille_mask;

    if (aperture_grille_step < 3)
        aperture_grille_mask = 0.0;
    else if (aperture_grille_step < 4)
        aperture_grille_mask = fmod(8 * pin.pos.x, APERTURE_GRILLE_PERIOD) / APERTURE_GRILLE_PERIOD;
    else if (aperture_grille_step < 7)
        aperture_grille_mask = 1.0;
    else if (aperture_grille_step < 8)
        aperture_grille_mask = fmod(-8 * pin.pos.x, APERTURE_GRILLE_PERIOD) / APERTURE_GRILLE_PERIOD;

    fragColor.rgb *= 1.0 - APERTURE_GRILLE_STRENGTH * aperture_grille_mask;

    // Flicker effect
    fragColor *= 1.0 - FLICKER_STRENGTH / 2.0 * (1.0 + sin(2 * PI * FLICKER_FREQUENCY * iTime));

    // Noise effect
    float noiseContent = smoothstep(0.4, 0.6, frac(sin(uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y) * iTime * 4096.0) * 65536.0));
    float noiseUniform = smoothstep(0.4, 0.6, frac(sin(uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y) * iTime * 8192.0) * 65536.0));
    fragColor.rgb *= clamp(noiseContent + 1.0 - NOISE_CONTENT_STRENGTH, 0.0, 1.0);
    fragColor.rgb = clamp(fragColor.rgb + noiseUniform * NOISE_UNIFORM_STRENGTH, 0.0, 1.0);

    // Remove output outside of screen bounds
    if (uv.x < 0.0 || uv.x > 1.0)
        fragColor.rgb *= 0.0;
    if (uv.y < 0.0 || uv.y > 1.0)
        fragColor.rgb *= 0.0;

    // Bloom effect
#ifdef BLOOM_SPREAD
    float2 step = BLOOM_SPREAD * float2(1.414) / iResolution.xy;

    for (int i = 0; i < 24; i++) {
        float3 bloom_sample = float3(0.0, 0.0, 0.0); // Replace with actual bloom samples
        float4 neighbor = iChannel0.Sample(sampler0, uv + bloom_sample.xy * step);
        float luminance = 0.299 * neighbor.r + 0.587 * neighbor.g + 0.114 * neighbor.b;

        fragColor += luminance * bloom_sample.z * neighbor * BLOOM_STRENGTH;
    }

    fragColor = clamp(fragColor, 0.0, 1.0);
#endif

    // Fade effect
    fragColor = float4(FADE_FACTOR * fragColor.rgb, FADE_FACTOR);

    return fragColor;
}