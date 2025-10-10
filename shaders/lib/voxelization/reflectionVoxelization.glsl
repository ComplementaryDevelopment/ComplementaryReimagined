#if COLORED_LIGHTING < 512
    const ivec3 sceneVoxelVolumeSize = ivec3(COLORED_LIGHTING_INTERNAL, 64, COLORED_LIGHTING_INTERNAL);
#else
    const ivec3 sceneVoxelVolumeSize = ivec3(512, 64, 512);
#endif

vec3 playerToSceneVoxel(vec3 playerPos) {
    return playerPos + cameraPositionBestFract + 0.5 * vec3(sceneVoxelVolumeSize);
}

vec3 playerToPreviousSceneVoxel(vec3 previousPlayerPos) {
    return previousPlayerPos + previousCameraPositionBestFract + 0.5 * vec3(sceneVoxelVolumeSize);
}

#include "/lib/voxelization/reflectionVoxelData.glsl"

bool CheckInsideSceneVoxelVolume(vec3 voxelPos) {
    #ifndef SHADOW
        voxelPos -= 0.5 * sceneVoxelVolumeSize;
        voxelPos += sign(voxelPos) * 0.95;
        voxelPos += 0.5 * sceneVoxelVolumeSize;
    #endif
    voxelPos /= vec3(sceneVoxelVolumeSize);
    return clamp01(voxelPos) == voxelPos;
}

