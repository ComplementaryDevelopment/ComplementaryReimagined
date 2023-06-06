/*---------------------------------------------------------------------
         ___ __  __ ____   ___  ____ _____  _    _   _ _____ 
        |_ _|  \/  |  _ \ / _ \|  _ \_   _|/ \  | \ | |_   _|
         | || |\/| | |_) | | | | |_) || | / _ \ |  \| | | |  
         | || |  | |  __/| |_| |  _ < | |/ ___ \| |\  | | |  
        |___|_|  |_|_|    \___/|_| \_\|_/_/   \_\_| \_| |_|  
         .
  -> -> -> EDITING THIS FILE HAS A HIGH CHANCE TO BREAK THE SHADERPACK
  -> -> -> DO NOT CHANGE ANYTHING UNLESS YOU KNOW WHAT YOU ARE DOING
  -> -> -> DO NOT EXPECT SUPPORT AFTER MODIFYING SHADER FILES
---------------------------------------------------------------------*/

//User Settings//
    #define CMPR 0 //[0]

    #define SHADER_STYLE 1 //[1 4]

    #define RP_MODE 1 //[0 1 2 3]
    #if RP_MODE == 1
        #define IPBR
        //#define GENERATED_NORMALS
        //#define COATED_TEXTURES
    #endif
    #if RP_MODE >= 2
        #define CUSTOM_PBR
        #define POM
    #endif

    #define REALTIME_SHADOWS
    #define SHADOW_QUALITY 2 //[1 2 3 4 5]
    const float shadowDistance = 192.0; //[64.0 80.0 96.0 112.0 128.0 160.0 192.0 224.0 256.0 320.0 384.0 512.0 768.0 1024.0]
    //#define ENTITY_SHADOWS
    #define SSAO 2 //[0 2 1]
    #define WATER_QUALITY 2 //[1 2 3]
    #define LIGHTSHAFT_QUALITY 3 //[0 1 2 3 4]
    #define WATER_REFLECT_QUALITY 2 //[0 1 2]
    #define BLOCK_REFLECT_QUALITY 2 //[0 2 3]
    #if BLOCK_REFLECT_QUALITY >= 3
        #define TEMPORAL_FILTER
    #endif

    #define WATER_STYLE_DEFINE -1 //[-1 1 2 3]
    #define WATER_BUMPINESS 1.25 //[0.15 0.20 0.25 0.30 0.40 0.50 0.65 0.80 1.00 1.25 1.50 2.00 2.50]
    #define WATER_REFRACTION_INTENSITY 2.0 //[1.0 1.2 1.4 1.6 1.8 2.0 2.2 2.4 2.6 2.8 3.0]
    #define WATERCOLOR_R 100 //[25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 110 120 130 140 150 160 170 180 190 200 220 240 260 280 300]
    #define WATERCOLOR_G 100 //[25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 110 120 130 140 150 160 170 180 190 200 220 240 260 280 300]
    #define WATERCOLOR_B 100 //[25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 110 120 130 140 150 160 170 180 190 200 220 240 260 280 300]

    #define PIXEL_SHADOW 0 //[0 8 16 32 64 128]
    #define HAND_SWAYING 0 //[0 1 2 3]
    //#define LESS_LAVA_FOG
    #define SHOW_LIGHT_LEVEL 0 //[0 1 2 3]
    #define RAIN_PUDDLES 0 //[0 1 2 3 4]
    //#define SNOWY_WORLD
    
    #define SELECT_OUTLINE 1 //[0 1 2 3]
    #define SELECT_OUTLINE_I 1.00 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.20 2.40 2.60 2.80 3.00 3.25 3.50 3.75 4.00 4.50 5.00]
    #define SELECT_OUTLINE_R 1.35 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
    #define SELECT_OUTLINE_G 0.35 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
    #define SELECT_OUTLINE_B 1.75 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]

    //#define WORLD_OUTLINE
    #define WORLD_OUTLINE_THICKNESS 1 //[1 2 3 4]

    #define AURORA_STYLE_DEFINE -1 //[-1 0 1 2]
    #define AURORA_CONDITION 3 //[0 1 2 3 4]
    #define SUN_MOON_STYLE_DEFINE -1 //[-1 1 2]
    #define SUN_MOON_HORIZON
    #define NIGHT_STAR_AMOUNT 2 //[2 3]
    #define CLOUD_STYLE_DEFINE -1 //[-1 0 1 2 3]
    //#define CLOUD_SHADOWS
    #define CLOUD_HIGH_QUALITY 1 //[1 2]
    #define CLOUD_CLOSED_AREA_CHECK
    #define CLOUD_ALT1 192.0 //[8.0 12.0 16.0 20.0 22.0 24.0 28.0 32.0 36.0 40.0 44.0 48.0 52.0 56.0 60.0 64.0 68.0 72.0 76.0 80.0 84.0 88.0 92.0 96.0 100.0 104.0 108.0 112.0 116.0 120.0 124.0 128.0 132.0 136.0 140.0 144.0 148.0 152.0 156.0 160.0 164.0 168.0 172.0 176.0 180.0 184.0 188.0 192.0 196.0 200.0 204.0 208.0 212.0 216.0 220.0 224.0 228.0 232.0 236.0 240.0 244.0 248.0 252.0 254.0 256.0 272.0 274.0 276.0 278.0 280.0 282.0 284.0 286.0 288.0 290.0 292.0 294.0 296.0 298.0 300.0 302.0 306.0 308.0 310.0 312.0 314.0 316.0 318.0 320.0 322.0 324.0 326.0 328.0 330.0 332.0 334.0 336.0 338.0 340.0 342.0 344.0 346.0 348.0 350.0 352.0 354.0 356.0 358.0 360.0 362.0 364.0 366.0 368.0 370.0 372.0 374.0 376.0 378.0 380.0 382.0 384.0 388.0 392.0 396.0 400.0]
    #define CLOUD_ALT2 288.0 //[8.0 12.0 16.0 20.0 22.0 24.0 28.0 32.0 36.0 40.0 44.0 48.0 52.0 56.0 60.0 64.0 68.0 72.0 76.0 80.0 84.0 88.0 92.0 96.0 100.0 104.0 108.0 112.0 116.0 120.0 124.0 128.0 132.0 136.0 140.0 144.0 148.0 152.0 156.0 160.0 164.0 168.0 172.0 176.0 180.0 184.0 188.0 192.0 196.0 200.0 204.0 208.0 212.0 216.0 220.0 224.0 228.0 232.0 236.0 240.0 244.0 248.0 252.0 254.0 256.0 272.0 274.0 276.0 278.0 280.0 282.0 284.0 286.0 288.0 290.0 292.0 294.0 296.0 298.0 300.0 302.0 306.0 308.0 310.0 312.0 314.0 316.0 318.0 320.0 322.0 324.0 326.0 328.0 330.0 332.0 334.0 336.0 338.0 340.0 342.0 344.0 346.0 348.0 350.0 352.0 354.0 356.0 358.0 360.0 362.0 364.0 366.0 368.0 370.0 372.0 374.0 376.0 378.0 380.0 382.0 384.0 388.0 392.0 396.0 400.0]

    #define BORDER_FOG
    #define ATM_FOG_MULT 0.95 //[0.50 0.65 0.80 0.95]
    #define CAVE_FOG
    #define LIGHTSHAFT_BEHAVIOUR 1 //[1 2 3]
    #define LIGHTSHAFT_DAY_I 100 //[1 3 5 7 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 110 120 130 140 150 160 170 180 190 200]
    #define LIGHTSHAFT_NIGHT_I 100 //[1 3 5 7 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 110 120 130 140 150 160 170 180 190 200]
    #define LIGHTSHAFT_RAIN_I 100 //[1 3 5 7 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 110 120 130 140 150 160 170 180 190 200]

    #define BLOOM_STRENGTH 0.12 //[0.027 0.036 0.045 0.054 0.063 0.072 0.081 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19]
    #define FXAA
    #define IMAGE_SHARPENING 3 //[0 1 2 3 4 5 6 7 8 9 10]
    //#define MOTION_BLURRING
    #define MOTION_BLURRING_STRENGTH 1.00 //[0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
    #define VIGNETTE_R

    #define ENTITY_GN_AND_CT
    #define GENERATED_NORMAL_MULT 100 //[50 55 60 65 70 75 80 85 90 95 100 110 120 130 140 150 160 170 180 190 200]
    #define COATED_TEXTURE_MULT 100 //[50 55 60 65 70 75 80 85 90 95 100 110 120 130 140 150 160 170 180 190 200]
    #define GLOWING_ORES 0 //[0 1 2]
    //#define FANCY_GLASS
    //#define EMISSIVE_REDSTONE_BLOCK
    //#define EMISSIVE_LAPIS_BLOCK
    #define GLOWING_AMETHYST 1 //[0 1 2]

    #define NORMAL_MAP_STRENGTH 100 //[0 10 15 20 30 40 60 80 100 120 140 160 180 200]
    #define CUSTOM_EMISSION_INTENSITY 100 //[0 5 7 10 15 20 25 30 35 40 45 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200 225 250]
    #define POM_DEPTH 0.80 //[0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
    #define POM_QUALITY 128 //[16 32 64 128 256 512]
    #define POM_DISTANCE 32 //[16 24 32 48 64 128 256 512 1024]
    #define POM_LIGHTING_MODE 2 //[1 2]
    //#define POM_ALLOW_CUTOUT
    #define DIRECTIONAL_BLOCKLIGHT 0 //[0 3 7 11]

    #define BLOCKLIGHT_COLOR_MODE 10 //[9 10 11]
    #define MINIMUM_LIGHT_MODE 2 //[0 1 2 3 4]
    #define HELD_LIGHTING_MODE 2 //[0 1 2]
    #define AMBIENT_MULT 100 //[50 55 60 65 70 75 80 85 90 95 100 110 120 130 140 150 160 170 180 190 200]

    #define NO_WAVING_INDOORS
    #define WAVING_FOLIAGE
    //#define WAVING_LEAVES
    #define WAVING_WATER_VERTEX

    #define SUN_ANGLE -1 //[-1 0 -20 -30 -40]

    #define T_EXPOSURE 1.40 //[0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.10 2.20 2.30 2.40 2.50 2.60 2.70 2.80]
    #define TM_WHITE_CURVE 2.0 //[1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0]
    #define T_LOWER_CURVE 1.20 //[0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
    #define T_UPPER_CURVE 1.30 //[0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
    #define T_SATURATION 1.00 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
    #define T_VIBRANCE 1.00 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
    //#define COLORGRADING
    #define GR_RR 100 //[0 4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96 100 108 116 124 132 140 148 156 164 172 180 188 196 200 212 224 236 248 260 272 284 296 300 316 332 348 364 380 396 400 400 424 448 472 496 500]
    #define GR_RG 0 //[0 4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96 100 108 116 124 132 140 148 156 164 172 180 188 196 200 212 224 236 248 260 272 284 296 300 316 332 348 364 380 396 400 400 424 448 472 496 500]
    #define GR_RB 0 //[0 4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96 100 108 116 124 132 140 148 156 164 172 180 188 196 200 212 224 236 248 260 272 284 296 300 316 332 348 364 380 396 400 400 424 448 472 496 500]
    #define GR_RC 1.00 //[0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00 2.20 2.40 2.60 2.80 3.00 3.25 3.50 3.75 4.00 4.50 5.00]
    #define GR_GR 0 //[0 4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96 100 108 116 124 132 140 148 156 164 172 180 188 196 200 212 224 236 248 260 272 284 296 300 316 332 348 364 380 396 400 400 424 448 472 496 500]
    #define GR_GG 100 //[0 4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96 100 108 116 124 132 140 148 156 164 172 180 188 196 200 212 224 236 248 260 272 284 296 300 316 332 348 364 380 396 400 400 424 448 472 496 500]
    #define GR_GB 0 //[0 4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96 100 108 116 124 132 140 148 156 164 172 180 188 196 200 212 224 236 248 260 272 284 296 300 316 332 348 364 380 396 400 400 424 448 472 496 500]
    #define GR_GC 1.00 //[0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00 2.20 2.40 2.60 2.80 3.00 3.25 3.50 3.75 4.00 4.50 5.00]
    #define GR_BR 0 //[0 4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96 100 108 116 124 132 140 148 156 164 172 180 188 196 200 212 224 236 248 260 272 284 296 300 316 332 348 364 380 396 400 400 424 448 472 496 500]
    #define GR_BG 0 //[0 4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96 100 108 116 124 132 140 148 156 164 172 180 188 196 200 212 224 236 248 260 272 284 296 300 316 332 348 364 380 396 400 400 424 448 472 496 500]
    #define GR_BB 100 //[0 4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96 100 108 116 124 132 140 148 156 164 172 180 188 196 200 212 224 236 248 260 272 284 296 300 316 332 348 364 380 396 400 400 424 448 472 496 500]
    #define GR_BC 1.00 //[0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00 2.20 2.40 2.60 2.80 3.00 3.25 3.50 3.75 4.00 4.50 5.00]

    //#define LIGHT_COLOR_MULTS
    //#define ATM_COLOR_MULTS
    #define LIGHT_MORNING_R 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define LIGHT_MORNING_G 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define LIGHT_MORNING_B 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define LIGHT_MORNING_I 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define ATM_MORNING_R 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define ATM_MORNING_G 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define ATM_MORNING_B 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define ATM_MORNING_I 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define LIGHT_NOON_R 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define LIGHT_NOON_G 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define LIGHT_NOON_B 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define LIGHT_NOON_I 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define ATM_NOON_R 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define ATM_NOON_G 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define ATM_NOON_B 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define ATM_NOON_I 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define LIGHT_NIGHT_R 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define LIGHT_NIGHT_G 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define LIGHT_NIGHT_B 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define LIGHT_NIGHT_I 1.00 //[0.01 0.03 0.05 0.07 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define ATM_NIGHT_R 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define ATM_NIGHT_G 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define ATM_NIGHT_B 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define ATM_NIGHT_I 1.00 //[0.01 0.03 0.05 0.07 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define LIGHT_RAIN_R 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define LIGHT_RAIN_G 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define LIGHT_RAIN_B 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define LIGHT_RAIN_I 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define ATM_RAIN_R 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define ATM_RAIN_G 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define ATM_RAIN_B 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define ATM_RAIN_I 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define LIGHT_NETHER_R 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define LIGHT_NETHER_G 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define LIGHT_NETHER_B 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define LIGHT_NETHER_I 1.00 //[0.01 0.03 0.05 0.07 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define ATM_NETHER_R 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define ATM_NETHER_G 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define ATM_NETHER_B 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define ATM_NETHER_I 1.00 //[0.01 0.03 0.05 0.07 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define LIGHT_END_R 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define LIGHT_END_G 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define LIGHT_END_B 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define LIGHT_END_I 1.00 //[0.01 0.03 0.05 0.07 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define ATM_END_R 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define ATM_END_G 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define ATM_END_B 1.00 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
    #define ATM_END_I 1.00 //[0.01 0.03 0.05 0.07 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]

