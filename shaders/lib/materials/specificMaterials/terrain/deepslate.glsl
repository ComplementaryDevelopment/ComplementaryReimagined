smoothnessG = pow2(pow2(color.g)) * 4.0;
smoothnessG = min1(smoothnessG);
smoothnessD = smoothnessG;

/* Tweak to make caves with Glow Lichen look better lit and closer to vanilla Minecraft.
Builds using Deepslate generally don't look worse with this lightmap because Deepslate texture is very dark.*/
lmCoordM.x = pow(lmCoordM.x + 0.0001, 0.65);