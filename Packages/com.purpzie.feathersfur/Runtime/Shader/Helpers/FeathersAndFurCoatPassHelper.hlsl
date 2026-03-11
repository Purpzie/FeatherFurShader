#pragma once

#include "FeathersAndFurCommonHelper.hlsl"
#include "FeathersAndFurCardGenerationHelper.hlsl"
#include "FeathersAndFurLightingHelper.hlsl"
#include "FeathersAndFurForkHelper.hlsl"

//Structs ------------------------------------------------------------------------------------------

struct CoatPixelInput
{
    float4 rasterPosition : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 worldPosition : TEXCOORD1;
    float3 relativePositionToOccludingUnitSphere : TEXCOORD2;

    nointerpolation float2 baseUv : TEXCOORD3;
    nointerpolation float4 worldTangent : TEXCOORD4;
    nointerpolation uint flipbookFrame : TEXCOORD5;
    nointerpolation float selfShadowDensity : TEXCOORD6;

    UNITY_VERTEX_OUTPUT_STEREO
};

//Helpers ------------------------------------------------------------------------------------------

//apply the card detail color to the base coat color using one of a variety of blend modes
float3 BlendCardColor(float3 baseColor, float4 detailColor, uint blendMode)
{
    float3 compositedColor = baseColor;

    switch (blendMode)
    {
        case 0: //off
            compositedColor = baseColor;
            break;

        case 1: //override
            compositedColor = detailColor.rgb;
            break;

        case 2: //additive
            compositedColor = baseColor + detailColor.rgb;
            break;

        case 3: //subtractive
            compositedColor = baseColor - detailColor.rgb;
            break;

        case 4: //tint
            compositedColor = baseColor * detailColor.rgb;
            break;

        case 5: //alpha
            compositedColor = lerp(baseColor, detailColor.rgb, detailColor.a);
            break;

        case 6: //premultiplied alpha
            compositedColor = (baseColor * saturate(1.0 - detailColor.a)) + detailColor.rgb;
            break;
    }

    return compositedColor; //clamped to the valid range outside of this function
}

//apply the card detail material parameter to the base coat material parameter using one of a variety of blend modes
float BlendCardMaterialParameter(float baseValue, float detailValue, uint blendMode, float2 alphas)
{
    float compositedValue = baseValue;

    switch (blendMode)
    {
        case 0: //off
            compositedValue = baseValue;
            break;

        case 1: //override
            compositedValue = detailValue;
            break;

        case 2: //additive
            compositedValue = baseValue + detailValue;
            break;

        case 3: //subtractive
            compositedValue = baseValue - detailValue;
            break;

        case 4: //multiply
            compositedValue = baseValue * detailValue;
            break;

        case 5: //screen
            compositedValue = baseValue + detailValue - (detailValue * baseValue);
            break;

        case 6: //min
            compositedValue = min(baseValue, detailValue);
            break;

        case 7: //max
            compositedValue = max(baseValue, detailValue);
            break;

        case 8: //albedo alpha
            compositedValue = lerp(baseValue, detailValue, alphas.x);
            break;

        case 9: //emissive alpha
            compositedValue = lerp(baseValue, detailValue, alphas.y);
            break;
    }

    return saturate(compositedValue);
}

//Shader Functions ---------------------------------------------------------------------------------

