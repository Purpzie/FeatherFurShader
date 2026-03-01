#pragma once

#include "UnityCG.cginc"

static const float cEpsilon = 0.000001;
static const float cPi = 3.14159265;
static const uint cDepthPassBaseTriangleIndex = ~0u;

//Shader Properties --------------------------------------------------------------------------------

Texture2D _CoatParametersTexture;
SamplerState sampler_CoatParametersTexture;
float4 _CoatParametersTexture_ST;

Texture2D _CoatDirectionTexture;
SamplerState sampler_CoatDirectionTexture;
float4 _CoatDirectionTexture_ST;

uint _CardAtlasTextureCount;
uint _CardAtlasTexturesPerRow;
Texture2D _CardCutoutTexture;
SamplerState sampler_CardCutoutTexture;
float4 _CardCutoutTexture_ST;
bool _CardCutoutTextureAtlasEnabled;
float _CardCutoutThreshold;

float _CardSizeMin;
float _CardSizeMax;

float _CardShapeLengthMin;
float _CardShapeLengthMax;
float _CardShapeLengthCurve;

float _CardShapeWidthMin;
float _CardShapeWidthMax;
float _CardShapeWidthCurve;

float _CardElevationMin;
float _CardElevationMax;
float _CardElevationRandomness;
float _CardOrientationRandomness;

float _CardRotationRandomnessMin;
float _CardRotationRandomnessMax;
float _CardRotationRandomnessElevationStart;
float _CardRotationRandomnessElevationEnd;

float _CardBillboardingMin;
float _CardBillboardingMax;
float _CardBillboardingElevationStart;
float _CardBillboardingElevationEnd;
float _CardBillboardingSizeStart;
float _CardBillboardingSizeEnd;

Texture2D _UndercoatAlbedoTexture;
SamplerState sampler_UndercoatAlbedoTexture;
float4 _UndercoatAlbedoTexture_ST;
float3 _UndercoatAlbedoTint;
bool _UndercoatCutoutEnabled;
float _UndercoatCutoutThreshold;

Texture2D _CoatAlbedoTexture;
SamplerState sampler_CoatAlbedoTexture;
float4 _CoatAlbedoTexture_ST;
float3 _CoatAlbedoTint;
bool _CoatCutoutEnabled;
float _CoatCutoutThreshold;

Texture2D _CardAlbedoTexture;
SamplerState sampler_CardAlbedoTexture;
float4 _CardAlbedoTexture_ST;
bool _CardAlbedoTextureAtlasEnabled;
float4 _CardAlbedoTint;
uint _CardAlbedoBlendMode;

Texture2D _UndercoatEmissionTexture;
SamplerState sampler_UndercoatEmissionTexture;
float4 _UndercoatEmissionTexture_ST;
float3 _UndercoatEmissionTint;

Texture2D _CoatEmissionTexture;
SamplerState sampler_CoatEmissionTexture;
float4 _CoatEmissionTexture_ST;
float3 _CoatEmissionTint;

Texture2D _CardEmissionTexture;
SamplerState sampler_CardEmissionTexture;
float4 _CardEmissionTexture_ST;
bool _CardEmissionTextureAtlasEnabled;
float4 _CardEmissionTint;
uint _CardEmissionBlendMode;

Texture2D _UndercoatMaterialParametersTexture;
SamplerState sampler_UndercoatMaterialParametersTexture;
float4 _UndercoatMaterialParametersTexture_ST;
float _UndercoatReflectivenessMin;
float _UndercoatReflectivenessMax;
float _UndercoatRoughnessMin;
float _UndercoatRoughnessMax;
float _UndercoatIridescentThicknessMin;
float _UndercoatIridescentThicknessMax;
float _UndercoatAmbientOcclusionMin;
float _UndercoatAmbientOcclusionMax;

Texture2D _CoatMaterialParametersTexture;
SamplerState sampler_CoatMaterialParametersTexture;
float4 _CoatMaterialParametersTexture_ST;
float _CoatReflectivenessMin;
float _CoatReflectivenessMax;
float _CoatRoughnessMin;
float _CoatRoughnessMax;
float _CoatIridescentThicknessMin;
float _CoatIridescentThicknessMax;
float _CoatAmbientOcclusionMin;
float _CoatAmbientOcclusionMax;