//Internal Settings//
    #define SIDE_SHADOWING

    #define GLASS_OPACITY 0.25
    #define FANCY_NETHERPORTAL
    
    #define SHADOW_FILTERING
    const int shadowMapResolution = 2048;

    #define LIGHT_HIGHLIGHT
    #define DIRECTIONAL_SHADING

    #define CLOUD_STRETCH 5.5
    #define ATMOSPHERIC_FOG
    #define BLOOM_FOG

    #define TAA

    #define GLOWING_ENTITY_FIX
    #define FLICKERING_FIX
    //#define SAFER_GENERATED_NORMALS

    #define BLOOM
    #define UNDERWATER_DISTORTION

//Visual Style Handling//
    #if SHADER_STYLE == 1
        #define WATER_STYLE_DEFAULT 1
        #define AURORA_STYLE_DEFAULT 1
        #define SUN_MOON_STYLE_DEFAULT 1
        #define CLOUD_STYLE_DEFAULT 1
    #elif SHADER_STYLE == 4
        #define WATER_STYLE_DEFAULT 3
        #define AURORA_STYLE_DEFAULT 2
        #define SUN_MOON_STYLE_DEFAULT 2
        #define CLOUD_STYLE_DEFAULT 3
    #endif
    #if WATER_STYLE_DEFINE == -1
        #define WATER_STYLE WATER_STYLE_DEFAULT
    #else
        #define WATER_STYLE WATER_STYLE_DEFINE
    #endif
    #if AURORA_STYLE_DEFINE == -1
        #define AURORA_STYLE AURORA_STYLE_DEFAULT
    #else
        #define AURORA_STYLE AURORA_STYLE_DEFINE
    #endif
    #if SUN_MOON_STYLE_DEFINE == -1
        #define SUN_MOON_STYLE SUN_MOON_STYLE_DEFAULT
    #else
        #define SUN_MOON_STYLE SUN_MOON_STYLE_DEFINE
    #endif
    #if CLOUD_STYLE_DEFINE == -1
        #define CLOUD_STYLE CLOUD_STYLE_DEFAULT
    #else
        #define CLOUD_STYLE CLOUD_STYLE_DEFINE
    #endif
    // Thanks to SpacEagle17 and isuewo for the sun angle handling
    #if SUN_ANGLE == -1
        #if SHADER_STYLE == 1
            const float sunPathRotation = 0.0;
            #define PERPENDICULAR_TWEAKS
        #elif SHADER_STYLE == 4
            const float sunPathRotation = -40.0;
        #endif
    #elif SUN_ANGLE == 0
        const float sunPathRotation = 0.0;
        #define PERPENDICULAR_TWEAKS
    #elif SUN_ANGLE == -20
        const float sunPathRotation = -20.0;
    #elif SUN_ANGLE == -30
        const float sunPathRotation = -30.0;
    #elif SUN_ANGLE == -40
        const float sunPathRotation = -40.0;
    #endif

