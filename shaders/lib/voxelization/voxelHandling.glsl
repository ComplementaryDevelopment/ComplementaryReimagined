// 10000 to 12047
if (mat < 11024) {
    if (mat < 10512) {
        if (mat < 10256) {
            if (mat < 10128) {
                if (mat < 10064) {
                    if (mat < 10032) {
                        if (mat < 10016) { // 10000 to 10015
                            if (mat == 10009) { // Leaves
                                doSolidBlockCheck = false;
                            }
                        } else { // 10016 to 10031
                        }
                    } else {
                        if (mat < 10048) { // 10032 to 10047
                            if (mat == 10035) { // Stone Bricks, Mossy Stone Bricks
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                        } else { // 10048 to 10063
                            if (mat == 10056) { // Lava Cauldron
                                return;
                            }
                        }
                    }
                } else {
                    if (mat < 10096) {
                        if (mat < 10080) { // 10064 to 10079
                            if (mat == 10068) { // Lava
                                if (abs(dot(textureRad, vec2(atlasSize.x, -atlasSize.y))) < 6.5)
                                    storeToAllFaces = true;
                                else return;
                            }
                            if (mat == 10072 || mat == 10076) { // Fire, Soul Fire
                                #include "/lib/voxelization/specificVoxelHandling/storeAllFacesOfCutout.glsl"
                            }
                        } else { // 10080 to 10095
                            if (mat % 4 == 3) { // Stone, Smooth Stone, Granite, Diorite, Andesite
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                        }
                    } else {
                        if (mat < 10112) { // 10096 to 10111
                            if (mat % 4 == 3) { // Polished Granite, Polished Diorite, Polished Andesite, Bricks, Cobbled Deepslate
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                        } else { // 10112 to 10127
                            if (mat == 10115 || mat == 10119) { // Polished Deepslate, Deepslate Bricks, Deepslate Tiles, Calcite, Polished Calcite
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                        }
                    }
                }
            } else {
                if (mat < 10192) {
                    if (mat < 10160) {
                        if (mat < 10144) { // 10128 to 10143
                            if (mat == 10132) { // Grass Block Regular
                                if (texture2D(tex, mc_midTexCoord.xy).a < 0.5) return; // Grass Block Side Overlay
                            }
                            if (mat == 10129 // Farmland:Dry
                                || mat == 10137 // Farmland:Wet
                            ) {
                                #include "/lib/voxelization/specificVoxelHandling/farmlandHandling.glsl"
                            }
                        } else { // 10144 to 10159
                            if (mat == 10155 || mat == 10159) { // Cobblestone, Oak Planks
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                        }
                    } else {
                        if (mat < 10176) { // 10160 to 10175
                            if (mat == 10167 || mat == 10175) { // Spruce Planks, Birch Planks
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                        } else { // 10176 to 10191
                            if (mat == 10183 || mat == 10191) { // Jungle Planks, Acacia Planks
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                        }
                    }
                } else {
                    if (mat < 10224) {
                        if (mat < 10208) { // 10192 to 10207
                            if (mat == 10199 || mat == 10207) { // Dark Oak Planks, Mangrove Planks
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                        } else { // 10208 to 10223
                            if (mat == 10215 || mat == 10223) { // Crimson Planks, Warped Planks
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                        }
                    } else {
                        if (mat < 10240) { // 10224 to 10239
                        } else { // 10240 to 10255
                            if (mat == 10243 || mat == 10247) { // Sandstone, Red Sandstone
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                        }
                    }
                }
            }
        } else {
            if (mat < 10384) {
                if (mat < 10320) {
                    if (mat < 10288) {
                        if (mat < 10272) { // 10256 to 10271
                        } else { // 10272 to 10287
                        }
                    } else {
                        if (mat < 10304) { // 10288 to 10303
                            if (mat == 10295) { // Copper
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                        } else { // 10304 to 10319
                        }
                    }
                } else {
                    if (mat < 10352) {
                        if (mat < 10336) { // 10320 to 10335
                            if (mat == 10332) { // Amethyst Clusters
                                #include "/lib/voxelization/specificVoxelHandling/storeAllFacesOfCutout.glsl"
                            }
                        } else { // 10336 to 10351
                        }
                    } else {
                        if (mat < 10368) { // 10352 to 10367
                            if (mat == 10367) { // Quartz
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                        } else { // 10368 to 10383
                            if (mat == 10379 || mat == 10383) { // Purpur, Powder Snow, Snow Bricks
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                        }
                    }
                }
            } else {
                if (mat < 10448) {
                    if (mat < 10416) {
                        if (mat < 10400) { // 10384 to 10399
                            if (mat == 10387) { // Packed Ice Bricks
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                        } else { // 10400 to 10415
                            if (mat == 10404) { // Sea Pickle
                                return;
                            }
                        }
                    } else {
                        if (mat < 10432) { // 10416 to 10431
                            if (mat % 4 == 3) { // Nether Bricks, Red Nether Bricks, End Stone Bricks
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                        } else { // 10432 to 10447
                            if (mat == 10443 || mat == 10447) { // Prismarine, Prismarine Bricks, Dark Prismarine
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                        }
                    }
                } else {
                    if (mat < 10480) {
                        if (mat < 10464) { // 10448 to 10463
                            if (mat == 10461) { // Concrete except lime
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                        } else { // 10464 to 10479
                        }
                    } else {
                        if (mat < 10496) { // 10480 to 10495
                            if (mat == 10483) { // Blackstone
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                            if (mat == 10493) { // Dirt Path
                                #include "/lib/voxelization/specificVoxelHandling/farmlandHandling.glsl"
                            }
                        } else { // 10496 to 10511
                            if (mat == 10496 || mat == 10500 || mat == 10508) { // Torch, End Rod, Chorus Flower:Alive
                                return;
                            }
                        }
                    }
                }
            }
        }
    } else {
        if (mat < 10768) {
            if (mat < 10640) {
                if (mat < 10576) {
                    if (mat < 10544) {
                        if (mat < 10528) { // 10512 to 10527
                            if (mat == 10512) { // Chorus Flower:Dead
                                return;
                            }
                        } else { // 10528 to 10543
                            if (mat == 10528) { // Soul Torch
                                return;
                            }
                        }
                    } else {
                        if (mat < 10560) { // 10544 to 10559
                            if (mat == 10544) { // Glow Lichen
                                #include "/lib/voxelization/specificVoxelHandling/storeAllFacesOfCutout.glsl"
                            }
                            if (mat == 10556) { // End Portal Frame:Active
                                return;
                            }
                        } else { // 10560 to 10575
                            { // Lantern, Soul Lantern, Dragon Egg
                                return;
                            }
                        }
                    }
                } else {
                    if (mat < 10608) {
                        if (mat < 10592) { // 10576 to 10591
                        } else { // 10592 to 10607
                            if (mat > 10592) { // Redstone Wire, Redstone Torch
                                return;
                            }
                        }
                    } else {
                        if (mat < 10624) { // 10608 to 10623
                        } else { // 10624 to 10639
                            if (mat == 10632) { // Cave Vines
                                return;
                            }
                        }
                    }
                }
            } else {
                if (mat < 10704) {
                    if (mat < 10672) {
                        if (mat < 10656) { // 10640 to 10655
                            if (mat == 10644) { // Powered Repeater, Powered Comparator
                                return;
                            }
                            if (mat == 10652) { // Campfire:Lit
                                #include "/lib/voxelization/specificVoxelHandling/campfireHandling.glsl"
                            }
                        } else { // 10656 to 10671
                            if (mat == 10656) { // Soul Campfire:Lit
                                #include "/lib/voxelization/specificVoxelHandling/campfireHandling.glsl"
                            }
                            if (mat == 10669) { // Wool Carpets except lime
                                #include "/lib/voxelization/specificVoxelHandling/carpetHandling.glsl"
                            }
                            if (mat == 10671) { // Wool except lime
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                        }
                    } else {
                        if (mat < 10688) { // 10672 to 10687
                        } else { // 10688 to 10703
                            if (mat == 10698 || mat == 10700) { // Some Non-Solid Sculk Stuff
                                return;
                            }
                        }
                    }
                } else {
                    if (mat < 10736) {
                        if (mat < 10720) { // 10704 to 10719
                            if (mat == 10704) { // Sculk Sensor:Active
                                return;
                            }
                            if (mat == 10715) { // Tuff
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                        } else { // 10720 to 10735
                        }
                    } else {
                        if (mat < 10752) { // 10736 to 10751
                        } else { // 10752 to 10767
                            if (mat == 10759) { // Bamboo, Bamboo Mosaic
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                            if (mat == 10763) { // Cherry
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                        }
                    }
                }
            }
        } else {
            if (mat < 10896) {
                if (mat < 10832) {
                    if (mat < 10800) {
                        if (mat < 10784) { // 10768 to 10783
                            if (mat == 10776 || mat == 10780) { // Crimson Fungus, Warped Fungus, Potted Crimson Fungus, Potted Warped Fungus
                                return;
                            }
                        } else { // 10784 to 10799
                            { // Calibrated Sculk Sensor
                                return;
                            }
                        }
                    } else {
                        if (mat < 10816) { // 10800 to 10815
                        } else { // 10816 to 10831
                        }
                    }
                } else {
                    if (mat < 10864) {
                        if (mat < 10848) { // 10832 to 10847
                            if (mat == 10836) { // Brewing Stand
                                return;
                            }
                            if (mat == 10841) { // Lime Concrete
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                            if (mat == 10845) { // Lime Carpet
                                #include "/lib/voxelization/specificVoxelHandling/carpetHandling.glsl"
                            }
                            if (mat == 10847) { // Lime Wool
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                        } else { // 10848 to 10863
                        }
                    } else {
                        if (mat < 10880) { // 10864 to 10879
                        } else { // 10880 to 10895
                            if (mat == 10884) { // Weeping Vines
                                return;
                            }
                        }
                    }
                }
            } else {
                if (mat < 10960) {
                    if (mat < 10928) {
                        if (mat < 10912) { // 10896 to 10911
                            { // Some Lit Candles & Candle Cakes
                                return;
                            }
                        } else { // 10912 to 10927
                            if (mat <= 10922) { // Remaining Lit Candles & Candle Cakes
                                return;
                            }
                            if (mat == 10925) { // Moss Carpet
                                #include "/lib/voxelization/specificVoxelHandling/carpetHandling.glsl"
                            }
                        }
                    } else {
                        if (mat < 10944) { // 10928 to 10943
                            if (mat == 10931) { // Pale Oak
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                            if (mat == 10943) { // Resin Bricks
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                        } else { // 10944 to 10959
                            if (mat == 10953) { // Snow Layers < 8
                                #include "/lib/voxelization/specificVoxelHandling/carpetHandling.glsl"
                            }
                        }
                    }
                } else {
                    if (mat < 10992) {
                        if (mat < 10976) { // 10960 to 10975
                            if (mat == 10972) { // Firefly Bush
                                return;
                            }
                        } else { // 10976 to 10991
                            { // Open Eyeblossom, Potted Open Eyeblossom, Copper Torch, Copper Lantern
                                return;
                            }
                        }
                    } else {
                        if (mat < 11008) { // 10992 to 11007
                            if (mat % 4 == 3) { // Sulfur, Polished Sulfur, Sulfur Bricks, Cinnabar, Polished Cinnabar, Cinnabar Bricks
                                #include "/lib/voxelization/specificVoxelHandling/turnHalfBlocksToFullBlocks.glsl"
                            }
                        } else { // 11008 to 11023
                            if (mat == 11012) { // Ice Crystal
                                return;
                            }
                        }
                    }
                }
            }
        }
    }
} else {
    if (mat < 11536) {
        if (mat < 11280) {
            if (mat < 11152) {
                if (mat < 11088) {
                    if (mat < 11056) {
                        if (mat < 11040) { // 11024 to 11039
                        } else { // 11040 to 11055
                        }
                    } else {
                        if (mat < 11072) { // 11056 to 11071
                        } else { // 11072 to 11087
                        }
                    }
                } else {
                    if (mat < 11120) {
                        if (mat < 11104) { // 11088 to 11103
                        } else { // 11104 to 11119
                        }
                    } else {
                        if (mat < 11136) { // 11120 to 11135
                        } else { // 11136 to 11151
                        }
                    }
                }
            } else {
                if (mat < 11216) {
                    if (mat < 11184) {
                        if (mat < 11168) { // 11152 to 11167
                        } else { // 11168 to 11183
                        }
                    } else {
                        if (mat < 11200) { // 11184 to 11199
                        } else { // 11200 to 11215
                        }
                    }
                } else {
                    if (mat < 11248) {
                        if (mat < 11232) { // 11216 to 11231
                        } else { // 11232 to 11247
                        }
                    } else {
                        if (mat < 11264) { // 11248 to 11263
                        } else { // 11264 to 11279
                        }
                    }
                }
            }
        } else {
            if (mat < 11408) {
                if (mat < 11344) {
                    if (mat < 11312) {
                        if (mat < 11296) { // 11280 to 11295
                        } else { // 11296 to 11311
                        }
                    } else {
                        if (mat < 11328) { // 11312 to 11327
                        } else { // 11328 to 11343
                        }
                    }
                } else {
                    if (mat < 11376) {
                        if (mat < 11360) { // 11344 to 11359
                        } else { // 11360 to 11375
                        }
                    } else {
                        if (mat < 11392) { // 11376 to 11391
                        } else { // 11392 to 11407
                        }
                    }
                }
            } else {
                if (mat < 11472) {
                    if (mat < 11440) {
                        if (mat < 11424) { // 11408 to 11423
                        } else { // 11424 to 11439
                        }
                    } else {
                        if (mat < 11456) { // 11440 to 11455
                        } else { // 11456 to 11471
                        }
                    }
                } else {
                    if (mat < 11504) {
                        if (mat < 11488) { // 11472 to 11487
                        } else { // 11488 to 11503
                        }
                    } else {
                        if (mat < 11520) { // 11504 to 11519
                        } else { // 11520 to 11535
                        }
                    }
                }
            }
        }
    } else {
        if (mat < 11792) {
            if (mat < 11664) {
                if (mat < 11600) {
                    if (mat < 11568) {
                        if (mat < 11552) { // 11536 to 11551
                        } else { // 11552 to 11567
                        }
                    } else {
                        if (mat < 11584) { // 11568 to 11583
                        } else { // 11584 to 11599
                        }
                    }
                } else {
                    if (mat < 11632) {
                        if (mat < 11616) { // 11600 to 11615
                        } else { // 11616 to 11631
                        }
                    } else {
                        if (mat < 11648) { // 11632 to 11647
                        } else { // 11648 to 11663
                        }
                    }
                }
            } else {
                if (mat < 11728) {
                    if (mat < 11696) {
                        if (mat < 11680) { // 11664 to 11679
                        } else { // 11680 to 11695
                        }
                    } else {
                        if (mat < 11712) { // 11696 to 11711
                        } else { // 11712 to 11727
                        }
                    }
                } else {
                    if (mat < 11760) {
                        if (mat < 11744) { // 11728 to 11743
                        } else { // 11744 to 11759
                        }
                    } else {
                        if (mat < 11776) { // 11760 to 11775
                        } else { // 11776 to 11791
                        }
                    }
                }
            }
        } else {
            if (mat < 11920) {
                if (mat < 11856) {
                    if (mat < 11824) {
                        if (mat < 11808) { // 11792 to 11807
                        } else { // 11808 to 11823
                        }
                    } else {
                        if (mat < 11840) { // 11824 to 11839
                        } else { // 11840 to 11855
                        }
                    }
                } else {
                    if (mat < 11888) {
                        if (mat < 11872) { // 11856 to 11871
                        } else { // 11872 to 11887
                        }
                    } else {
                        if (mat < 11904) { // 11888 to 11903
                        } else { // 11904 to 11919
                        }
                    }
                }
            } else {
                if (mat < 11984) {
                    if (mat < 11952) {
                        if (mat < 11936) { // 11920 to 11935
                        } else { // 11936 to 11951
                        }
                    } else {
                        if (mat < 11968) { // 11952 to 11967
                        } else { // 11968 to 11983
                        }
                    }
                } else {
                    if (mat < 12016) {
                        if (mat < 12000) { // 11984 to 11999
                        } else { // 12000 to 12015
                        }
                    } else {
                        if (mat < 12032) { // 12016 to 12031
                        } else { // 12032 to 12047
                        }
                    }
                }
            }
        }
    }
}
