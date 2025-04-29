#ifndef INCLUDE_VOXELIZATION
    #define INCLUDE_VOXELIZATION

    #if COLORED_LIGHTING_INTERNAL <= 512
        const ivec3 voxelVolumeSize = ivec3(COLORED_LIGHTING_INTERNAL, COLORED_LIGHTING_INTERNAL * 0.5, COLORED_LIGHTING_INTERNAL);
    #else
        const ivec3 voxelVolumeSize = ivec3(COLORED_LIGHTING_INTERNAL, 512 * 0.5, COLORED_LIGHTING_INTERNAL);
    #endif

    float effectiveACLdistance = min(float(COLORED_LIGHTING_INTERNAL), shadowDistance * 2.0);

    vec3 transform(mat4 m, vec3 pos) {
        return mat3(m) * pos + m[3].xyz;
    }

    vec3 SceneToVoxel(vec3 scenePos) {
        return scenePos + cameraPositionBestFract + (0.5 * vec3(voxelVolumeSize));
    }

    bool CheckInsideVoxelVolume(vec3 voxelPos) {
        #ifndef SHADOW
            voxelPos -= voxelVolumeSize / 2;
            voxelPos += sign(voxelPos) * 0.95;
            voxelPos += voxelVolumeSize / 2;
        #endif
        voxelPos /= vec3(voxelVolumeSize);
        return clamp01(voxelPos) == voxelPos;
    }

    vec4 GetLightVolume(vec3 pos) {
        vec4 lightVolume;

        #ifdef COMPOSITE
            #undef ACL_CORNER_LEAK_FIX
        #endif

        #ifdef ACL_CORNER_LEAK_FIX
            float minMult = 1.5;
            ivec3 posTX = ivec3(pos * voxelVolumeSize);

            ivec3[6] adjacentOffsets = ivec3[](
                ivec3( 1, 0, 0),
                ivec3(-1, 0, 0),
                ivec3( 0, 1, 0),
                ivec3( 0,-1, 0),
                ivec3( 0, 0, 1),
                ivec3( 0, 0,-1)
            );

            int adjacentCount = 0;
            for (int i = 0; i < 6; i++) {
                int voxel = int(texelFetch(voxel_sampler, posTX + adjacentOffsets[i], 0).r);
                if (voxel == 1 || voxel >= 200) adjacentCount++;
            }

            if (int(texelFetch(voxel_sampler, posTX, 0).r) >= 200) adjacentCount = 6;
        #endif

        if ((frameCounter & 1) == 0) {
            lightVolume = texture(floodfill_sampler_copy, pos);
            #ifdef ACL_CORNER_LEAK_FIX
                if (adjacentCount >= 3) {
                    vec4 lightVolumeTX = texelFetch(floodfill_sampler_copy, posTX, 0);
                    if (dot(lightVolumeTX, lightVolumeTX) > 0.01)
                    lightVolume.rgb = min(lightVolume.rgb, lightVolumeTX.rgb * minMult);
                }
            #endif
        } else {
            lightVolume = texture(floodfill_sampler, pos);
            #ifdef ACL_CORNER_LEAK_FIX
                if (adjacentCount >= 3) {
                    vec4 lightVolumeTX = texelFetch(floodfill_sampler, posTX, 0);
                    if (dot(lightVolumeTX, lightVolumeTX) > 0.01)
                    lightVolume.rgb = min(lightVolume.rgb, lightVolumeTX.rgb * minMult);
                }
            #endif
        }

        return lightVolume;
    }

    int GetVoxelIDs(int mat) {
        /* These return IDs must be consistent across the following files:
        "voxelization.glsl", "blocklightColors.glsl", "item.properties"
        The order of if-checks or block IDs don't matter. The returning IDs matter. */

        #define ALWAYS_DO_IPBR_LIGHTS

        #if defined IPBR || defined ALWAYS_DO_IPBR_LIGHTS
            #define DO_IPBR_LIGHTS
        #endif

        if (mat < 10564) {
            if (mat < 10356) {
                if (mat < 10300) {
                    if (mat < 10228) {
                        if (mat == 10056) return  14; // Lava Cauldron
                        if (mat == 10068) return  13; // Lava
                        if (mat == 10072) return   5; // Fire
                        if (mat == 10076) return  27; // Soul Fire
                        #ifdef DO_IPBR_LIGHTS
                        if (mat == 10216) return  62; // Crimson Stem, Crimson Hyphae
                        if (mat == 10224) return  63; // Warped Stem, Warped Hyphae
                        #endif
                    } else {
                        if (mat == 10228) return 255; // Bedrock
                        #if defined GLOWING_ORE_ANCIENTDEBRIS && defined DO_IPBR_LIGHTS
                        if (mat == 10252) return  52; // Ancient Debris
                        #endif
                        #if defined GLOWING_ORE_IRON && defined DO_IPBR_LIGHTS
                        if (mat == 10272) return  43; // Iron Ore
                        if (mat == 10276) return  43; // Deepslate Iron Ore
                        #endif
                        #if defined GLOWING_ORE_COPPER && defined DO_IPBR_LIGHTS
                        if (mat == 10284) return  45; // Copper Ore
                        if (mat == 10288) return  45; // Deepslate Copper Ore
                        #endif
                    }
                } else {
                    if (mat < 10332) {
                        #if defined GLOWING_ORE_GOLD && defined DO_IPBR_LIGHTS
                        if (mat == 10300) return  44; // Gold Ore
                        if (mat == 10304) return  44; // Deepslate Gold Ore
                        #endif
                        #if defined GLOWING_ORE_NETHERGOLD && defined DO_IPBR_LIGHTS
                        if (mat == 10308) return  50; // Nether Gold Ore
                        #endif
                        #if defined GLOWING_ORE_DIAMOND && defined DO_IPBR_LIGHTS
                        if (mat == 10320) return  48; // Diamond Ore
                        if (mat == 10324) return  48; // Deepslate Diamond Ore
                        #endif
                    } else {
                        if (mat == 10332) return  36; // Amethyst Cluster, Amethyst Buds
                        #if defined GLOWING_ORE_EMERALD && defined DO_IPBR_LIGHTS
                        if (mat == 10340) return  47; // Emerald Ore
                        if (mat == 10344) return  47; // Deepslate Emerald Ore
                        #endif
                        #if defined EMISSIVE_LAPIS_BLOCK && defined DO_IPBR_LIGHTS
                        if (mat == 10352) return  42; // Lapis Block
                        #endif
                    }
                }
            } else {
                if (mat < 10496) {
                    if (mat < 10448) {
                        #if defined GLOWING_ORE_LAPIS && defined DO_IPBR_LIGHTS
                        if (mat == 10356) return  46; // Lapis Ore
                        if (mat == 10360) return  46; // Deepslate Lapis Ore
                        #endif
                        #if defined GLOWING_ORE_NETHERQUARTZ && defined DO_IPBR_LIGHTS
                        if (mat == 10368) return  49; // Nether Quartz Ore
                        #endif
                        if (mat == 10396) return  11; // Jack o'Lantern
                        if (mat == 10404) return   6; // Sea Pickle:Waterlogged
                        if (mat == 10412) return  10; // Glowstone
                    } else {
                        if (mat == 10448) return  18; // Sea Lantern
                        if (mat == 10452) return  37; // Magma Block
                        #ifdef DO_IPBR_LIGHTS
                        if (mat == 10456) return  60; // Command Block
                        #endif
                        if (mat == 10476) return  26; // Crying Obsidian
                        #if defined GLOWING_ORE_GILDEDBLACKSTONE && defined DO_IPBR_LIGHTS
                        if (mat == 10484) return  51; // Gilded Blackstone
                        #endif
                    }
                } else {
                    if (mat < 10528) {
                        if (mat == 10496) return   2; // Torch
                        if (mat == 10500) return   3; // End Rod
                        #ifdef DO_IPBR_LIGHTS
                        if (mat == 10508) return  39; // Chorus Flower:Alive
                        if (mat == 10512) return  39; // Chorus Flower:Dead
                        #endif
                        if (mat == 10516) return  21; // Furnace:Lit
                    } else {
                        if (mat == 10528) return  28; // Soul Torch
                        if (mat == 10544) return  34; // Glow Lichen
                        if (mat == 10548) return  33; // Enchanting Table
                        if (mat == 10556) return  58; // End Portal Frame:Active
                        if (mat == 10560) return  12; // Lantern
                    }
                }
            }
        } else {
            if (mat < 10696) {
                if (mat < 10620) {
                    if (mat < 10592) {
                        if (mat == 10564) return  29; // Soul Lantern
                        #ifdef DO_IPBR_LIGHTS
                        if (mat == 10572) return  38; // Dragon Egg
                        #endif
                        if (mat == 10576) return  22; // Smoker:Lit
                        if (mat == 10580) return  23; // Blast Furnace:Lit
                    } else {
                        if (mat == 10592) return  17; // Respawn Anchor:Lit
                        #ifdef DO_IPBR_LIGHTS
                        if (mat == 10596) return  66; // Redstone Wire:Lit
                        #endif
                        if (mat == 10604) return  35; // Redstone Torch
                        #if defined EMISSIVE_REDSTONE_BLOCK && defined DO_IPBR_LIGHTS
                        if (mat == 10608) return  41; // Redstone Block
                        #endif
                        #if defined GLOWING_ORE_REDSTONE && defined DO_IPBR_LIGHTS
                        if (mat == 10612) return  32; // Redstone Ore:Unlit
                        #endif
                        if (mat == 10616) return  31; // Redstone Ore:Lit
                    }
                } else {
                    if (mat < 10648) {
                        #if defined GLOWING_ORE_REDSTONE && defined DO_IPBR_LIGHTS
                        if (mat == 10620) return  32; // Deepslate Redstone Ore:Unlit
                        #endif
                        if (mat == 10624) return  31; // Deepslate Redstone Ore:Lit
                        if (mat == 10632) return  20; // Cave Vines:With Glow Berries
                        if (mat == 10640) return  16; // Redstone Lamp:Lit
                        #ifdef DO_IPBR_LIGHTS
                        if (mat == 10644) return  67; // Repeater:Lit, Comparator:Lit
                        if (mat == 10646) return  66; // Comparator:Unlit:Subtract
                        #endif
                    } else {
                        if (mat == 10648) return  19; // Shroomlight
                        if (mat == 10652) return  15; // Campfire:Lit
                        if (mat == 10656) return  30; // Soul Campfire:Lit
                        if (mat == 10680) return   7; // Ochre Froglight
                        if (mat == 10684) return   8; // Verdant Froglight
                        if (mat == 10688) return   9; // Pearlescent Froglight
                    }
                }
            } else {
                if (mat < 10868) {
                    if (mat < 10780) {
                        if (mat == 10696) return  57; // Sculk, Sculk Catalyst, Sculk Vein, Sculk Sensor:Unlit
                        if (mat == 10700) return  57; // Sculk Shrieker
                        if (mat == 10704) return  57; // Sculk Sensor:Lit
                        #ifdef DO_IPBR_LIGHTS
                        if (mat == 10708) return  53; // Spawner
                        if (mat == 10736) return  64; // Structure Block, Jigsaw Block, Test Block, Test Instance Block
                        if (mat == 10776) return  61; // Warped Fungus, Crimson Fungus
                        #endif
                    } else {
                        #ifdef DO_IPBR_LIGHTS
                        if (mat == 10780) return  61; // Potted Warped Fungus, Potted Crimson Fungus
                        #endif
                        if (mat == 10784) return  36; // Calibrated Sculk Sensor:Unlit
                        if (mat == 10788) return  36; // Calibrated Sculk Sensor:Lit
                        #ifdef DO_IPBR_LIGHTS
                        if (mat == 10836) return  40; // Brewing Stand
                        #endif
                        if (mat == 10852) return  55; // Copper Bulb:BrighterOnes:Lit
                        if (mat == 10856) return  56; // Copper Bulb:DimmerOnes:Lit
                    }
                } else {
                    if (mat < 30020) {
                        if (mat == 10868) return  54; // Trial Spawner:NotOminous:Active, Vault:NotOminous:Active
                        if (mat == 10872) return  68; // Vault:Inactive
                        if (mat == 10876) return  69; // Trial Spawner:Ominous:Active, Vault:Ominous:Active
                        #ifdef DO_IPBR_LIGHTS
                        if (mat == 10884) return  65; // Weeping Vines Plant
                        #endif
                        #ifndef COLORED_CANDLE_LIGHT
                        if (mat >= 10900 && mat <= 10922) return 24; // Standard Candles:Lit
                        #else
                        if (mat == 10900) return  24; // Standard Candles:Lit
                        if (mat == 10902) return  70; // Red Candles:Lit
                        if (mat == 10904) return  71; // Orange Candles:Lit
                        if (mat == 10906) return  72; // Yellow Candles:Lit
                        if (mat == 10908) return  73; // Lime Candles:Lit
                        if (mat == 10910) return  74; // Green Candles:Lit
                        if (mat == 10912) return  75; // Cyan Candles:Lit
                        if (mat == 10914) return  76; // Light Blue Candles:Lit
                        if (mat == 10916) return  77; // Blue Candles:Lit
                        if (mat == 10918) return  78; // Purple Candles:Lit
                        if (mat == 10920) return  79; // Magenta Candles:Lit
                        if (mat == 10922) return  80; // Pink Candles:Lit
                        #endif
                        if (mat == 10948) return  82; // Creaking Heart: Active
                        if (mat == 10972) return  83; // Firefly Bush
                        if (mat == 10976) return  81; // Open Eyeblossom
                        if (mat == 10980) return  81; // Potted Open Eyeblossom
                        if (mat == 30008) return 254; // Tinted Glass
                        if (mat == 30012) return 213; // Slime Block
                        if (mat == 30016) return 201; // Honey Block
                    } else {
                        if (mat == 30020) return  25; // Nether Portal
                        if (mat >= 31000 && mat < 32000) return 200 + (mat - 31000) / 2; // Stained Glass+
                        if (mat == 32004) return 216; // Ice
                        if (mat == 32008) return 217; // Glass
                        if (mat == 32012) return 218; // Glass Pane
                        if (mat == 32016) return   4; // Beacon
                    }
                }
            }
        }

        return 1; // Standard Block
    }

    #if defined SHADOW && defined VERTEX_SHADER
        void UpdateVoxelMap(int mat) {
            if (mat == 32000 // Water
            || mat < 30000 && mat % 4 == 1 // Non-solid terrain
            || mat < 10000 // Block entities or unknown blocks that we treat as non-solid
            ) return;

            vec3 modelPos = gl_Vertex.xyz + at_midBlock / 64.0;
            vec3 viewPos = transform(gl_ModelViewMatrix, modelPos);
            vec3 scenePos = transform(shadowModelViewInverse, viewPos);
            vec3 voxelPos = SceneToVoxel(scenePos);

            bool isEligible = any(equal(ivec4(renderStage), ivec4(
                MC_RENDER_STAGE_TERRAIN_SOLID,
                MC_RENDER_STAGE_TERRAIN_TRANSLUCENT,
                MC_RENDER_STAGE_TERRAIN_CUTOUT,
                MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED)));

            if (isEligible && CheckInsideVoxelVolume(voxelPos)) {
                int voxelData = GetVoxelIDs(mat);
                
                imageStore(voxel_img, ivec3(voxelPos), uvec4(voxelData, 0u, 0u, 0u));
            }
        }
    #endif

#endif //INCLUDE_VOXELIZATION