//Define Handling//
    #ifndef OVERWORLD
        #undef LIGHT_HIGHLIGHT
        #undef CAVE_FOG
        #undef CLOUD_SHADOWS
        #undef SNOWY_WORLD
    #endif
    #ifdef NETHER
        #undef ATMOSPHERIC_FOG
    #endif
    #ifdef END
        #undef BLOOM_FOG
    #endif

    #if defined GBUFFERS_TEXTURED || defined GBUFFERS_BASIC
        #undef LIGHT_HIGHLIGHT
        #undef DIRECTIONAL_SHADING
        #undef SIDE_SHADOWING
    #endif
    #ifdef GBUFFERS_WATER
        #undef LIGHT_HIGHLIGHT
    #endif

    #ifndef BLOOM
        #undef BLOOM_FOG
    #endif

    #ifndef GLOWING_ENTITY_FIX
        #undef GBUFFERS_ENTITIES_GLOWING
    #endif

    #if LIGHTSHAFT_QUALITY > 0 && defined OVERWORLD && defined REALTIME_SHADOWS || defined END
        #define LIGHTSHAFTS_ACTIVE
    #endif

    #if defined OVERWORLD && CLOUD_STYLE > 0
        #define CLOUDS_ACTIVATE
    #endif
    #if defined OVERWORLD && (CLOUD_STYLE == 1 || CLOUD_STYLE == 2)
        #define CLOUDS_REIMAGINED
    #endif

    #if RP_MODE >= 1 && BLOCK_REFLECT_QUALITY >= 1
        #define PBR_REFLECTIONS
    #endif

    #if defined WAVING_FOLIAGE || defined WAVING_LEAVES
        #define WAVING_ANYTHING_TERRAIN
    #endif

    #ifdef IS_IRIS
        #undef FANCY_GLASS
    #endif

