smoothnessG = (1.0 - pow(color.g, 64.0) * 0.3) * 0.4;
highlightMult = 2.0;

smoothnessD = smoothnessG;

DoBrightBlockTweaks(shadowMult, highlightMult);