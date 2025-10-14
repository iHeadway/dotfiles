// In-game CRT shader converted to HLSL
// Original GLSL by sarphiv, converted by [Your Name]
// License: CC BY-NC-SA 4.0

// Settings (same as original)
#define CURVE 13.0, 11.0
#define COLOR_FRINGING_SPREAD 0.85 //1.0
#define GHOSTING_SPREAD 0.75
#define GHOSTING_STRENGTH 1.0
#define DARKEN_MIX 0.2 //0.4
#define VIGNETTE_SPREAD 0.3
#define VIGNETTE_BRIGHTNESS 6.4
#define TINT 0.93, 1.00, 0.96
#define SCAN_LINES_STRENGTH 0.6 //0.15
#define SCAN_LINES_VARIANCE 0.35
#define SCAN_LINES_PERIOD 4.0
#define APERTURE_GRILLE_STRENGTH 0.2
#define APERTURE_GRILLE_PERIOD 2.0
#define FLICKER_STRENGTH 0.05
#define FLICKER_FREQUENCY 15.0
#define NOISE_CONTENT_STRENGTH 0.15
#define NOISE_UNIFORM_STRENGTH 0.03
#define BLOOM_SPREAD 2.0 //2.0 //8.0
#define BLOOM_STRENGTH 0.1 //0.1 //0.04
#define FADE_FACTOR 0.75 //0.55

// Constants
static const float PI = 3.14159265358979323846;

#ifdef BLOOM_SPREAD
static const float3 bloom_samples[24] = {
    float3( 0.1693761725038636,  0.9855514761735895,  1),
    float3(-1.333070830962943,   0.4721463328627773,  0.7071067811865475),
    float3(-0.8464394909806497, -1.51113870578065,    0.5773502691896258),
    float3( 1.554155680728463,  -1.2588090085709776,  0.5),
    float3( 1.681364377589461,   1.4741145918052656,  0.4472135954999579),
    float3(-1.2795157692199817,  2.088741103228784,   0.4082482904638631),
    float3(-2.4575847530631187, -0.9799373355024756,  0.3779644730092272),
    float3( 0.5874641440200847, -2.7667464429345077,  0.35355339059327373),
    float3( 2.997715703369726,   0.11704939884745152, 0.3333333333333333),
    float3( 0.41360842451688395, 3.1351121305574803,  0.31622776601683794),
    float3(-3.167149933769243,   0.9844599011770256,  0.30151134457776363),
    float3(-1.5736713846521535, -3.0860263079123245,  0.2886751345948129),
    float3( 2.888202648340422,  -2.1583061557896213,  0.2773500981126146),
    float3( 2.7150778983300325,  2.5745586041105715,  0.2672612419124244),
    float3(-2.1504069972377464,  3.2211410627650165,  0.2581988897471611),
    float3(-3.6548858794907493, -1.6253643308191343,  0.25),
    float3( 1.0130775986052671, -3.9967078676335834,  0.24253562503633297),
    float3( 4.229723673607257,   0.33081361055181563, 0.23570226039551587),
    float3( 0.40107790291173834, 4.340407413572593,   0.22941573387056174),
    float3(-4.319124570236028,   1.159811599693438,   0.22360679774997896),
    float3(-1.9209044802827355, -4.160543952132907,   0.2182178902359924),
    float3( 3.8639122286635708, -2.6589814382925123,  0.21320071635561041),
    float3( 3.3486228404946234,  3.4331800232609,     0.20851441405707477),
    float3(-2.8769733643574344,  3.9652268864187157,  0.20412414523193154)
};
#endif

cbuffer Constants : register(b0)
{
    float2 iResolution;
    float iTime;
};

Texture2D iChannel0 : register(t0);
SamplerState sampler_iChannel0 : register(s0);