Texture2D _CardMaterialParametersTexture;
SamplerState sampler_CardMaterialParametersTexture;
float4 _CardMaterialParametersTexture_ST;
bool _CardMaterialParametersTextureAtlasEnabled;
float _CardReflectivenessMin;
float _CardReflectivenessMax;
uint _CardReflectivenessBlendMode;
float _CardRoughnessMin;
float _CardRoughnessMax;
uint _CardRoughnessBlendMode;
float _CardIridescentThicknessMin;
float _CardIridescentThicknessMax;
uint _CardIridescentThicknessBlendMode;
float _CardAmbientOcclusionMin;
float _CardAmbientOcclusionMax;
uint _CardAmbientOcclusionBlendMode;

Texture2D _UndercoatAdditionalMaterialParametersTexture;
SamplerState sampler_UndercoatAdditionalMaterialParametersTexture;
float4 _UndercoatAdditionalMaterialParametersTexture_ST;
bool _UndercoatFurnessReadCoatParametersMask;
float _UndercoatFurnessMin;
float _UndercoatFurnessMax;
float _UndercoatDiameterMin;
float _UndercoatDiameterMax;
float _UndercoatSelfShadowMaskMin;
float _UndercoatSelfShadowMaskMax;
float _UndercoatAmbientTransmissionOcclusionMin;
float _UndercoatAmbientTransmissionOcclusionMax;

Texture2D _CoatAdditionalMaterialParametersTexture;
SamplerState sampler_CoatAdditionalMaterialParametersTexture;
float4 _CoatAdditionalMaterialParametersTexture_ST;
float _CoatFurnessMin;
float _CoatFurnessMax;
float _CoatDiameterMin;
float _CoatDiameterMax;
float _CoatSelfShadowMaskMin;
float _CoatSelfShadowMaskMax;
float _CoatAmbientTransmissionOcclusionMin;
float _CoatAmbientTransmissionOcclusionMax;

Texture2D _UndercoatNormalTexture;
SamplerState sampler_UndercoatNormalTexture;
float4 _UndercoatNormalTexture_ST;
float _UndercoatNormalStrength;
float _UndercoatNormalFurInfluence;

Texture2D _UndercoatAnisotropyTexture;
SamplerState sampler_UndercoatAnisotropyTexture;
float4 _UndercoatAnisotropyTexture_ST;
float _UndercoatAnisotropyFlattenFurTangents;
float _UndercoatAnisotropyStrength;

Texture2D _UndercoatFurRootNormalTexture;
SamplerState sampler_UndercoatFurRootNormalTexture;
float4 _UndercoatFurRootNormalTexture_ST;
float _UndercoatFurRootNormalStrength;
float _UndercoatFurRootNormalDiffuseInfluence;

Texture2D _CoatFurRootNormalTexture;
SamplerState sampler_CoatFurRootNormalTexture;
float4 _CoatFurRootNormalTexture_ST;
float _CoatFurRootNormalStrength;
float _CoatFurRootNormalDiffuseInfluence;

Texture2D _CardNormalTexture;
SamplerState sampler_CardNormalTexture;
float4 _CardNormalTexture_ST;
bool _CardNormalTextureAtlasEnabled;
float _CardNormalStrength;
float _CardNormalFurInfluence;

Texture2D _CardAnisotropyTexture;
SamplerState sampler_CardAnisotropyTexture;
float4 _CardAnisotropyTexture_ST;
bool _CardAnisotropyTextureAtlasEnabled;
float _CardAnisotropyFlattenFurTangents;
float _CardAnisotropyStrength;

Texture2D _ClothingMaskFullTexture;
SamplerState sampler_ClothingMaskFullTexture;
float4 _ClothingMaskFullTexture_ST;
uint _ClothingMaskFullRedChannelMode;
uint _ClothingMaskFullGreenChannelMode;
uint _ClothingMaskFullBlueChannelMode;
uint _ClothingMaskFullAlphaChannelMode;