[maxvertexcount(4)]
void CoatGeometryShader(point CardGenerationGeometryInput input[1], inout TriangleStream<CoatPixelInput> outputStream)
{
    CoatPixelInput output;
    UNITY_INITIALIZE_OUTPUT(CoatPixelInput, output);

    UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(input[0], output);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input[0]);

    [branch]
    if (IsMainCameraPass() && IsMirrored() && !_CardRenderInMirrors)
    {
        return; //don't draw cards in mirrors
    }

    CardGenerationInfo cardInfo;
    if (!GetCardGenerationInfo(input[0], cardInfo))
    {
        return;
    }

    //more perfomant to just sample this twice than to increase the size of the output strucct
    static const float cMinModelDiameter = 0.01;
    float4 additionalMaterialParameters = _CoatAdditionalMaterialParametersTexture.SampleLevel(sampler_CoatAdditionalMaterialParametersTexture, TRANSFORM_TEX(input[0].uv, _CoatAdditionalMaterialParametersTexture), 0.0);
    float modelDiameter = max(cMinModelDiameter, lerp(_CoatDiameterMin, _CoatDiameterMax, additionalMaterialParameters.g));

    //set parameters that are constant across the card

    output.baseUv = input[0].uv;
    output.flipbookFrame = cardInfo.flipbookIndex;
    output.worldTangent = float4(normalize(cardInfo.cardWidthAxis), 1.0) * (cardInfo.mirrorUvHorizontal ? -1.0 : 1.0);
    output.selfShadowDensity = cardInfo.selfShadowDensity;

    //build the card geometry
    for (uint y = 0; y < 2; y++)
    {
        for (uint x = 0; x < 2; x++)
        {
            output.uv.x = cardInfo.mirrorUvHorizontal ? (1 - x) : x;
            output.uv.y = y;

            output.worldPosition = input[0].worldPosition;
            output.worldPosition += cardInfo.cardLengthAxis * y;
            output.worldPosition += cardInfo.cardWidthAxis * (x - 0.5);

            output.rasterPosition = UnityWorldToClipPos(output.worldPosition);

            output.relativePositionToOccludingUnitSphere = cardInfo.selfShadowLengthAxis * y;
            output.relativePositionToOccludingUnitSphere += cardInfo.selfShadowWidthAxis * (x - 0.5);

            output.relativePositionToOccludingUnitSphere /= modelDiameter / 2.0;
            output.relativePositionToOccludingUnitSphere += cardInfo.baseSelfShadowNormal;

            outputStream.Append(output);
        }
    }
}

float4 CoatPixelShader(CoatPixelInput input, bool isFrontFace : SV_IsFrontFace) : SV_Target
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    float2 cardAtlasUv = GetCardTextureAtlasUv(input.uv, input.flipbookFrame);

    //the the distance fadeout ammount for this card
    float fadeFactor = GetFadeFactor(input.worldPosition);

#ifdef BASE_LIGHTING_PASS //only do the cutout on the base pass, otherwise we can just test if the depth is the same as the base pass
    float2 cardOpacityUv = _CardCutoutTextureAtlasEnabled ? cardAtlasUv : input.uv;
    float cardOpacity = _CardCutoutTexture.Sample(sampler_CardCutoutTexture, TRANSFORM_TEX(cardOpacityUv, _CardCutoutTexture)).a;

    float ditherValue = BayerDither16(input.rasterPosition.xy);

    if ((cardOpacity < _CardCutoutThreshold) || (fadeFactor < ditherValue))
    {
        discard;
    }
