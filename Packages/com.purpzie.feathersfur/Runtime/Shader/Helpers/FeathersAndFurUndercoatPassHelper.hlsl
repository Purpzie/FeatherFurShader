#pragma once

#include "FeathersAndFurCommonHelper.hlsl"
#include "FeathersAndFurLightingHelper.hlsl"

//Structs ------------------------------------------------------------------------------------------

struct BaseVertexInput
{
    float3 position : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAl;
    float4 tangent : TANGENT;

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct BasePixelInput
{
    float4 rasterPosition : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 worldPosition : TEXCOORD1;
    float3 worldNormal : TEXCOORD2;
    float4 worldTangent : TEXCOORD3;

    UNITY_VERTEX_OUTPUT_STEREO
};

//Shader Functions ---------------------------------------------------------------------------------

BasePixelInput BaseVertexShader(BaseVertexInput input)
{
    BasePixelInput output;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_INITIALIZE_OUTPUT(BasePixelInput, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    output.uv = input.uv;

    output.worldPosition = mul(unity_ObjectToWorld, float4(input.position, 1.0));
    output.rasterPosition = UnityWorldToClipPos(output.worldPosition);

    output.worldNormal = UnityObjectToWorldNormal(input.normal);
    output.worldTangent.xyz = UnityObjectToWorldDir(input.tangent.xyz);
    output.worldTangent.w = input.tangent.w;

    return output;
}

float4 BasePixelShader(BasePixelInput input, bool isFrontFace : SV_IsFrontFace) : SV_Target
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    //get cutout parameters

    float4 colorAndAlpha = _UndercoatAlbedoTexture.Sample(sampler_UndercoatAlbedoTexture, TRANSFORM_TEX(input.uv, _UndercoatAlbedoTexture));
    float2 clothingMask = GetClothingMask(input.uv);

#ifdef BASE_LIGHTING_PASS //only do the cutout on the base pass, otherwise we can just test if the depth is the same as the base pass
    if((_UndercoatCutoutEnabled && colorAndAlpha.a < _UndercoatCutoutThreshold) || (clothingMask.y < _ClothingMaskCutoutThreshold))
    {
        discard;
    }
#endif //BASE_LIGHTING_PASS

    //get albedo

    float3 albedo = colorAndAlpha.rgb * _UndercoatAlbedoTint;

    //get emission

    #ifdef BASE_LIGHTING_PASS
    float3 emission = _UndercoatEmissionTexture.Sample(sampler_UndercoatEmissionTexture, TRANSFORM_TEX(input.uv, _UndercoatEmissionTexture)).rgb * _UndercoatEmissionTint;
    #else
    float3 emission = 0;
    #endif

    //get material parameters

    float4 materialParameters = _UndercoatMaterialParametersTexture.Sample(sampler_UndercoatMaterialParametersTexture, TRANSFORM_TEX(input.uv, _UndercoatMaterialParametersTexture));

    float reflectiveness = saturate(lerp(_UndercoatReflectivenessMin, _UndercoatReflectivenessMax, materialParameters.r));
    float roughness = PerceptualRoughnessToRoughness(saturate(lerp(_UndercoatRoughnessMin, _UndercoatRoughnessMax, materialParameters.g)));
    float iridescentThickness = saturate(lerp(_UndercoatIridescentThicknessMin, _UndercoatIridescentThicknessMax, materialParameters.b));
    float ambientOcclusion = saturate(lerp(_UndercoatAmbientOcclusionMin, _UndercoatAmbientOcclusionMax, materialParameters.a));

    //get additional material parameters

    float4 additionalMaterialParameters = _UndercoatAdditionalMaterialParametersTexture.Sample(sampler_UndercoatAdditionalMaterialParametersTexture, TRANSFORM_TEX(input.uv, _UndercoatAdditionalMaterialParametersTexture));
    float4 coatParameters = _CoatParametersTexture.SampleLevel(sampler_CoatParametersTexture, TRANSFORM_TEX(input.uv, _CoatParametersTexture), 0.0);

    float furness = saturate(lerp(_UndercoatFurnessMin, _UndercoatFurnessMax, _UndercoatFurnessReadCoatParametersMask ? coatParameters.a : additionalMaterialParameters.r));
    float selfShadowStrength = saturate(lerp(_UndercoatSelfShadowMaskMin, _UndercoatSelfShadowMaskMax, additionalMaterialParameters.b));
    float ambientTransmissionOcclusion = saturate(lerp(_UndercoatAmbientTransmissionOcclusionMin, _UndercoatAmbientTransmissionOcclusionMax, additionalMaterialParameters.a));

    //get normal and anisotropy maps

    float4 normalMap = _UndercoatNormalTexture.Sample(sampler_UndercoatNormalTexture, TRANSFORM_TEX(input.uv, _UndercoatNormalTexture));
    float4 anisotropyMap = _UndercoatAnisotropyTexture.Sample(sampler_UndercoatAnisotropyTexture, TRANSFORM_TEX(input.uv, _UndercoatAnisotropyTexture));

    //calculate tangent space

    float3 backfaceCorrectedWorldNormal = isFrontFace ? input.worldNormal : -input.worldNormal;
    float3 worldBitangent = cross(input.worldNormal, input.worldTangent.xyz) * input.worldTangent.w * unity_WorldTransformParams.w;

    LightingSurface surface = GetLightingSurface(backfaceCorrectedWorldNormal,
                                                 input.worldTangent.xyz,
                                                 worldBitangent,
                                                 normalMap,
                                                 _UndercoatNormalStrength,
                                                 anisotropyMap,
                                                 _UndercoatAnisotropyFlattenFurTangents,
                                                 _UndercoatAnisotropyStrength,
                                                 _UndercoatNormalFurInfluence);

    //get self shadowing paraameters

    float cardSpacing = GetCardSpacing(coatParameters.x);
    float2 cardSize = GetCardShape(coatParameters.x) * cardSpacing;
    float coatDensity = coatParameters.w * clothingMask.x * cardSize.x * cardSize.y / (cardSpacing * cardSpacing);

    float2 selfShadowParams = HairGetSelfShadowTerms(0.0, coatDensity * selfShadowStrength * GetFadeFactor(input.worldPosition), 0.0);

    float3 selfShadowNormal = UnpackNormalWithScale(_UndercoatFurRootNormalTexture.Sample(sampler_UndercoatFurRootNormalTexture, TRANSFORM_TEX(input.uv, _UndercoatFurRootNormalTexture)), _UndercoatFurRootNormalStrength);
    selfShadowNormal = (selfShadowNormal.x * input.worldTangent.xyz)
                     + (selfShadowNormal.y * worldBitangent)
                     + (selfShadowNormal.z * input.worldNormal);
    selfShadowNormal = normalize(selfShadowNormal);

    //evaluate lighting
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
                                           _UndercoatFurRootNormalDiffuseInfluence);

    return float4(lighting, 1.0);
}