Texture2D<uint> _ClothingMaskPackedTexture;
float4 _ClothingMaskPackedTexture_ST;
float4 _ClothingMaskPackedTexture_TexelSize;
bool _ClothingMaskPackedUvWrapEnabled;
uint _ClothingMaskPacked0BitMode;
uint _ClothingMaskPacked1BitMode;
uint _ClothingMaskPacked2BitMode;
uint _ClothingMaskPacked3BitMode;
uint _ClothingMaskPacked4BitMode;
uint _ClothingMaskPacked5BitMode;
uint _ClothingMaskPacked6BitMode;
uint _ClothingMaskPacked7BitMode;
uint _ClothingMaskPacked8BitMode;
uint _ClothingMaskPacked9BitMode;
uint _ClothingMaskPacked10BitMode;
uint _ClothingMaskPacked11BitMode;
uint _ClothingMaskPacked12BitMode;
uint _ClothingMaskPacked13BitMode;
uint _ClothingMaskPacked14BitMode;
uint _ClothingMaskPacked15BitMode;
uint _ClothingMaskPacked16BitMode;
uint _ClothingMaskPacked17BitMode;
uint _ClothingMaskPacked18BitMode;
uint _ClothingMaskPacked19BitMode;
uint _ClothingMaskPacked20BitMode;
uint _ClothingMaskPacked21BitMode;
uint _ClothingMaskPacked22BitMode;
uint _ClothingMaskPacked23BitMode;
uint _ClothingMaskPacked24BitMode;
uint _ClothingMaskPacked25BitMode;
uint _ClothingMaskPacked26BitMode;
uint _ClothingMaskPacked27BitMode;
uint _ClothingMaskPacked28BitMode;
uint _ClothingMaskPacked29BitMode;
uint _ClothingMaskPacked30BitMode;
uint _ClothingMaskPacked31BitMode;

float _ClothingMaskCutoutThreshold;

float _SelfShadowColoredStrength;
float _SelfShadowUncoloredStrength;
float _SelfShadowCardTipOpacity;
float _SelfShadowNonFurStrengthMultiplier;

float _FurDirectLightingOcclusion;
float _FurShift;
float _FurRemapStart;
float _FurRemapEnd;
float _FurBaselineReflectiveness;
float _FurFresnelStrength;
Texture2D _FurIridescenceLUT;
SamplerState sampler_FurIridescenceLUT;

float _DiffuseRoughnessInfluence;
float _DiffuseRemapStart;
float _DiffuseRemapEnd;

float _SpecularBaselineReflectiveness;
float _SpecularFresnelStrength;
Texture2D _SpecularIridescenceLUT;
SamplerState sampler_SpecularIridescenceLUT;

uint _AmbientLightingOverrideMode;
float3 _AmbientLightingOverrideColor;
float _DiffuseAmbientLightingDirectionality;
float _FurAmbientLightingDirectionality;

bool _FurCustomReflectionProbeEnabled;
TextureCube _FurCustomReflectionProbe;
bool _FurCustomTransmissionProbeEnabled;
TextureCube _FurCustomTransmissionProbe;
bool _SpecularCustomReflectionProbeEnabled;
TextureCube _SpecularCustomReflectionProbe;

float _BrightnessClamp;

Texture2D _CoatOptimizationTexture;
float4 _CoatOptimizationTexture_TexelSize;
SamplerState sampler_PointRepeat;

float _CardLodFactor;
float _CardLodGrowth;
bool _CardLodFixedResolutionEnabled;
uint _CardLodFixedResolution;
float _CardLodSpacingMax;
float _CardLodSpacingMin;
float _CardLodShadowSpacingMin;

float _CardFadeStart;
float _CardFadeLength;

bool _CardRenderInMirrors;
bool _CardRenderInShadows;

bool _SkinnedMeshScaleFixupEnabled;
float3 _CardRescale;

uint _UndercoatCullMode;
uint _UndercoatShadowCullMode;
float _CardShadowBias;
uint _RandomSeed;

//Shared Helpers -----------------------------------------------------------------------------------

//get how much the cards should be fading out a a given position
float GetFadeFactor(float3 worldPos)
{
    //fading is disabled when start distance is negative
    if (_CardFadeStart < 0)
    {
        return 1.0;
    }

    //get the distance past the start of the fade
    float distance = length(worldPos - _WorldSpaceCameraPos);
    distance = max(0.0, distance - _CardFadeStart);

    //return the opacity of the card at this point
    return 1.0 - saturate(distance / max(cEpsilon, _CardFadeLength));
}

//get the distance between cards based on the size in the coat parameters
float GetCardSpacing(float sizeFactor)
{
    float cardSpacing = lerp(_CardSizeMin, _CardSizeMax, sizeFactor);
    return max(_CardSizeMin, cardSpacing);
}

