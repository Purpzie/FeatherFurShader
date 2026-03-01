#pragma once

#include "FeathersAndFurCommonHelper.hlsl"
#include "FeathersAndFurCardGenerationHelper.hlsl"

//Structs ------------------------------------------------------------------------------------------

struct ShadowPixelInput
{
    V2F_SHADOW_CASTER;

    float3 worldPosition : TEXCOORD2;
    float2 uv : TEXCOORD4;
    nointerpolation uint flipbookFrame : TEXCOORD5;
    nointerpolation bool isCard : TEXCOORD6;

    UNITY_VERTEX_OUTPUT_STEREO
};

//Helpers ------------------------------------------------------------------------------------------

//set the builtin values from V2F_SHADOW_CASTER in the pixel input struct for cards
void SetBuiltinShadowcasterValuesForCard(float3 worldPosition, float3 worldNormal, bool isShadowPass, inout ShadowPixelInput output)
{
#if !defined(SHADOWS_CUBE) || defined(SHADOWS_CUBE_IN_DEPTH_TEX)
    worldPosition = WorldSpaceShadowCasterPos(worldPosition, worldNormal);
#endif

    //add a bias away from the light in shadowcaster passes
    if (isShadowPass)
    {
        bool isOrthographic = UNITY_MATRIX_P._m33 != 0.0;
        float3 biasDirection = isOrthographic ? -UNITY_MATRIX_I_V._m02_m12_m22 : worldPosition - UNITY_MATRIX_I_V._m03_m13_m23;
        worldPosition += normalize(biasDirection) * _CardShadowBias;
    }

    output.pos = UnityWorldToClipPos(worldPosition);

    //recreate functionality of TRANSFER_SHADOW_CASTER_NORMALOFFSET
#if defined(SHADOWS_CUBE) && !defined(SHADOWS_CUBE_IN_DEPTH_TEX)
    output.vec = worldPosition - _LightPositionRange.xyz;
#else
    output.pos = UnityApplyLinearShadowBias(output.pos);
#endif
}

//set the builtin values from V2F_SHADOW_CASTER in the pixel input struct for the base triangle vertices
void SetBuiltinShadowcasterValuesForBaseVertex(float3 worldPosition, inout ShadowPixelInput output)
{
    //WorldSpaceShadowCasterPos() was already applied to world position in the domain shader for the base triangle
    output.pos = UnityWorldToClipPos(worldPosition);

    //recreate functionality of TRANSFER_SHADOW_CASTER_NORMALOFFSET
#if defined(SHADOWS_CUBE) && !defined(SHADOWS_CUBE_IN_DEPTH_TEX)
    output.vec = worldPosition - _LightPositionRange.xyz;
#else
    output.pos = UnityApplyLinearShadowBias(output.pos);
#endif
}

//Shader Functions ---------------------------------------------------------------------------------

[maxvertexcount(4)]
void ShadowGeometryShader(point CardGenerationGeometryInput input[1], inout TriangleStream<ShadowPixelInput> outputStream)
{
    ShadowPixelInput output;
    UNITY_INITIALIZE_OUTPUT(ShadowPixelInput, output);

    UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(input[0], output);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input[0]);

    //special case for the vertex that is passing in the base triangle's shadow  caster position
    if (input[0].cardIndex == cDepthPassBaseTriangleIndex)
    {
        //non-interpolated values

        output.worldPosition = 0.0; //unused
        output.flipbookFrame = 0; //unused
        output.isCard = false;

        //first vertex

        SetBuiltinShadowcasterValuesForBaseVertex(input[0].worldPosition, output);
        output.uv = input[0].uv;

        outputStream.Append(output);

        //second vertex

        SetBuiltinShadowcasterValuesForBaseVertex(input[0].normal, output); //second vertex's world position is stored in the normal
        output.uv = float2(input[0].tangent.w, input[0].skinnedMeshScale); //unpack uv
        
        outputStream.Append(output);

        //third vertex

        SetBuiltinShadowcasterValuesForBaseVertex(input[0].tangent.xyz, output); //third vertex's world position is stored in the tangent
        output.uv = float2(input[0].sourceTriangleArea, input[0].sourceTriangleHash); //unpack uv
        
        outputStream.Append(output);

        return; //once the base triangle has been recreated this case is done
    }

    bool isShadowPass = !IsMainCameraPass();

    [branch]
    if ((isShadowPass && !_CardRenderInShadows) //only create base triangle in shadowcaster passes if cards are disabled in shadows
        || (!isShadowPass && IsMirrored() && !_CardRenderInMirrors)) //don't create cards in mirrors if cards are disabled in mirrors
    {
        return;
    }

    CardGenerationInfo cardInfo;
    if (!GetCardGenerationInfo(input[0], cardInfo))
    {
        return;
    }

    float3 worldNormal = normalize(cross(cardInfo.cardWidthAxis, cardInfo.cardLengthAxis)) * unity_WorldTransformParams.w;

    //non-interpolated values
    output.flipbookFrame = cardInfo.flipbookIndex;
    output.isCard = true;

    //build the card geometry
    for (uint y = 0; y < 2; y++)
    {
        for (uint x = 0; x < 2; x++)
        {
            output.uv.x = cardInfo.mirrorUvHorizontal ? (1 - x) : x;
            output.uv.y = y;

            output.worldPosition = input[0].worldPosition;
            output.worldPosition += cardInfo.cardWidthAxis * (x - 0.5);
            output.worldPosition += cardInfo.cardLengthAxis * y;

            SetBuiltinShadowcasterValuesForCard(output.worldPosition, worldNormal, isShadowPass, output);

            outputStream.Append(output);
        }
    }
}

float4 ShadowPixelShader(ShadowPixelInput input, bool isFrontFace : SV_IsFrontFace) : SV_Target
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
    
    //do different pixel discards for the cards and the base mesh to match the respective behaviors in the main passes
    [branch]
    if (input.isCard)
    {
        //card cutout
        float2 cardAtlasUv = GetCardTextureAtlasUv(input.uv, input.flipbookFrame);
        float2 cardOpacityUv = _CardCutoutTextureAtlasEnabled ? cardAtlasUv : input.uv;
        float opacity = _CardCutoutTexture.Sample(sampler_CardCutoutTexture, TRANSFORM_TEX(cardOpacityUv, _CardCutoutTexture)).a;

        //distance fade
        float fadeFactor = GetFadeFactor(input.worldPosition);
        float ditherValue = BayerDither16(input.pos.xy);

        if ((opacity < _CardCutoutThreshold) || (fadeFactor < ditherValue))
        {
            discard;
        }
    }
    else
    {
        //backface culling is disabled because the cards need it off, so for the base triangle do it manually instead
        uint cullMode = IsMainCameraPass() ? _UndercoatCullMode : _UndercoatShadowCullMode;
        bool cullFace = isFrontFace ? cullMode == 1 : cullMode == 2;

        //base opacity cutout
        float opacity = _UndercoatAlbedoTexture.Sample(sampler_UndercoatAlbedoTexture, TRANSFORM_TEX(input.uv, _UndercoatAlbedoTexture)).a;

        //clothing mask cutout
        float clothingMask = GetClothingMask(input.uv).y;

        if (cullFace || (_UndercoatCutoutEnabled && opacity < _UndercoatCutoutThreshold) || (clothingMask < _ClothingMaskCutoutThreshold))
        {
            discard;
        }
    }

    SHADOW_CASTER_FRAGMENT(input);
}