#endif

    //sample all the textures

    //sample albedo textures

    float3 baseAlbedo = 0.0;
    [branch]
    if (_CardAlbedoBlendMode != 1) //if the base albedo is used
    {
        baseAlbedo = _CoatAlbedoTexture.SampleLevel(sampler_CoatAlbedoTexture, TRANSFORM_TEX(input.baseUv, _CoatAlbedoTexture), 0.0).rgb;
    }

    float4 detailAlbedo = 0.0;
    [branch]
    if (_CardAlbedoBlendMode != 0) //if the detail texture is used
    {
        float2 cardAlbedoUv = _CardAlbedoTextureAtlasEnabled ? cardAtlasUv : input.uv;
        detailAlbedo = _CardAlbedoTexture.Sample(sampler_CardAlbedoTexture, TRANSFORM_TEX(cardAlbedoUv, _CardAlbedoTexture));
    }

    //sample emission textures

    float3 baseEmission = 0.0;
    #ifdef BASE_LIGHTING_PASS
    [branch]
    if (_CardEmissionBlendMode != 1)
    {
        baseEmission = _CoatEmissionTexture.SampleLevel(sampler_CoatEmissionTexture, TRANSFORM_TEX(input.baseUv, _CoatEmissionTexture), 0.0).rgb;
    }
    #ifdef _PURPZIE_GRYPHON_AUDIOLINK_ON
    baseEmission += PurpzieGryphonAudiolinkEmission(input.baseUv, baseAlbedo);
    #endif
    #endif

    float4 detailEmission = 0.0;
    #ifdef BASE_LIGHTING_PASS
    [branch]
    if (_CardEmissionBlendMode != 0)
    {
        float2 cardEmissionUv = _CardEmissionTextureAtlasEnabled ? cardAtlasUv : input.uv;
        detailEmission = _CardEmissionTexture.Sample(sampler_CardEmissionTexture, TRANSFORM_TEX(cardEmissionUv, _CardEmissionTexture));
    }
    #endif

    //sample material paramter textures

    float4 baseMaterialParameters = 0.0;
    [branch]
    if (_CardRoughnessBlendMode != 1
        || _CardReflectivenessBlendMode != 1
        || _CardIridescentThicknessBlendMode != 1
        || _CardAmbientOcclusionBlendMode != 1) //if any of these blend modes is not a full override
    {
        baseMaterialParameters = _CoatMaterialParametersTexture.SampleLevel(sampler_CoatMaterialParametersTexture, TRANSFORM_TEX(input.baseUv, _CoatMaterialParametersTexture), 0.0);
    }

    float4 detailMaterialParameters = 0.0;
    [branch]
    if (_CardRoughnessBlendMode != 0
        || _CardReflectivenessBlendMode != 0
        || _CardIridescentThicknessBlendMode != 0
        || _CardAmbientOcclusionBlendMode != 0) //if the detail texture is used
    {
        float2 cardMaterialParametersUv = _CardMaterialParametersTextureAtlasEnabled ? cardAtlasUv : input.uv;
        detailMaterialParameters = _CardMaterialParametersTexture.Sample(sampler_CardMaterialParametersTexture, TRANSFORM_TEX(cardMaterialParametersUv, _CardMaterialParametersTexture));
    }

    //sample additional material parameter textures

    float4 additionalMaterialParameters = _CoatAdditionalMaterialParametersTexture.SampleLevel(sampler_CoatAdditionalMaterialParametersTexture, TRANSFORM_TEX(input.baseUv, _CoatAdditionalMaterialParametersTexture),0.0);

    //sample normal and anisotropy maps

    float2 cardNormalUv = _CardNormalTextureAtlasEnabled ? cardAtlasUv : input.uv;
    float4 normalMap = _CardNormalTexture.Sample(sampler_CardNormalTexture, TRANSFORM_TEX(cardNormalUv, _CardNormalTexture));

    float2 cardAnisotropyUv = _CardAnisotropyTextureAtlasEnabled ? cardAtlasUv : input.uv;
    float4 anisotropyMap = _CardAnisotropyTexture.Sample(sampler_CardAnisotropyTexture, TRANSFORM_TEX(cardAnisotropyUv, _CardAnisotropyTexture));
    if (all(anisotropyMap == 0.0))
    {
        //the anisotropy map value should only be 0 in all channels if it is the default texture, so override the default with something more appropriate
        anisotropyMap = float4(0.5, 1.0, 0.0, 1.0);
    }

    //process all the material inputs

    //tint and blend albedo

    baseAlbedo *= _CoatAlbedoTint.rgb;
    detailAlbedo *= _CardAlbedoTint;
    float3 albedo = saturate(BlendCardColor(baseAlbedo, detailAlbedo, _CardAlbedoBlendMode));

    //tint and blend emission

    baseEmission *= _CoatEmissionTint;
    detailEmission *= _CardEmissionTint;
    float3 emission = max(0.0, BlendCardColor(baseEmission, detailEmission, _CardEmissionBlendMode));

    //remap and blend material parameters

    float2 materialBlendAlphas = float2(detailAlbedo.a, detailEmission.a);

    float baseReflectiveness = saturate(lerp(_CoatReflectivenessMin, _CoatReflectivenessMax, baseMaterialParameters.r));
    float detailReflectiveness = saturate(lerp(_CardReflectivenessMin, _CardReflectivenessMax, detailMaterialParameters.r));
    float reflectiveness = BlendCardMaterialParameter(baseReflectiveness, detailReflectiveness, _CardReflectivenessBlendMode, materialBlendAlphas);

    float baseRoughness = saturate(lerp(_CoatRoughnessMin, _CoatRoughnessMax, baseMaterialParameters.g));
    float detailRoughness = saturate(lerp(_CardRoughnessMin, _CardRoughnessMax, detailMaterialParameters.g));
    float roughness = BlendCardMaterialParameter(baseRoughness, detailRoughness, _CardRoughnessBlendMode, materialBlendAlphas);
    roughness = PerceptualRoughnessToRoughness(roughness);

    float baseIridescentThickness = saturate(lerp(_CoatIridescentThicknessMin, _CoatIridescentThicknessMax, baseMaterialParameters.b));
    float detailIridescentThickness = saturate(lerp(_CardIridescentThicknessMin, _CardIridescentThicknessMax, detailMaterialParameters.b));
    float iridescentThickness = BlendCardMaterialParameter(baseIridescentThickness, detailIridescentThickness, _CardIridescentThicknessBlendMode, materialBlendAlphas);

    float baseAmbientOcclusion = saturate(lerp(_CoatAmbientOcclusionMin, _CoatAmbientOcclusionMax, baseMaterialParameters.a));
    float detailAmbientOcclusion = saturate(lerp(_CardAmbientOcclusionMin, _CardAmbientOcclusionMax, detailMaterialParameters.a));
    float ambientOcclusion = BlendCardMaterialParameter(baseAmbientOcclusion, detailAmbientOcclusion, _CardAmbientOcclusionBlendMode, materialBlendAlphas);

    //remap additional material parameters

    float furness = saturate(lerp(_CoatFurnessMin, _CoatFurnessMax, additionalMaterialParameters.r));
    float selfShadowStrength = saturate(lerp(_CoatSelfShadowMaskMin, _CoatSelfShadowMaskMax, additionalMaterialParameters.b));
    float ambientTransmissionOcclusion = saturate(lerp(_CoatAmbientTransmissionOcclusionMin, _CoatAmbientTransmissionOcclusionMax, additionalMaterialParameters.a));

    //calculate tangent space

    float3 worldNormal = normalize(cross(ddy(input.worldPosition), ddx(input.worldPosition)));
    float3 worldBitangent = cross(worldNormal, input.worldTangent.xyz) * input.worldTangent.w * unity_WorldTransformParams.w;
    worldBitangent = isFrontFace ? worldBitangent : -worldBitangent;

    LightingSurface surface = GetLightingSurface(worldNormal,
                                                 input.worldTangent.xyz,
                                                 worldBitangent,
                                                 normalMap,
                                                 _CardNormalStrength,
                                                 anisotropyMap,
                                                 _CardAnisotropyFlattenFurTangents,
                                                 _CardAnisotropyStrength,
                                                 _CardNormalFurInfluence);

    //calculate self shadowing parameters
    float2 selfShadowParams = HairGetSelfShadowTerms(input.uv.y,
                                                     input.selfShadowDensity * selfShadowStrength * fadeFactor,
                                                     input.relativePositionToOccludingUnitSphere);
    float3 selfShadowNormal = UnityObjectToWorldNormal(input.relativePositionToOccludingUnitSphere);

    //evaluate the material

    float3 lighting = GetFullLightingModel(input.worldPosition,
                                           surface.normal,
                                           surface.anisotropyStrength,
                                           surface.anisotropyTangent,
                                           surface.anisotropyBitangent,
                                           surface.hairTangent,
                                           albedo,
                                           emission,
                                           roughness,
                                           reflectiveness,
                                           iridescentThickness,
                                           ambientOcclusion,
                                           furness,
                                           selfShadowParams,
                                           selfShadowNormal,
                                           ambientTransmissionOcclusion,
                                           _CoatFurRootNormalDiffuseInfluence);

    return float4(lighting, 1.0);
}