float4 main(float4 fragCoord : SV_Position) : SV_Target
{
    float texWidth, texHeight;
    iChannel0.GetDimensions(texWidth, texHeight);
    float2 uv = fragCoord.xy / float2(texWidth, texHeight);

#ifdef CURVE
    // Fixed pow() warning with explicit absolute value
    float2 originalUV = uv;
    uv = (uv - 0.5) * 2.0;
    float2 curve = float2(CURVE);
    uv.xy *= 1.0 + pow(abs(float2(uv.y, uv.x) / curve), float2(2.0, 2.0));
    uv = (uv / 2.0) + 0.5;
#endif

    // Retrieve colors with color fringing
    float4 color;
    color.r = iChannel0.Sample(sampler_iChannel0, float2(uv.x + 0.0003 * COLOR_FRINGING_SPREAD, uv.y + 0.0003 * COLOR_FRINGING_SPREAD)).r;
    color.g = iChannel0.Sample(sampler_iChannel0, float2(uv.x, uv.y - 0.0006 * COLOR_FRINGING_SPREAD)).g;
    color.b = iChannel0.Sample(sampler_iChannel0, float2(uv.x - 0.0006 * COLOR_FRINGING_SPREAD, uv.y)).b;
    color.a = iChannel0.Sample(sampler_iChannel0, uv).a;

    // Add ghosting
    color.r += 0.04 * GHOSTING_STRENGTH * iChannel0.Sample(sampler_iChannel0, GHOSTING_SPREAD * float2(+0.025, -0.027) + uv).r;
    color.g += 0.02 * GHOSTING_STRENGTH * iChannel0.Sample(sampler_iChannel0, GHOSTING_SPREAD * float2(-0.022, -0.020) + uv).g;
    color.b += 0.04 * GHOSTING_STRENGTH * iChannel0.Sample(sampler_iChannel0, GHOSTING_SPREAD * float2(-0.020, -0.018) + uv).b;

    // Darken colors
    color.rgb = lerp(color.rgb, color.rgb * color.rgb, DARKEN_MIX);

    // Vignette effect
    //color.rgb *= VIGNETTE_BRIGHTNESS * pow(uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), VIGNETTE_SPREAD);  //too dark
    color.rgb *= lerp(1.0, VIGNETTE_BRIGHTNESS, 0.2);

    // Apply tint
    color.rgb *= float3(TINT);

    // Scan lines
    color.rgb *= lerp(1.0, SCAN_LINES_VARIANCE/2.0*(1.0 + sin(2*PI* uv.y * iResolution.y/SCAN_LINES_PERIOD)), SCAN_LINES_STRENGTH);

    // Aperture grille
    int aperture_grille_step = int(8 * fmod(fragCoord.x, APERTURE_GRILLE_PERIOD) / APERTURE_GRILLE_PERIOD);
    float aperture_grille_mask = 0.0;

    if (aperture_grille_step < 3)
        aperture_grille_mask = 0.0;
    else if (aperture_grille_step < 4)
        aperture_grille_mask = fmod(8 * fragCoord.x, APERTURE_GRILLE_PERIOD) / APERTURE_GRILLE_PERIOD;
    else if (aperture_grille_step < 7)
        aperture_grille_mask = 1.0;
    else if (aperture_grille_step < 8)
        aperture_grille_mask = fmod(-8 * fragCoord.x, APERTURE_GRILLE_PERIOD) / APERTURE_GRILLE_PERIOD;

    color.rgb *= 1.0 - APERTURE_GRILLE_STRENGTH * aperture_grille_mask;

    // Flicker
    color *= 1.0 - FLICKER_STRENGTH/2.0*(1.0 + sin(2*PI*FLICKER_FREQUENCY*iTime));

    // Noise
    float noiseContent = smoothstep(0.4, 0.6, frac(sin(uv.x * uv.y * (1.0-uv.x) * (1.0-uv.y) * iTime * 4096.0) * 65536.0));
    float noiseUniform = smoothstep(0.4, 0.6, frac(sin(uv.x * uv.y * (1.0-uv.x) * (1.0-uv.y) * iTime * 8192.0) * 65536.0));
    color.rgb *= clamp(noiseContent + 1.0 - NOISE_CONTENT_STRENGTH, 0.0, 1.0);
    color.rgb = clamp(color.rgb + noiseUniform * NOISE_UNIFORM_STRENGTH, 0.0, 1.0);

    // Screen bounds check
    if (uv.x < 0.0 || uv.x > 1.0) color.rgb = 0.0;
    if (uv.y < 0.0 || uv.y > 1.0) color.rgb = 0.0;

#ifdef BLOOM_SPREAD
    // Bloom effect
    float2 step = BLOOM_SPREAD * 1.4142 / float2(3840.0, 2160.0);
    for (int i = 0; i < 24; i++) {
        float3 bloom_sample = bloom_samples[i];
        float4 neighbor = iChannel0.Sample(sampler_iChannel0, uv + bloom_sample.xy * step);
        float luminance = 0.299 * neighbor.r + 0.587 * neighbor.g + 0.114 * neighbor.b;
        color += luminance * bloom_sample.z * neighbor * BLOOM_STRENGTH;
    }
    color = clamp(color, 0.0, 1.0);
#endif

    // Fade effect
    color = float4(FADE_FACTOR * color.rgb, FADE_FACTOR);
    return color;
}