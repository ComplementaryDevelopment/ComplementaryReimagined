if (textureRad.y < 5.0 / atlasSize.y) {
    // Discarding if textureRad is too small to fix (somewhat rare) flickering on stairs
    if (textureRad.x < 5.0 / atlasSize.x) return;

    // Half textureRad for stairs and slabs to not overshoot their textures
    textureRad *= 0.5;

    // P.S: Don't ask me how any of these checks make sense because I have absolutely no idea either
}

doSolidBlockCheck = false;
if (normal.y < 0.5) storeToAllFacesExceptTop = true; // Not overriding top face or else carpets look broken on top of slabs