//get the length and width of the card (relative to size) based on the size in the coat parameters
float2 GetCardShape(float sizeFactor)
{
    float lengthFactor = pow(sizeFactor, exp(-_CardShapeLengthCurve));
    float cardLength = lerp(_CardShapeLengthMin, _CardShapeLengthMax, lengthFactor);

    float widthFactor = pow(sizeFactor, exp(-_CardShapeWidthCurve));
    float cardWidth = lerp(_CardShapeWidthMin, _CardShapeWidthMax, widthFactor);

    return float2(cardWidth, cardLength);
}

//get the value of a 16 pixel wide Bayer dither pattern for the pixel at the given coordinate
float BayerDither16(uint2 coordinate)
{
    //the pattern repeats every 16 pixels so we only care about the lower 4 bits
    coordinate &= 0x0Fu;
    uint difference = coordinate.x ^ coordinate.y;

    //interleave values, only need to do it for the first byte as there are only 256 dither values
    uint value = 0;

    value |= (difference & 0x1u);
    value |= (difference & 0x2u) << 1;
    value |= (difference & 0x4u) << 2;
    value |= (difference & 0x8u) << 3;

    value |= (coordinate.x & 0x1u) << 1;
    value |= (coordinate.x & 0x2u) << 2;
    value |= (coordinate.x & 0x4u) << 3;
    value |= (coordinate.x & 0x8u) << 4;

    //invert the 1 byte value
    float dither = reversebits(value) >> 24;

    //return the final value as a float
    return saturate((dither + 0.5) / 256.0);
}

//merge the clothing mask mode for a given bit of the packed mask into a bitmask of active masks of each type
void MergeClothingBitmask(uint index, uint maskType, inout uint2 packedMaskModes)
{
    //1 if the mask is using the specified mode, 0 if not
    uint2 modeActive = (maskType == uint2(1, 2)) ? 1 : 0;
    
    //pack the state of this mode into the bitmask
    packedMaskModes |= modeActive << index;
}

