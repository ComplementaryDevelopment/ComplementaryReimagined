/*
--------------------------------------------------------------------------------

  GLSL Debug Text Renderer by SixthSurge (updated 2023-04-08)

  Character set based on Monocraft by IdreesInc
  https://github.com/IdreesInc/Monocraft

  With additional characters added by WoMspace

  Usage:

  // Call beginText to initialize the text renderer. You can scale the fragment position to adjust the size of the text
  beginText(ivec2(gl_FragCoord.xy), ivec2(0, viewHeight));
            ^ fragment position     ^ text box position (upper left corner)

  // You can print various data types
  printBool(false);
  printFloat(sqrt(-1.0)); // Prints "NaN"
  printInt(42);
  printVec3(skyColor);

  // ...or arbitrarily long strings
  printString((_H, _e, _l, _l, _o, _comma, _space, _w, _o, _r, _l, _d));

  // To start a new line, use
  printLine();

  // You can also configure the text color on the fly
  text.fgCol = vec4(1.0, 0.0, 0.0, 1.0);
  text.bgCol = vec4(0.0, 0.0, 0.0, 1.0);

  // ...as well as the number base and number of decimal places to print
  text.base = 16;
  text.fpPrecision = 4;

  // Finally, call endText to blend the current fragment color with the text
  endText(fragColor);

  Important: any variables you display must be the same for all fragments, or
  at least all of the fragments that the text covers. Otherwise, different
  fragments will try to print different values, resulting in, well, a mess

--------------------------------------------------------------------------------
*/

#if !defined UTILITY_TEXTRENDERING_INCLUDED
#define UTILITY_TEXTRENDERING_INCLUDED

// Characters

const uint _A     = 0x747f18c4u;
const uint _B     = 0xf47d18f8u;
const uint _C     = 0x746108b8u;
const uint _D     = 0xf46318f8u;
const uint _E     = 0xfc39087cu;
const uint _F     = 0xfc390840u;
const uint _G     = 0x7c2718b8u;
const uint _H     = 0x8c7f18c4u;
const uint _I     = 0x71084238u;
const uint _J     = 0x084218b8u;
const uint _K     = 0x8cb928c4u;
const uint _L     = 0x8421087cu;
const uint _M     = 0x8eeb18c4u;
const uint _N     = 0x8e6b38c4u;
const uint _O     = 0x746318b8u;
const uint _P     = 0xf47d0840u;
const uint _Q     = 0x74631934u;
const uint _R     = 0xf47d18c4u;
const uint _S     = 0x7c1c18b8u;
const uint _T     = 0xf9084210u;
const uint _U     = 0x8c6318b8u;
const uint _V     = 0x8c62a510u;
const uint _W     = 0x8c635dc4u;
const uint _X     = 0x8a88a8c4u;
const uint _Y     = 0x8a884210u;
const uint _Z     = 0xf844447cu;
const uint _a     = 0x0382f8bcu;
const uint _b     = 0x85b318f8u;
const uint _c     = 0x03a308b8u;
const uint _d     = 0x0b6718bcu;
const uint _e     = 0x03a3f83cu;
const uint _f     = 0x323c8420u;
const uint _g     = 0x03e2f0f8u;
const uint _h     = 0x842d98c4u;
const uint _i     = 0x40308418u;
const uint _j     = 0x080218b8u;
const uint _k     = 0x4254c524u;
const uint _l     = 0x6108420cu;
const uint _m     = 0x06ab5ac4u;
const uint _n     = 0x07a318c4u;
const uint _o     = 0x03a318b8u;
const uint _p     = 0x05b31f40u;
const uint _q     = 0x03671784u;
const uint _r     = 0x05b30840u;
const uint _s     = 0x03e0e0f8u;
const uint _t     = 0x211c420cu;
const uint _u     = 0x046318bcu;
const uint _v     = 0x04631510u;
const uint _w     = 0x04635abcu;
const uint _x     = 0x04544544u;
const uint _y     = 0x0462f0f8u;
const uint _z     = 0x07c4447cu;
const uint _0     = 0x746b58b8u;
const uint _1     = 0x23084238u;
const uint _2     = 0x744c88fcu;
const uint _3     = 0x744c18b8u;
const uint _4     = 0x19531f84u;
const uint _5     = 0xfc3c18b8u;
const uint _6     = 0x3221e8b8u;
const uint _7     = 0xfc422210u;
const uint _8     = 0x745d18b8u;
const uint _9     = 0x745e1130u;
const uint _space = 0x0000000u;
const uint _dot   = 0x000010u;
const uint _minus = 0x0000e000u;
const uint _comma = 0x00000220u;
const uint _colon = 0x02000020u;

// Additional characters added by WoMspace <3
const uint _under = 0x000007Cu;  // _
const uint _quote = 0x52800000u; // "
const uint _exclm = 0x21084010u; // !
const uint _gt    = 0x02082220u; // >
const uint _lt    = 0x00888208u; // <
const uint _opsqr = 0x3908421Cu; // [
const uint _clsqr = 0xE1084270u; // ]
const uint _opprn = 0x11084208u; // (
const uint _clprn = 0x41084220u; // )
const uint _block = 0xFFFFFFFCu; // █
const uint _copyr = 0x03AB9AB8u; // ©️

const int charWidth   = 5;
const int charHeight  = 6;
const int charSpacing = 1;
const int lineSpacing = 1;

const ivec2 charSize  = ivec2(charWidth, charHeight);
const ivec2 spaceSize = charSize + ivec2(charSpacing, lineSpacing);

// Text renderer

