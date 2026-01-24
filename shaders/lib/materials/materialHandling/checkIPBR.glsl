bool CheckIPBR() {
    #if defined(IPBR) && defined(CUSTOM_PBR)
        return texture2DLod(specular, texCoord, 1000.0) == vec4(0.0);
    #elif defined(IPBR)
        return true;
    #else
        return false;
    #endif
}