//Activate Settings//
    #ifdef ENTITY_SHADOWS
    #endif
    #ifdef POM_ALLOW_CUTOUT
    #endif
    #ifdef ATM_COLOR_MULTS
    #endif
    #ifdef CLOUD_CLOSED_AREA_CHECK
    #endif

//Very Common Uniforms//
    uniform int worldTime;
    uniform int worldDay;

    uniform float rainFactor;
    uniform float screenBrightness;
    uniform float eyeBrightnessM;

    uniform vec3 fogColor;

    #ifdef VERTEX_SHADER
        uniform mat4 gbufferModelView;
    #endif

//Very Common Variables//
    const float shadowMapBias = 1.0 - 25.6 / shadowDistance;
    float timeAngle = worldTime / 24000.0;
    float noonFactor = sqrt(max(sin(timeAngle*6.28318530718),0.0));
    float nightFactor = max(sin(timeAngle*(-6.28318530718)),0.0);

    float rainFactor2 = rainFactor * rainFactor;
    float invRainFactor = 1.0 - rainFactor;
    float invRainFactorSqrt = 1.0 - rainFactor * rainFactor;
    float invNoonFactor = 1.0 - noonFactor;
    float invNoonFactor2 = invNoonFactor * invNoonFactor;

    float vsBrightness = clamp(screenBrightness, 0.0, 1.0);

    int modifiedWorldDay = int(mod(worldDay, 100) + 5.0);
    float syncedTime = (worldTime + modifiedWorldDay * 24000) * 0.05;

    const float pi = 3.14159265359;
    const float OSIEBCA = 1.0 / 255.0; // One Step In Eight Bit Color Attachment
    /* materialMask steps
    IntegratedPBR:
        OSIEBCA * 1.0 = Intense Fresnel
        OSIEBCA * 2.0 = Copper Fresnel
        OSIEBCA * 3.0 = Gold Fresnel
        OSIEBCA * 4.0 = 
        OSIEBCA * 5.0 = Redstone Fresnel
    PBR Independant: (Limited to 241 and above)
        OSIEBCA * 241.0 = Water
        .
        OSIEBCA * 253.0 = Reduced Edge TAA
        OSIEBCA * 254.0 = No SSAO, No TAA
        OSIEBCA * 255.0 = Unused as 1.0 is the clear color
    */

    const float oceanAltitude = 61.9;

    const float blocklightColMult = 0.875;
    #if BLOCKLIGHT_COLOR_MODE == 9
        const vec3 blocklightCol = vec3(0.40, 0.32, 0.29) * blocklightColMult;
    #elif BLOCKLIGHT_COLOR_MODE == 10
        const vec3 blocklightCol = vec3(0.43, 0.32, 0.26) * blocklightColMult; // Default
    #elif BLOCKLIGHT_COLOR_MODE == 11
        const vec3 blocklightCol = vec3(0.44, 0.31, 0.22) * blocklightColMult;
    #endif

    const vec3 caveFogColorRaw = vec3(0.13, 0.13, 0.15);
    #if MINIMUM_LIGHT_MODE <= 1
        vec3 caveFogColor = caveFogColorRaw * 0.7;
    #elif MINIMUM_LIGHT_MODE == 2
        vec3 caveFogColor = caveFogColorRaw * (0.7 + 0.3 * vsBrightness); // Default
    #elif MINIMUM_LIGHT_MODE >= 3
        vec3 caveFogColor = caveFogColorRaw;
    #endif

    vec3 underwaterColor = pow(fogColor, vec3(0.33, 0.21, 0.26));
    vec3 waterFogColor = underwaterColor * vec3(0.2 + 0.1 * vsBrightness);

    vec3 endSkyColor = vec3(0.095, 0.07, 0.15) * 1.5;

    #ifdef FRAGMENT_SHADER
        ivec2 texelCoord = ivec2(gl_FragCoord.xy);
    #endif