struct Text {
    vec4 result;     // Output color from the text renderer
    vec4 fgCol;      // Text foreground color
    vec4 bgCol;      // Text background color
    ivec2 fragPos;   // The position of the fragment (can be scaled to adjust the size of the text)
    ivec2 textPos;   // The position of the top-left corner of the text
    ivec2 charPos;   // The position of the next character in the text
    int base;        // Number base
    int fpPrecision; // Number of decimal places to print
} text;

// Fills the global text object with default values
void beginText(ivec2 fragPos, ivec2 textPos) {
    text.result      = vec4(0.0);
    text.fgCol       = vec4(1.0);
    text.bgCol       = vec4(0.0, 0.0, 0.0, 0.6);
    text.fragPos     = fragPos;
    text.textPos     = textPos;
    text.charPos     = ivec2(0);
    text.base        = 10;
    text.fpPrecision = 2;
}

// Applies the rendered text to the fragment
void endText(inout vec3 fragColor) {
    fragColor = mix(fragColor.rgb, text.result.rgb, text.result.a);
}

void printChar(uint character) {
    ivec2 pos = text.fragPos - text.textPos - spaceSize * text.charPos * ivec2(1, -1) + ivec2(0, spaceSize.y);

    uint index = uint(charWidth - pos.x + pos.y * charWidth + 1); // Edited

    // Draw background
    if (clamp(pos, ivec2(0), spaceSize - 1) == pos)
        text.result = mix(text.result, text.bgCol, text.bgCol.a);

    // Draw character
    if (clamp(pos, ivec2(0), charSize - 1) == pos)
        text.result = mix(text.result, text.fgCol, text.fgCol.a * float(character >> index & 1u));

    // Advance to next character
    text.charPos.x++;
}

#define printString(string) {                                               \
    uint[] characters = uint[] string;                                     \
    for (int i = 0; i < characters.length(); ++i) printChar(characters[i]); \
}

void printUnsignedInt(uint value, int len) {
    const uint[36] digits = uint[](
        _0, _1, _2, _3, _4, _5, _6, _7, _8, _9,
        _a, _b, _c, _d, _e, _f, _g, _h, _i, _j,
        _k, _l, _m, _n, _o, _p, _q, _r, _s, _t,
        _u, _v, _w, _x, _y, _z
    );

    // Advance to end of the number
    text.charPos.x += len - 1;

    // Write number backwards
    for (int i = 0; i < len; ++i) {
        printChar(digits[int(value) % text.base]); // Edited
        value /= uint(text.base); // Edited
        text.charPos.x -= 2;
    }

    // Return to end of the number
    text.charPos.x += len + 1;
}

void printUnsignedInt(uint value) {
    float logValue = log(float(value)) + 1e-6;
    float logBase  = log(float(text.base));

    int len = int(ceil(logValue / logBase));
        len = max(len, 1);

    printUnsignedInt(value, len);
}

void printInt(int value) {
    if (value < 0) printChar(_minus);
    printUnsignedInt(uint(abs(value)));
}

void printFloat(float value) {
    if (value < 0.0) printChar(_minus);

    if (isnan(value)) {
        printString((_N, _a, _N));
    } else if (isinf(value)) {
        printString((_i, _n, _f));
    } else {
        float i, f = modf(abs(value), i);

        uint integralPart   = uint(i);
        uint fractionalPart = uint(f * pow(float(text.base), float(text.fpPrecision)) + 0.5);

        printUnsignedInt(integralPart);
        printChar(_dot);
        printUnsignedInt(fractionalPart, text.fpPrecision);
    }
}

void printBool(bool value) {
    if (value) {
        printString((_t, _r, _u, _e));
    } else {
        printString((_f, _a, _l, _s, _e));
    }
}

void printVec2(vec2 value) {
    printFloat(value.x);
    printString((_comma, _space));
    printFloat(value.y);
}
void printVec3(vec3 value) {
    printFloat(value.x);
    printString((_comma, _space));
    printFloat(value.y);
    printString((_comma, _space));
    printFloat(value.z);
}
void printVec4(vec4 value) {
    printFloat(value.x);
    printString((_comma, _space));
    printFloat(value.y);
    printString((_comma, _space));
    printFloat(value.z);
    printString((_comma, _space));
    printFloat(value.w);
}

void printIvec2(ivec2 value) {
    printInt(value.x);
    printString((_comma, _space));
    printInt(value.y);
}
void printIvec3(ivec3 value) {
    printInt(value.x);
    printString((_comma, _space));
    printInt(value.y);
    printString((_comma, _space));
    printInt(value.z);
}
void printIvec4(ivec4 value) {
    printInt(value.x);
    printString((_comma, _space));
    printInt(value.y);
    printString((_comma, _space));
    printInt(value.z);
    printString((_comma, _space));
    printInt(value.w);
}

void printUvec2(uvec2 value) {
    printUnsignedInt(value.x);
    printString((_comma, _space));
    printUnsignedInt(value.y);
}
void printUvec3(uvec3 value) {
    printUnsignedInt(value.x);
    printString((_comma, _space));
    printUnsignedInt(value.y);
    printString((_comma, _space));
    printUnsignedInt(value.z);
}
void printUvec4(uvec4 value) {
    printUnsignedInt(value.x);
    printString((_comma, _space));
    printUnsignedInt(value.y);
    printString((_comma, _space));
    printUnsignedInt(value.z);
    printString((_comma, _space));
    printUnsignedInt(value.w);
}

void printLine() {
    text.charPos.x = 0;
    ++text.charPos.y;
}

#endif // UTILITY_TEXTRENDERING_INCLUDED