#if defined SHADOW && defined VERTEX_SHADER
    void UpdateSceneVoxelMap(int mat, vec3 normal, vec3 position) {
        ivec3 eligibleStages = ivec3(
            MC_RENDER_STAGE_TERRAIN_SOLID,
            MC_RENDER_STAGE_TERRAIN_CUTOUT,
            MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED
        );

        if (!any(equal(ivec3(renderStage), eligibleStages))) return;

        vec3 viewPos  = mat3(gl_ModelViewMatrix) * (gl_Vertex.xyz + at_midBlock.xyz / 64.0) + gl_ModelViewMatrix[3].xyz;
        vec3 scenePos = mat3(shadowModelViewInverse) * viewPos + shadowModelViewInverse[3].xyz;
        vec3 voxelPos = playerToSceneVoxel(scenePos);

        if (CheckInsideSceneVoxelVolume(voxelPos)) {
            bool doSolidBlockCheck = true;
            bool storeToAllFaces = false;
            bool storeToAllFacesExceptTop = false;
            uint matM = mat > 10 ? uint(mat) : 1u;
            vec2 textureRad = abs(texCoord - mc_midTexCoord.xy);
            vec2 origin = mc_midTexCoord.xy - textureRad;

            if (mat == 10132) { // Grass Block Regular
                if (texture2D(tex, mc_midTexCoord.xy).a < 0.5) return; // Grass Block Side Overlay
            }

            if (mat == 10009) { // Leaves
                doSolidBlockCheck = false;
            } 

            if (mat == 10129 // Farmland:Dry
                || mat == 10137 // Farmland:Wet
                || mat == 10493 // Dirt Path
            ) { 
                doSolidBlockCheck = false;
                textureRad *= 0.5;
                origin.y += 2.0 / atlasSize.y;
            } 

            if (mat == 10544 // Glow Lichen
                || mat == 10068 // Lava
            ) { 
                if (abs(dot(textureRad, vec2(atlasSize.x, -atlasSize.y))) < 4.5)
                    storeToAllFaces = true;
                else return;
            }
            
            // Half blocks that we want to display as full blocks in reflections
            if (mat == 10035 // Stone Bricks, Mossy Stone Bricks
                || abs(mat - 10095) <= 12 && mat % 4 == 3 // Stone, Smooth Stone, Granite, Diorite, Andesite, Bricks, Mud Bricks
                || mat == 10155 // Cobblestone, Mossy Cobblestone
                || abs(mat - 10191) <= 32 && mat % 8 == 7 // Oak, Spruce, Birch, Jungle, Acacia, DarkOak, Mangrove, Crimson, Warped
                || mat == 10111 // Cobbled Deepslate
                || mat == 10115 // Polished Deepslate, Deepslate Bricks, Deepslate Tiles
                || mat == 10243 // Sandstone
                || mat == 10247 // Red Sandstone
                || mat == 10295 // Copper
                || mat == 10367 // Quartz
                || mat == 10379 // Purpur
                || mat == 10381 // Powder Snow
                || mat == 10419 // Nether Bricks
                || mat == 10423 // Red Nether Bricks
                || mat == 10431 // End Stone Bricks
                || mat == 10443 // Prismarine, Prismarine Bricks
                || mat == 10447 // Dark Prismarine
                || mat == 10483 // Blackstone
                || mat == 10715 // Tuff
                || mat == 10759 // Bamboo, Bamboo Mosaic
                || mat == 10763 // Cherry
                || mat == 10931 // Pale Oak
                
            ) {
                if (textureRad.y < 5.0 / atlasSize.y) {
                    // Discarding if textureRad is too small to fix (somewhat rare) flickering on stairs
                    if (textureRad.x < 5.0 / atlasSize.x) return;

                    // Half textureRad for stairs and slabs to not overshoot their textures
                    textureRad *= 0.5;

                    // P.S: Don't ask me how any of these checks make sense because I have absolutely no idea either
                    // P.P.S: It seems like these checks only work well with default 16x textures but I don't have a better solution
                }

                doSolidBlockCheck = false;
                if (normal.y < 0.5) storeToAllFacesExceptTop = true; // Not overriding top face or else carpets look broken on top of slabs
            }

            if (mat == 10669 || mat == 10925 || mat == 10953) { // Wool Carpets, Moss Carpet, Snow Layers < 8
                if (normal.y > 0.5) {
                    voxelPos.y -= 1.0;
                    doSolidBlockCheck = false;
                } else return;
            }

            if (mat == 10072 || mat == 10076) { // Fire, Soul Fire
                doSolidBlockCheck = false;
                storeToAllFaces = true;
            }

            if (mat == 10652 || mat == 10656) { // Campfire:Lit, Soul Campfire:Lit
                if (abs(abs(normal.x) - 0.5) < 0.25) {
                    doSolidBlockCheck = false;
                    storeToAllFaces = true;
                } else return;
            }

            // Blocks to remove from reflections
            if (mat == 10056 // Lava Cauldron
                || mat == 10332 // Amethyst Clusters
                || mat == 10500 // End Rod
                || mat == 10508 // Chorus Flower:Alive
                || mat == 10512 // Chorus Flower:Dead
                || mat == 10556 // End Portal Frame:Active
                || mat == 10572 // Dragon Egg
                || mat == 10632 // Cave Vines
                || mat == 10776 // Crimson Fungus, Warped Fungus
                || mat == 10780 // Potted Crimson Fungus, Potted Warped Fungus
                || mat == 10836 // Brewing Stand
                || mat == 10884 // Weeping Vines
                || mat == 10972 // Firefly Bush
                || mat == 10976 // Open Eyeblossom
                || mat == 10980 // Potted Open Eyeblossom
                || abs(mat - 10562) <= 2 // Lantern & Soul Lantern
                || abs(mat - 10599) <= 3 // Redstone Wire
                || abs(mat - 10701) <= 3 // Non-Solid Sculk Stuff
                || abs(mat - 10786) <= 2 // Calibrated Sculk Sensor
                || abs(mat - 10911) <= 11 // Lit Candle Cakes
                || mat == 10988 // Copper Lantern
            ) {
                return;
            }

            if (doSolidBlockCheck) {
                if (
                    mat % 2 == 1 // Non-solids
                    || abs(mat - 5000) <= 4999 // Block entities that we treat as non-solid
                )
                return;
            }

            imageStore(wsr_img, ivec3(voxelPos), uvec4(matM, 0u, 0u, 0u));
            storeFaceData(ivec3(voxelPos), round(normal), origin, textureRad.x, storeToAllFaces, storeToAllFacesExceptTop, scenePos);

            float lodScale = 4.0;
            imageStore(wsr_img_lod, ivec3(voxelPos / lodScale), uvec4(1u, 0u, 0u, 0u));
        }
    }
#endif