//get the minimum mask values of all enabled clothing masks from both the full and packed textures
//x = card mask
//y = undercoat cutout mask
float2 GetClothingMask(float2 uv)
{
    float cardMask = 1.0;
    float undercoatMask = 1.0;

    //pack each of the individual full mask modes into a single uint4 for simplicity
    uint4 fullMaskModes = uint4(_ClothingMaskFullRedChannelMode,
                                _ClothingMaskFullGreenChannelMode,
                                _ClothingMaskFullBlueChannelMode,
                                _ClothingMaskFullAlphaChannelMode);
    
    //merge each of the individual packed mask modes into a set of bitmasks
    //x = all the hide card masks curently active
    //y = all the hide undercoat masks currently active
    //(it's not pretty but this way users can animate all the mask modes independently)
    uint2 packedMaskModes = 0;
    MergeClothingBitmask(0, _ClothingMaskPacked0BitMode, packedMaskModes);
    MergeClothingBitmask(1, _ClothingMaskPacked1BitMode, packedMaskModes);
    MergeClothingBitmask(2, _ClothingMaskPacked2BitMode, packedMaskModes);
    MergeClothingBitmask(3, _ClothingMaskPacked3BitMode, packedMaskModes);
    MergeClothingBitmask(4, _ClothingMaskPacked4BitMode, packedMaskModes);
    MergeClothingBitmask(5, _ClothingMaskPacked5BitMode, packedMaskModes);
    MergeClothingBitmask(6, _ClothingMaskPacked6BitMode, packedMaskModes);
    MergeClothingBitmask(7, _ClothingMaskPacked7BitMode, packedMaskModes);
    MergeClothingBitmask(8, _ClothingMaskPacked8BitMode, packedMaskModes);
    MergeClothingBitmask(9, _ClothingMaskPacked9BitMode, packedMaskModes);
    MergeClothingBitmask(10, _ClothingMaskPacked10BitMode, packedMaskModes);
    MergeClothingBitmask(11, _ClothingMaskPacked11BitMode, packedMaskModes);
    MergeClothingBitmask(12, _ClothingMaskPacked12BitMode, packedMaskModes);
    MergeClothingBitmask(13, _ClothingMaskPacked13BitMode, packedMaskModes);
    MergeClothingBitmask(14, _ClothingMaskPacked14BitMode, packedMaskModes);
    MergeClothingBitmask(15, _ClothingMaskPacked15BitMode, packedMaskModes);
    MergeClothingBitmask(16, _ClothingMaskPacked16BitMode, packedMaskModes);
    MergeClothingBitmask(17, _ClothingMaskPacked17BitMode, packedMaskModes);
    MergeClothingBitmask(18, _ClothingMaskPacked18BitMode, packedMaskModes);
    MergeClothingBitmask(19, _ClothingMaskPacked19BitMode, packedMaskModes);
    MergeClothingBitmask(20, _ClothingMaskPacked20BitMode, packedMaskModes);
    MergeClothingBitmask(21, _ClothingMaskPacked21BitMode, packedMaskModes);
    MergeClothingBitmask(22, _ClothingMaskPacked22BitMode, packedMaskModes);
    MergeClothingBitmask(23, _ClothingMaskPacked23BitMode, packedMaskModes);
    MergeClothingBitmask(24, _ClothingMaskPacked24BitMode, packedMaskModes);
    MergeClothingBitmask(25, _ClothingMaskPacked25BitMode, packedMaskModes);
    MergeClothingBitmask(26, _ClothingMaskPacked26BitMode, packedMaskModes);
    MergeClothingBitmask(27, _ClothingMaskPacked27BitMode, packedMaskModes);
    MergeClothingBitmask(28, _ClothingMaskPacked28BitMode, packedMaskModes);
    MergeClothingBitmask(29, _ClothingMaskPacked29BitMode, packedMaskModes);
    MergeClothingBitmask(30, _ClothingMaskPacked30BitMode, packedMaskModes);
    MergeClothingBitmask(31, _ClothingMaskPacked31BitMode, packedMaskModes);
    
    //evaluate the full clothing mask if any of it's mask modes are enabled
    [branch]
    if (any(fullMaskModes != 0))
    {
        float4 fullCloathingMask = _ClothingMaskFullTexture.SampleLevel(sampler_ClothingMaskFullTexture, TRANSFORM_TEX(uv, _ClothingMaskFullTexture), 0.0);

        //cards
        
        //set any disabled masks to 1 so they have no effect
        float4 activeCardMaskValues = fullMaskModes != 0 ? fullCloathingMask : 1.0;
        
        //get the minimum of all enabled masks
        cardMask = min(cardMask, activeCardMaskValues.x);
        cardMask = min(cardMask, activeCardMaskValues.y);
        cardMask = min(cardMask, activeCardMaskValues.z);
        cardMask = min(cardMask, activeCardMaskValues.w);
        
        //undercoat cutout
        
        //set any mask not using cutout mode to 1 so they have no effect
        float4 activeUndercoatMaskValues = fullMaskModes == 2 ? fullCloathingMask : 1.0;
        
        //get the minimum of all masks using cutout mode
        undercoatMask = min(undercoatMask, activeUndercoatMaskValues.x);
        undercoatMask = min(undercoatMask, activeUndercoatMaskValues.y);
        undercoatMask = min(undercoatMask, activeUndercoatMaskValues.z);
        undercoatMask = min(undercoatMask, activeUndercoatMaskValues.w);
    }

    //evaluate the packed clothing mask if any of it's mask modes are enabled
    [branch]
    if (any(packedMaskModes != 0))
    {
        float2 maskUv = TRANSFORM_TEX(uv, _ClothingMaskPackedTexture);
        maskUv = _ClothingMaskPackedUvWrapEnabled ? frac(maskUv) : saturate(maskUv);
        
        //calculate the coordinates of pixel at the given UV
        int3 maskPixelLocation = int3(maskUv * _ClothingMaskPackedTexture_TexelSize.zw, 0);
        maskPixelLocation.xy = clamp(maskPixelLocation.xy, 0.5, _ClothingMaskPackedTexture_TexelSize.zw - 0.5);
        
        //load the pixel value from the texture since integer texture types cannot be sampled
        uint clothingBitmask = _ClothingMaskPackedTexture.Load(maskPixelLocation);
        
        //if any masks are using card mode and have their bit set, hide the cards
        if ((clothingBitmask & packedMaskModes.x) != 0)
        {
            cardMask = 0.0;
        }
        
        //if any masks are using cutout mode and have their bit set, hide the cards and undercoat
        if ((clothingBitmask & packedMaskModes.y) != 0)
        {
            cardMask = 0.0;
            undercoatMask = 0.0;
        }
    }

    return saturate(float2(cardMask, undercoatMask));
}