//Very Common Functions//
    #ifdef VERTEX_SHADER
        vec2 GetLightMapCoordinates() {
            vec2 lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
            return clamp((lmCoord - 0.03125) * 1.06667, 0.0, 1.0);
        }
        vec3 GetSunVector() {
            const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
            #ifdef OVERWORLD
                float ang = fract(timeAngle - 0.25);
                ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
                return normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
            #elif defined END
                float ang = 0.0;
                return normalize((gbufferModelView * vec4(vec3(0.0, sunRotationData * 2000.0), 1.0)).xyz);
            #else
                return vec3(0.0);
            #endif
        }
    #endif

    float GetLuminance(vec3 color) {
        return dot(color, vec3(0.299, 0.587, 0.114));
    }

    vec3 DoLuminanceCorrection(vec3 color) {
        return color / GetLuminance(color);
    }

    float GetBiasFactor(float NdotLM) {
        float NdotLM2 = NdotLM * NdotLM;
        return 1.25 * (1.0 - NdotLM2 * NdotLM2) / NdotLM;
    }

    float GetHorizonFactor(float XdotU) {
        #ifdef SUN_MOON_HORIZON
            float horizon = clamp((XdotU + 0.1) * 10.0, 0.0, 1.0);
            horizon *= horizon;
            return horizon * horizon * (3.0 - 2.0 * horizon);
        #else
            float horizon = min(XdotU + 1.0, 1.0);
            horizon *= horizon;
            horizon *= horizon;
            return horizon * horizon;
        #endif
    }

    bool CheckForColor(vec3 albedo, vec3 check) { // Thanks to Builderb0y
        vec3 dif = albedo - check * 0.003921568;
        return dif == clamp(dif, vec3(-0.001), vec3(0.001));
    }

    int min1(int x) {
        return min(x, 1);
    }
    float min1(float x) {
        return min(x, 1.0);
    }
    int max0(int x) {
        return max(x, 0);
    }
    float max0(float x) {
        return max(x, 0.0);
    }
    int clamp01(int x) {
        return clamp(x, 0, 1);
    }
    float clamp01(float x) {
        return clamp(x, 0.0, 1.0);
    }

    int pow2(int x) {
        return x * x;
    }
    float pow2(float x) {
        return x * x;
    }
    vec2 pow2(vec2 x) {
        return x * x;
    }
    vec3 pow2(vec3 x) {
        return x * x;
    }
    vec4 pow2(vec4 x) {
        return x * x;
    }

    int pow3(int x) {
        return pow2(x) * x;
    }
    float pow3(float x) {
        return pow2(x) * x;
    }
    vec2 pow3(vec2 x) {
        return pow2(x) * x;
    }
    vec3 pow3(vec3 x) {
        return pow2(x) * x;
    }
    vec4 pow3(vec4 x) {
        return pow2(x) * x;
    }

    float pow1_5(float x) { // Faster pow(x, 1.5) approximation (that isn't accurate at all) if x is between 0 and 1
        return x - x * pow2(1.0 - x); // Thanks to SixthSurge
    }
    vec2 pow1_5(vec2 x) {
        return x - x * pow2(1.0 - x);
    }
    vec3 pow1_5(vec3 x) {
        return x - x * pow2(1.0 - x);
    }
    vec4 pow1_5(vec4 x) {
        return x - x * pow2(1.0 - x);
    }

    float sqrt1(float x) { // Faster sqrt() approximation (that isn't accurate at all) if x is between 0 and 1
        return x * (2.0 - x); // Thanks to Builderb0y
    }
    vec2 sqrt1(vec2 x) {
        return x * (2.0 - x);
    }
    vec3 sqrt1(vec3 x) {
        return x * (2.0 - x);
    }
    vec4 sqrt1(vec4 x) {
        return x * (2.0 - x);
    }
    float sqrt2(float x) {
        x = 1.0 - x;
        x *= x;
        x *= x;
        return 1.0 - x;
    }
    vec2 sqrt2(vec2 x) {
        x = 1.0 - x;
        x *= x;
        x *= x;
        return 1.0 - x;
    }
    vec3 sqrt2(vec3 x) {
        x = 1.0 - x;
        x *= x;
        x *= x;
        return 1.0 - x;
    }
    vec4 sqrt2(vec4 x) {
        x = 1.0 - x;
        x *= x;
        x *= x;
        return 1.0 - x;
    }
    float sqrt3(float x) {
        x = 1.0 - x;
        x *= x;
        x *= x;
        x *= x;
        return 1.0 - x;
    }
    vec2 sqrt3(vec2 x) {
        x = 1.0 - x;
        x *= x;
        x *= x;
        x *= x;
        return 1.0 - x;
    }
    vec3 sqrt3(vec3 x) {
        x = 1.0 - x;
        x *= x;
        x *= x;
        x *= x;
        return 1.0 - x;
    }
    vec4 sqrt3(vec4 x) {
        x = 1.0 - x;
        x *= x;
        x *= x;
        x *= x;
        return 1.0 - x;
    }
    float sqrt4(float x) {
        x = 1.0 - x;
        x *= x;
        x *= x;
        x *= x;
        x *= x;
        return 1.0 - x;
    }
    vec2 sqrt4(vec2 x) {
        x = 1.0 - x;
        x *= x;
        x *= x;
        x *= x;
        x *= x;
        return 1.0 - x;
    }
    vec3 sqrt4(vec3 x) {
        x = 1.0 - x;
        x *= x;
        x *= x;
        x *= x;
        x *= x;
        return 1.0 - x;
    }
    vec4 sqrt4(vec4 x) {
        x = 1.0 - x;
        x *= x;
        x *= x;
        x *= x;
        x *= x;
        return 1.0 - x;
    }

    float smoothstep1(float x) {
        return x * x * (3.0 - 2.0 * x);
    }

// 62 75 74 20 74 68 4F 73 65 20 77 68 6F 20 68 6F 70 65 20 69 6E 20 74 68 65 20 6C 69 6D 69 4E 61 6C 0A 77 69 6C 6C 20 72 65 6E 65 77 20 74 68 65 69 72 20 73 54 72 65 6E 67 74 48 2E 0A 74 68 65 79 20 77 69 6C 6C 20 73 6F 41 72 20 6F 6E 20 65 6C 79 54 72 61 73 20 6C 69 6B 65 20 70 68 61 6E 74 6F 6D 73 3B 0A 74 68 65 79 20 77 69 6C 6C 20 72 75 6E 20 61 6E 44 20 6E 6F 74 20 67 72 6F 77 20 77 65 41 72 79 2C 0A 74 68 65 59 20 77 69 6C 6C 20 77 61 6C 6B 20 61 6E 64 20 6E 6F 74 20 62 65 20 66 61 69 6E 74 2E