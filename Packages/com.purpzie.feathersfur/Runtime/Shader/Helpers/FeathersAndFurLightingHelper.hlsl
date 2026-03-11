#pragma once

#include "FeathersAndFurCommonHelper.hlsl"
#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "FeathersAndFurForkHelper.hlsl"

//Structs ------------------------------------------------------------------------------------------

struct LightingSurface
{
    float3 normal;
    float anisotropyStrength;
    float3 anisotropyTangent;
    float3 anisotropyBitangent;
    float3 hairTangent;
};

//General Lighting Helpers -------------------------------------------------------------------------

//gets the perceptual luminance of a color
float3 GetLuminance(float3 color)
{
    return dot(color, float3(0.2126, 0.7152, 0.0722));
}

//clamps a color's luminance without affecting it's chromaticity
float3 ClampBrightness(float3 color)
{
    float luminance = GetLuminance(color);
    float renormalization = _BrightnessClamp > cEpsilon ? max(1.0, luminance / _BrightnessClamp) : 1.0;

    return color / renormalization;
}

//Fresnel with non-physical control over strength
inline float Fresnel(float nDotV, float reflectiveness, float fresnelStrength)
{
    //Schlick's approximation
    float fresnelFactor = pow(saturate(1.0 - nDotV), 5.0);

    return lerp(reflectiveness, 1.0, fresnelFactor * fresnelStrength);
}

//Non physically based remmapping of Lambert term for toon shading
float RemapLambert(float originalUnclampedLambert, float remapStart, float remapEnd)
{
    float range = max(0.0, remapEnd - remapStart);
    float remappedLambert = (originalUnclampedLambert - remapStart) / range;

    return abs(range) > cEpsilon ? remappedLambert : (originalUnclampedLambert >= remapStart ? 1.0 : -1.0);
}

//samples a given cubemap with Unity's roughness -> mip level encoding
float3 SampleReflectionProbe(TextureCube reflectionProbe, float3 reflectionVector, float roughness)
{
    //match the behavior in Unity_GlossyEnvironment
    float perceptualRoughness = RoughnessToPerceptualRoughness(roughness);
    perceptualRoughness = perceptualRoughness * (1.7 - (0.7 * perceptualRoughness));
    float mipLevel = perceptualRoughnessToMipmapLevel(perceptualRoughness);

    return reflectionProbe.SampleLevel(samplerunity_SpecCube0, reflectionVector, mipLevel).rgb;
}

//calculates all the normals and tangents that describe the shape of the surface
LightingSurface GetLightingSurface(float3 vertexNormal,
                                   float3 vertexTangent,
                                   float3 vertexBitangent,
                                   float4 normalMap,
                                   float normalStrength,
                                   float4 anisotropyMap,
                                   float flattenHairTangentsFactor,
                                   float anisotropyStrength,
                                   float hairNormalInfluence)
{
    LightingSurface surface;

    //convert normal map to world space

    float3 tangentSpaceNormal = UnpackNormalWithScale(normalMap, normalStrength);

    surface.normal = (vertexTangent * tangentSpaceNormal.x)
                   + (vertexBitangent * tangentSpaceNormal.y)
                   + (vertexNormal * tangentSpaceNormal.z);
    surface.normal = normalize(surface.normal);

    //get anisotropy values

    float3 tangentSpaceAnisotropyDirection = UnpackNormalmapRGorAG(anisotropyMap);

    surface.anisotropyStrength = length(tangentSpaceAnisotropyDirection.xy) * abs(anisotropyStrength);

    float3 anisotropyDirection = (vertexTangent * tangentSpaceAnisotropyDirection.x)
                               + (vertexBitangent * tangentSpaceAnisotropyDirection.y);
    anisotropyDirection = surface.anisotropyStrength > cEpsilon ? anisotropyDirection : vertexTangent;

    surface.anisotropyBitangent = normalize(cross(surface.normal, anisotropyDirection));
    surface.anisotropyTangent = normalize(cross(surface.anisotropyBitangent, surface.normal));

    //if anisotropy is negative, make anisotropy direction perpendicular to what it was
    if (anisotropyStrength < 0.0)
    {
        float3 temp = surface.anisotropyTangent;
        surface.anisotropyTangent = surface.anisotropyBitangent;
        surface.anisotropyBitangent = temp;
    }

    //get hair tangent

    float3 normalForHairAdjustment = UnpackNormalWithScale(normalMap, normalStrength * hairNormalInfluence);

    tangentSpaceAnisotropyDirection.z *= saturate(1.0 - flattenHairTangentsFactor);
    tangentSpaceAnisotropyDirection = length(tangentSpaceAnisotropyDirection) > cEpsilon
                                    ? normalize(tangentSpaceAnisotropyDirection)
                                    : float3(0.0, 1.0, 0.0);

    float anisotropyHorizontalLength = length(tangentSpaceAnisotropyDirection.xy);

    float2 horizontalAnisotropyDirection = tangentSpaceAnisotropyDirection.xy / anisotropyHorizontalLength; //normalized
    float3 hairPerpendicularDirection = float3(-horizontalAnisotropyDirection * tangentSpaceAnisotropyDirection.z, anisotropyHorizontalLength);
    float hairDirectionNormalOffset = -dot(horizontalAnisotropyDirection, normalForHairAdjustment.xy) / normalForHairAdjustment.z;

    float3 tangentSpaceHairDirection = normalize(tangentSpaceAnisotropyDirection + (hairPerpendicularDirection * hairDirectionNormalOffset));
    tangentSpaceHairDirection = normalForHairAdjustment.z > cEpsilon ? tangentSpaceHairDirection : hairPerpendicularDirection; //NaN prevention
    tangentSpaceHairDirection = anisotropyHorizontalLength > cEpsilon ? tangentSpaceHairDirection : normalForHairAdjustment; //NaN prevention

    surface.hairTangent = (vertexTangent * tangentSpaceHairDirection.x)
                        + (vertexBitangent * tangentSpaceHairDirection.y)
                        + (vertexNormal * tangentSpaceHairDirection.z);
    surface.hairTangent = normalize(surface.hairTangent);

    return surface;
}

//Unity Lighting Helpers ---------------------------------------------------------------------------

//Applies Unity's built in distance fog to a given color
float3 ApplyBuiltInFog(float3 color, float3 worldPos)
{
    //clip space depth
    float fogCoord = dot(float4(worldPos, 1.0), UNITY_MATRIX_VP[2]);

    UNITY_APPLY_FOG(fogCoord, color);
    return color;
}

//get the direction from a point to the current Unity light
float3 GetBuiltInLightDirection(float3 worldPos)
{
    return CacheLightDirection;
    //when _WorldSpaceLightPos0.w == 0 then _WorldSpaceLightPos0.xyz is a directional light direction
    //return (_WorldSpaceLightPos0.w < 0.5) ? normalize(_WorldSpaceLightPos0.xyz) : normalize(_WorldSpaceLightPos0.xyz - worldPos.xyz);
}

float3 GetBuiltInLightColor()
{
    return _LightColor0.rgb * cPi; //Unity's built in shaders implicitly multiply light strength by PI
}

//replicates Unity's built in light attenuation
float GetBuiltInLightAttenuation(float3 worldPos)
{
#if defined DIRECTIONAL
    return 1.0;
#elif defined POINT
    unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1.0)).xyz;
    return tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).r;
#elif defined SPOT
    unityShadowCoord4 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1.0));
    return (lightCoord.z > 0) * UnitySpotCookie(lightCoord) * UnitySpotAttenuate(lightCoord.xyz);
#elif defined DIRECTIONAL_COOKIE
    unityShadowCoord2 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1.0)).xy;
    return tex2D(_LightTexture0, lightCoord).w;
#elif defined POINT_COOKIE
    unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1.0)).xyz;
    return tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).r * texCUBE(_LightTexture0, lightCoord).w;
#else
    return 0.0;
#endif
}

//replicates Unity's built in real time shadows
float GetBuiltInLightRealtimeShadows(float3 worldPos)
{
    //fade value
    float zDist = dot(_WorldSpaceCameraPos - worldPos, UNITY_MATRIX_V[2].xyz);
    float fadeDist = UnityComputeShadowFadeDistance(worldPos, zDist);
    float realtimeToBakedShadowFade = UnityComputeShadowFade(fadeDist);

    float shadowAttenuation = 1.0f;

#if defined (SHADOWS_SCREEN)

    //directional light shadows
#if defined(UNITY_NO_SCREENSPACE_SHADOWS)
    shadowAttenuation = unitySampleShadow(mul(unity_WorldToShadow[0], unityShadowCoord4(worldPos, 1)));
#else
    float4 screenPos = ComputeScreenPos(UnityWorldToClipPos(worldPos));
    shadowAttenuation = unitySampleShadow(screenPos);
#endif

#else //defined (SHADOWS_SCREEN)

    //local light shadows
    [branch]
    if (realtimeToBakedShadowFade < (1.0 - cEpsilon))
    {
#if (defined (SHADOWS_DEPTH) && defined (SPOT))
        unityShadowCoord4 spotShadowCoord = mul(unity_WorldToShadow[0], unityShadowCoord4(worldPos, 1));
        shadowAttenuation = UnitySampleShadowmap(spotShadowCoord);
#elif defined (SHADOWS_CUBE)
        shadowAttenuation = UnitySampleShadowmap(worldPos - _LightPositionRange.xyz);
#endif
    }

#endif //defined (SHADOWS_SCREEN)

    return lerp(shadowAttenuation, 1.0, realtimeToBakedShadowFade);
}

//replicates Unity's built in ambient probe lighting, with additional options for override colors and directional strength
float3 GetBuiltInAmbientDiffuse(float3 worldPos, float3 normal, float directionality)
{
    //blends towards the average color as directionally decreaces
    float4 basis = float4(normal * saturate(directionality), 1.0);

    //matches Unity's per pixel ambient lighting
    float3 ambient = 0.0;
#if UNITY_LIGHT_PROBE_PROXY_VOLUME
    if (unity_ProbeVolumeParams.x == 1.0)
    {
        ambient = SHEvalLinearL0L1_SampleProbeVolume(basis, worldPos);
    }
    else
    {
        ambient = SHEvalLinearL0L1(basis);
    }
#else
    ambient = SHEvalLinearL0L1(basis);
#endif

    ambient += SHEvalLinearL2(basis);

    ambient = max(0.0, ambient);

#ifdef UNITY_COLORSPACE_GAMMA
    ambient = LinearToGammaSpace(ambient);
#endif

    //handle all color override options
    if (_AmbientLightingOverrideMode == 1) //override mode
    {
        return _AmbientLightingOverrideColor;
    }
    else if (_AmbientLightingOverrideMode == 2) //additive mode
    {
        ambient += _AmbientLightingOverrideColor;
    }
    else if (_AmbientLightingOverrideMode == 3) //per channel mode
    {
        ambient = max(_AmbientLightingOverrideColor, ambient);
    }
    else if (_AmbientLightingOverrideMode == 4) //luminance mode
    {
        float probeLuminance = GetLuminance(ambient);
        float minLuminance = GetLuminance(_AmbientLightingOverrideColor);
        float minAmbientFactor = saturate((minLuminance - probeLuminance) / minLuminance);

        ambient += _AmbientLightingOverrideColor * minAmbientFactor;
    }

    return max(0.0, ambient);
}

//replicates Unity's built in reflections
float3 SampleBuiltInReflectionProbes(float3 worldPos, float3 reflection, float roughness)
{
    UnityGIInput d;
    d.worldPos = worldPos;
    d.worldViewDir = 0.0; //unused

    //unity internal values
    d.probeHDR[0] = unity_SpecCube0_HDR;
    d.probeHDR[1] = unity_SpecCube1_HDR;
#if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
    d.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
#endif
#ifdef UNITY_SPECCUBE_BOX_PROJECTION
    d.boxMax[0] = unity_SpecCube0_BoxMax;
    d.probePosition[0] = unity_SpecCube0_ProbePosition;
    d.boxMax[1] = unity_SpecCube1_BoxMax;
    d.boxMin[1] = unity_SpecCube1_BoxMin;
    d.probePosition[1] = unity_SpecCube1_ProbePosition;
#endif

    Unity_GlossyEnvironmentData g;
    g.roughness = RoughnessToPerceptualRoughness(roughness);
    g.reflUVW = reflection;

    return UnityGI_IndirectSpecular(d, 1.0, g);
}

//Self Shadowing Helpers ---------------------------------------------------------------------------

//get the amount of light that can pass through a single strand of hair
float3 GetSelfShadowOpacity(float3 hairAbsorption, float hairReflectiveness, float furness = 1.0)
{
    float transmissionLength = cPi / 2.0; //average length of ray entering random position on fiber (with longitudinal angle canceled out)

    float3 transmission = saturate(exp(-hairAbsorption * transmissionLength));
    transmission *= 1.0 - hairReflectiveness;

    transmission *= furness; //non-hair doesn't let light though

    return saturate(1.0 - transmission);
}

//get the values used to approximate hair self shadowing
//x = the optical depth of the hair, assuming the hair is growing on a flat plane, looking in the direction of the plane's normal
//y = the greatest cosine between the light direction and relativePositionToOccludingUnitSphere where the light can reach the point without being occluded
float2 HairGetSelfShadowTerms(float lengthFactor, float coatDensity, float3 relativePositionToOccludingUnitSphere)
{
    //assumes card opacity linearly fades from 1 at the bottom to _SelfShadowCardTipOpacity at the tip
    //the elevation of the cards relative to the surface is irrelevant bacuse the shorter distance to
    //travel past them when they lay flat is counteracted by an inverse increase in density
    float opticalDepth = coatDensity * ((lengthFactor * lengthFactor * (1.0 - _SelfShadowCardTipOpacity)) + (lengthFactor * -2.0) + _SelfShadowCardTipOpacity + 1.0) / 2.0;

    float distanceFromCenter = max(1.0, length(relativePositionToOccludingUnitSphere));
    float lightWrapCos = saturate(sqrt((distanceFromCenter * distanceFromCenter) - 1.0) / distanceFromCenter);

    return float2(opticalDepth, lightWrapCos);
}

//returns how much light is able to reach this point after self shadowing from the fur
float3 GetSelfShadowing(float unclampedLambert, float3 selfShadowOpacity, float2 selfShadowTerms, float indirectRoughnessFactor = 0)
{
    //bias Lambert to wrap around the surface
    float biasedLambertTerm = saturate((unclampedLambert + selfShadowTerms.y) / (1.0 + selfShadowTerms.y));

    //when sampling indirect lighting the self shadowing would need to be integrated with the incoming light across the visible hemisphere
    //instead we aproximate by integrating this function across a cosine lobe and finding an optical depth multiplier
    //which matches the overall shadowing level most closely
    static const float cShadowCosineLobeMultiplier = 1.5825; //max error of 0.0234 of shadow strength vs using full integral in white furnace case

    float opticalDepth = selfShadowTerms.x * lerp(1.0, cShadowCosineLobeMultiplier, indirectRoughnessFactor);
    opticalDepth = max(0.0, opticalDepth / biasedLambertTerm); //the light passes though more hair at grazing angles

    float3 selfShadowAbsorption = (selfShadowOpacity * _SelfShadowColoredStrength) + _SelfShadowUncoloredStrength;

    return saturate(exp(-opticalDepth * selfShadowAbsorption)) * biasedLambertTerm;
}

//PBR Specular/Diffuse Helpers ---------------------------------------------------------------------

//Microfacet diffuse with non-physical controls to allow for simple cel shading
//Based on "Physically Based Shading at Disney" (https://media.disneyanimation.com/uploads/production/publication_asset/48/asset/s2012_pbs_disney_brdf_notes_v3.pdf)
float3 BurleyDiffuse(float3 lightDirection, float3 viewDirection, float3 normal, float3 halfNormal, float roughness)
{
    float nDotL = saturate(RemapLambert(dot(normal, lightDirection), _DiffuseRemapStart, _DiffuseRemapEnd));
    float nDotV = saturate(dot(normal, viewDirection));
    float lDotH = saturate(dot(lightDirection, halfNormal));

    float fresnelStrength = (2.0 * roughness * lDotH * lDotH) - 0.5;

    float incoming = 1.0 + (fresnelStrength * pow(1.0 - nDotL, 5.0)); //using the remapped Lambert looks better
    float outgoing = 1.0 + (fresnelStrength * pow(1.0 - nDotV, 5.0));

    float burleyScale = max(0.0, incoming * outgoing);
    burleyScale = lerp(1.0, burleyScale, _DiffuseRoughnessInfluence);

    return nDotL * burleyScale / cPi;
}

//energy conservation factor for diffuse lighting component
float GetDiffuseEnergyConservationFactor(float metalness)
{
    return lerp(1.0 - _SpecularBaselineReflectiveness, 0.0, metalness);
}

//the full PBR specular color, taking into account Fresnel and metalness
float3 GetSpecularColor(float lDotH, float3 metalColor, float metalness, float indirectRoughnessFactor = 0.0)
{
    float dielectricReflectiveness = Fresnel(lDotH, _SpecularBaselineReflectiveness, _SpecularFresnelStrength);

    //fade out Fresnel at high roughnesses to compensate for lack of full BRDF integration with cubemaps
    dielectricReflectiveness = lerp(dielectricReflectiveness, _SpecularBaselineReflectiveness, indirectRoughnessFactor);

    return lerp(dielectricReflectiveness, metalColor, metalness);
}

//Anisotropic GGX formulas based on "Physically Based Rendering in Filament"
//https://google.github.io/filament/Filament.md.html#materialsystem/anisotropicmodel

//anisotropic Trowbridge-Reitz distribution of microfacet normals
//uses two roughness terms, one for the tangent distribution and one for the bitangent distribution
float AnisotropicGGXDistributionTerm(float3 halfNormal, float3 normal, float3 tangent, float3 bitangent, float2 anisotropicRoughness)
{
    float a2 = anisotropicRoughness.x * anisotropicRoughness.y;

    float3 v = float3(dot(halfNormal, tangent), dot(halfNormal, bitangent), dot(halfNormal, normal))
             * float3(anisotropicRoughness.yx, a2);

    float denom = dot(v, v) / a2;
    denom = cPi * denom * denom;

    return all(anisotropicRoughness > cEpsilon) ? max(0.0, a2 / denom) : 0.0;
}

//Smith shadowing function (includes BRDF denominator)
float AnisotropicGGXGeometryTerm(float3 lightDirection, float3 viewDirection, float3 normal, float3 tangent, float3 bitangent, float2 anisotropicRoughness)
{
    float nDotL = saturate(dot(normal, lightDirection));
    float nDotV = saturate(dot(normal, viewDirection));

    float tDotL = dot(tangent, lightDirection);
    float bDotL = dot(bitangent, lightDirection);
    float lightTerm = nDotV * length(float3(anisotropicRoughness.x * tDotL, anisotropicRoughness.y * bDotL, nDotL));

    float tDotV = dot(tangent, viewDirection);
    float bDotV = dot(bitangent, viewDirection);
    float viewTerm = nDotL * length(float3(anisotropicRoughness.x * tDotV, anisotropicRoughness.y * bDotV, nDotV));

    float shadowing =  saturate(0.5 / (lightTerm + viewTerm));

    //multiscattering approximation from "Misunderstanding Multiscattering" (https://c0de517e.blogspot.com/2019/08/misunderstanding-multiscattering.html)
    float multiscattering = 1.0 + (2.0 * anisotropicRoughness.x * anisotropicRoughness.y * nDotV);

    return shadowing * multiscattering;
}

//Full equation for direct specular reflection
float3 AnisotropicGGX(float3 lightDirection, float3 viewDirection, float3 halfNormal, float3 surfaceNormal, float3 anisotropicTangent, float3 anisotropicBitangent, float2 anisotropicRoughness, float3 metalColor, float metalness)
{
    //distribution, geometry, BRDF denominator, and Lambert terms
    float specularHighlight = AnisotropicGGXDistributionTerm(halfNormal, surfaceNormal, anisotropicTangent, anisotropicBitangent, anisotropicRoughness)
                            * AnisotropicGGXGeometryTerm(lightDirection, viewDirection, surfaceNormal, anisotropicTangent, anisotropicBitangent, anisotropicRoughness)
                            * saturate(dot(lightDirection, surfaceNormal));

    //combine dielectric Fresnel and metallic reflection
    float lDotH = saturate(dot(lightDirection, halfNormal));
    float3 specularColor = GetSpecularColor(lDotH, metalColor, metalness);

    return specularHighlight * specularColor;
}

//creates warped reflection vector to approximate anisotropy with a cubemap reflections
float3 GetAnisotropicCumbemapReflectionVector(float3 normal, float3 viewDirection, float3 anisotropicBitangent, float anisotropy)
{
    static const float cMaxWarping = 0.75; //ad-hoc value

    float3 axis = cross(anisotropicBitangent, viewDirection);
    float3 anisotropicWarpedNormal = cross(axis, anisotropicBitangent);

    anisotropicWarpedNormal = normalize(lerp(normal, anisotropicWarpedNormal, abs(anisotropy) * cMaxWarping));

    return reflect(-viewDirection, anisotropicWarpedNormal);
}

//get iridescence from a look up texture based on the reflection angle and the iridescent film thickness
float3 SpecularIridescence(float lDotH, float iridescentThickness)
{
    //sample from left side of the texture when the light and view directions are aligned
    //sample from the right side when they are opposite
    float iridescenceAngle = saturate(1.0 - lDotH);

    return _SpecularIridescenceLUT.SampleLevel(sampler_SpecularIridescenceLUT, float2(iridescenceAngle, iridescentThickness), 0.0).rgb;
}

//full GGX/diffuse direct lighting model
float3 GetNonHairDirectLighting(float3 lightDirection,
                                float3 viewDirection,
                                float3 diffuseNormal,
                                float3 specularNormal,
                                float3 albedo,
                                float roughness,
                                float anisotropy,
                                float3 anisotropicTangent,
                                float3 anisotropicBitangent,
                                float metalness,
                                float iridescentThickness,
                                float3 lightColor)
{

    float3 halfNormal = normalize(lightDirection + viewDirection);
    float2 anisotropicRoughness = float2(roughness, roughness * (1.0 - anisotropy));
    float diffuseRoughness = sqrt(saturate(anisotropicRoughness.x * anisotropicRoughness.y));

    //diffuse lighting
    float3 diffuseLighting = BurleyDiffuse(lightDirection, viewDirection, diffuseNormal, halfNormal, diffuseRoughness);
    diffuseLighting *= albedo * GetDiffuseEnergyConservationFactor(metalness);

    //specular lighting
    float3 specularLighting = AnisotropicGGX(lightDirection, viewDirection, halfNormal, specularNormal, anisotropicTangent, anisotropicBitangent, anisotropicRoughness, albedo, metalness);
    specularLighting *= SpecularIridescence(dot(lightDirection, halfNormal), iridescentThickness);

    return diffuseLighting * lightColor + specularLighting * CacheSpecLightColor;
}

//full GGX/diffuse indirect  lighting model
float3 GetNonHairIndirectLighting(float3 worldPos, float3 viewDirection,
                                  float3 diffuseNormal, float3 specularNormal,
                                  float3 albedo, float3 anisotropicBitangent,
                                  float anisotropy, float roughness,
                                  float metalness, float iridescentThickness)
{
    //diffuse lighting
    float3 diffuseLighting = GetBuiltInAmbientDiffuse(worldPos, diffuseNormal, _DiffuseAmbientLightingDirectionality)
                           * albedo
                           * GetDiffuseEnergyConservationFactor(metalness);

    //specular lighting
    float3 reflectionVector = GetAnisotropicCumbemapReflectionVector(specularNormal, viewDirection, anisotropicBitangent, anisotropy);
    float nDotV = saturate(dot(specularNormal, viewDirection));

    float3 cubemapReflection = 0.0;
    if (_SpecularCustomReflectionProbeEnabled)
    {
        cubemapReflection = SampleReflectionProbe(_SpecularCustomReflectionProbe, reflectionVector, roughness);
    }
    else
    {
        cubemapReflection = SampleBuiltInReflectionProbes(worldPos, reflectionVector, roughness);
    }

    float3 specularLighting = GetSpecularColor(nDotV, albedo, metalness, roughness);
    specularLighting *= SpecularIridescence(nDotV, iridescentThickness);
    specularLighting *= cubemapReflection;

    return diffuseLighting + specularLighting;
}

//Hair Lighting Helpers ----------------------------------------------------------------------------

//get an absorbtion term for the hair fibers based on the desired final color after multiscattering
//based on "A Practical and Controllable Hair and Fur Model for Production Path Tracing" (https://benedikt-bitterli.me/pchfm/)
float3 HairAbsorptionFromAlbedo(float3 albedo)
{
    //5.969 - 0.215(B) + 2.532(B^2) - 10.73(B^3) + 5.574(B^4) + 0.245(B^5) where azimuthal roughness 'B' is 1.0
    static const float cAzimuthalRoughnessFactor = 3.375;

    float3 absorption = log(albedo) / cAzimuthalRoughnessFactor;
    absorption *= absorption;

    return max(0.0, absorption);
}

//hair Scattering functions based on "Physically Based Hair Shading in Unreal"
//https://blog.selfshadow.com/publications/s2016-shading-course/karis/s2016_pbs_epic_hair.pdf

//scattering in the direction of the hair fiber, shared for all scattering types
float HairLongitudinalScattering(float lightDotHair, float viewDotHair, float roughness, float shift)
{
    //the shift value represents the fact that hair folicals have a sawtooth like surface at the microscopic level,
    //and this along with refraction as light enters and exits the hair biases the reflection direction
    float power = lightDotHair + viewDotHair - shift;
    power = (power * power) / (2.0 * roughness * roughness);

    //normalize the scattering function
    return roughness > cEpsilon ? exp(-power) / (roughness * sqrt(2.0 * cPi)) : 0.0;
}

//scattering perpendicular to the hair fiber direction when light reflects of the surface without entering the hair
float3 HairRScattering(float cosHalfAzimuthalAngle)
{
    return cosHalfAzimuthalAngle / 4.0;
}

//scattering perpendicular to the hair fiber direction when light enters the fiber then reflects off the internal surface and exit back out
float3 HairTRTScattering(float cosAzimuthalAngle)
{
    return  exp((17.0 * cosAzimuthalAngle) - 16.78);
}

//scattering perpendicular to the hair fiber direction when light passes though the fiber
float3 HairTTScattering(float cosAzimuthalAngle)
{
    return exp((-3.65 * cosAzimuthalAngle) - 3.98);
}

//amount of light that will reach the camera when light enters the fiber then reflects off the internal surface and exit back out
float3 HairTRTFressnelAndTransmission(float3 absorption, float reflectiveness, float cosLongitudinalDifferenceAngle)
{
    //Fresnel dictates how much light is reflected on the reflection event, and blocks light from passing though on both transmission events
    float fresnel = Fresnel(cosLongitudinalDifferenceAngle / 2.0, reflectiveness, _FurFresnelStrength);
    fresnel = (1.0 - fresnel) * (1.0 - fresnel) * fresnel;

    //tint the light based on how far it had to travel through the hair follicle
    float transmissionLength = 0.8 / cosLongitudinalDifferenceAngle;
    float3 transmission = saturate(exp(-absorption * transmissionLength));

    return fresnel * transmission;
}

//amount of light that will reach the camera when light passes though the fiber
float3 HairTTFressnelAndTransmission(float3 absorption, float reflectiveness, float cosAzimuthalAngle, float cosHalfAzimuthalAngle, float cosLongitudinalDifferenceAngle)
{
    float modifiedIndexOfRefraction = (1.19 / cosLongitudinalDifferenceAngle) + (0.36 * cosLongitudinalDifferenceAngle);
    float offsetFromHairCenter = ((((-0.8 * cosAzimuthalAngle) + 0.6) / modifiedIndexOfRefraction) + 1.0) * cosHalfAzimuthalAngle;
    float offsetFromHairCenterSquared = saturate(offsetFromHairCenter * offsetFromHairCenter);

    //Fresnel blocks light from passing though on both transmission events
    float fresnel = Fresnel(cosLongitudinalDifferenceAngle * sqrt(1.0 - offsetFromHairCenterSquared), reflectiveness, _FurFresnelStrength);
    fresnel = (1.0 - fresnel) * (1.0 - fresnel);

    //tint the light based on how far it had to travel through the hair follicle
    float transmissionLength = sqrt(1.0 - saturate(offsetFromHairCenterSquared / (modifiedIndexOfRefraction * modifiedIndexOfRefraction)))
                             / (2.0 * cosLongitudinalDifferenceAngle);
    float3 transmission = saturate(exp(-absorption * transmissionLength));

    return  fresnel * transmission;
}

//extremely basic aproximation off multi-scattering. The hair transmission was derrived from the desired multiscattering albedo used here
float3 GetHairMultiscattering(float3 albedo, float reflectiveness, float3 iridescence)
{
    return saturate(lerp(albedo, reflectiveness * iridescence, reflectiveness)) / cPi;
}

//get iridescence from a look up texture based on the reflection angle and the iridescent film thickness
float3 HairIridescence(float lDotH, float iridescenceFactor)
{
    //sample from left side of the texture when the light and view directions are aligned
    //sample from the right side when they are opposite
    float iridescenceAngle = saturate(1.0 - lDotH);

    return _FurIridescenceLUT.SampleLevel(sampler_FurIridescenceLUT, float2(iridescenceAngle, iridescenceFactor), 0.0).rgb;
}

//full hair direct lighting model
float3 GetHairDirectLighting(float3 lightDirection,
                             float3 viewDirection,
                             float3 hairTangent,
                             float3 albedo,
                             float3 absorption,
                             float roughness,
                             float reflectiveness,
                             float iridescentThickness,
                             float3 selfShadowNormal,
                             float3 selfShadowOpacity,
                             float2 selfShadowParams,
                             float3 lightColor)
{
    //derive frequently used terms in the hair lighting BRDF

    float lightDirectionDotHalfNormal = sqrt(saturate((dot(lightDirection, viewDirection) / 2.0) + 0.5));

    float lightDotHair = dot(lightDirection, hairTangent);
    float viewDotHair = dot(viewDirection, hairTangent);
    float cosLongitudinalDifferenceAngle = cos(abs(asin(viewDotHair) - asin(lightDotHair)) / 2.0);

    float3 projectedLightDirection = normalize(lightDirection - (hairTangent * lightDotHair));
    float3 projectedViewDirection = normalize(viewDirection - (hairTangent * viewDotHair));
    float cosAzimuthalAngle = dot(projectedLightDirection, projectedViewDirection);
    float cosHalfAzimuthalAngle = sqrt(saturate((cosAzimuthalAngle / 2.0) + 0.5));

    //get iridescence color

    float3 iridescence = HairIridescence(lightDirectionDotHalfNormal, iridescentThickness);

    float3 lighting = 0.0;

    //R term
    float roughnessR = roughness;
    float shiftR = -2.0 * _FurShift;
    lighting += HairLongitudinalScattering(lightDotHair, viewDotHair, roughnessR, shiftR)
              * HairRScattering(cosHalfAzimuthalAngle)
              * Fresnel(lightDirectionDotHalfNormal, reflectiveness, _FurFresnelStrength);

    //TRT term
    float roughnessTRT = 2.0 * roughness;
    float shiftTRT = 4.0 * _FurShift;
    lighting += HairLongitudinalScattering(lightDotHair, viewDotHair, roughnessTRT, shiftTRT)
              * HairTRTScattering(cosAzimuthalAngle)
              * HairTRTFressnelAndTransmission(absorption, reflectiveness, cosLongitudinalDifferenceAngle);

    //only apply iridescence to reflection terms (ignore the fact that the TRT term would interact with the iridescence multiple times)
    lighting *= iridescence;

    //TT term
    float roughnessTT = 0.5 * roughness;
    float shiftTT = _FurShift;
    lighting += HairLongitudinalScattering(lightDotHair, viewDotHair, roughnessTT, shiftTT)
              * HairTTScattering(cosAzimuthalAngle)
              * HairTTFressnelAndTransmission(absorption, reflectiveness, cosAzimuthalAngle, cosHalfAzimuthalAngle, cosLongitudinalDifferenceAngle);

    //apply self shadowing
    float lambert = dot(lightDirection, selfShadowNormal);
    lighting *= GetSelfShadowing(lambert, selfShadowOpacity, selfShadowParams);

    lighting *= CacheSpecLightColor;

    //multiscatter term
    float remappedLambert = RemapLambert(lambert, _FurRemapStart, _FurRemapEnd);
    lighting += GetHairMultiscattering(albedo, reflectiveness, iridescence)
              * GetSelfShadowing(remappedLambert, selfShadowOpacity, selfShadowParams)
              * lightColor;

    return max(0.0, lighting);
}

//full hair indirect lighting model
float3 GetHairIndirectLighting(float3 worldPos, float3 viewDirection, float3 hairTangent, float3 selfShadowNormal,
                               float3 albedo, float3 absorption, float roughness, float reflectiveness, float iridescentThickness,
                               float3 selfShadowOpacity, float2 selfShadowParams, float transmissionOcclusion)
{
    static const float cHairAzimuthalScatteringCubemapRoughness = 0.1; //ad-hoc value

    //each lighting term has the same cosLongitudinalDifferenceAngle that maximizes its scattering response
    float viewDotHair = dot(viewDirection, hairTangent);
    float cosLongitudinalDifferenceAngle = sqrt(1.0 - saturate(viewDotHair * viewDotHair));

    //R and TRT terms

    //get shading parameters based on a light direction that is the view direction reflected by the half normal

    float3 reflectionCenterDirection = normalize(viewDirection - (hairTangent * dot(hairTangent, viewDirection) * 2.0));
    float lightDirectionDotHalfNormalR = cosLongitudinalDifferenceAngle; //the math works out so that these are the same

    float3 iridescence = HairIridescence(lightDirectionDotHalfNormalR, iridescentThickness);
    float surfaceFresnel = Fresnel(lightDirectionDotHalfNormalR, reflectiveness, _FurFresnelStrength);

    //approximate reflection scattering integration by sampling the cubemap based on reflection roughness (do a single sample with weighted average roughness for performance)

    float roughnessR = roughness;
    float roughnessTRT = 2.0 * roughness;

    float relativeReflectionLobeWeight = saturate(1.0 - surfaceFresnel);
    relativeReflectionLobeWeight = 1.0 / (1.0 + (relativeReflectionLobeWeight * relativeReflectionLobeWeight));

    float reflectionCubemapRoughness = saturate(lerp(roughnessTRT, roughnessR, relativeReflectionLobeWeight)); //blend based on relative visibility
    reflectionCubemapRoughness = lerp(cHairAzimuthalScatteringCubemapRoughness, 1.0, reflectionCubemapRoughness);

    float3 reflectionProbeSample = 0.0;
    if (_FurCustomReflectionProbeEnabled)
    {
        reflectionProbeSample = SampleReflectionProbe(_FurCustomReflectionProbe, reflectionCenterDirection, reflectionCubemapRoughness);
    }
    else
    {
        reflectionProbeSample = SampleBuiltInReflectionProbes(worldPos, reflectionCenterDirection, reflectionCubemapRoughness);
    }

    //evaluate the Fresnel, transmission, and self shadowing for both types of reflections
    //(there's no proper integration with the scattering functions so just evaluate with the center direcion of the refletion lobes as an approximation)

    float3 reflectionColor = surfaceFresnel; //R term
    reflectionColor += HairTRTFressnelAndTransmission(absorption, reflectiveness, cosLongitudinalDifferenceAngle); //TRT term

    //use cubemap sample roughness to bias self shadowing to acccount for more of the light coming in from shadowed angles at high roughness
    reflectionColor *= GetSelfShadowing(dot(reflectionCenterDirection, selfShadowNormal), selfShadowOpacity, selfShadowParams, reflectionCubemapRoughness);

    //apply the same iridescence term to both types of reflection (ignore the fact that the TRT term would interact with the iridescence multiple times)
    reflectionColor *= iridescence;

    float3 lighting = reflectionColor * reflectionProbeSample;

    //TT term

    [branch]
    if (transmissionOcclusion > cEpsilon)
    {
        //get shading paramters based on a light direction directly opposite the view direction

        float3 transmissionCenterDirection = -viewDirection;
        float cosAzimuthalAngleTT = -1;
        float cosHalfAzimuthalAngleTT = 0;

        //approximate transmission scattering integration by sampling the cubemap based on the scattering roughness

        float roughnessTT = 0.5 * roughness;
        float transmissionCubemapRoughness = lerp(cHairAzimuthalScatteringCubemapRoughness, 1.0, roughnessTT);

        float3 transmissionProbeSample = 0.0;
        if (_FurCustomTransmissionProbeEnabled)
        {
            transmissionProbeSample = SampleReflectionProbe(_FurCustomTransmissionProbe, transmissionCenterDirection, transmissionCubemapRoughness);
        }
        else
        {
            transmissionProbeSample = SampleBuiltInReflectionProbes(worldPos, transmissionCenterDirection, transmissionCubemapRoughness);
        }

        //evaluate the Fresnel, transmission, and self shadowing of the transmission lobe
        //(there's no proper integration with the scattering function so just evaluate with the center direcion of the transmission lobe as an approximation)

        float3 transmissionColor = HairTTFressnelAndTransmission(absorption, reflectiveness, cosAzimuthalAngleTT, cosHalfAzimuthalAngleTT, cosLongitudinalDifferenceAngle);

        //use cubemap sample roughness to bias self shadowing to acccount for more of the light coming in from shadowed angles at high roughness
        transmissionColor *= GetSelfShadowing(dot(transmissionCenterDirection, selfShadowNormal), selfShadowOpacity, selfShadowParams, transmissionCubemapRoughness);

        lighting += transmissionColor * transmissionProbeSample * transmissionOcclusion;
    }

    //multiscattering term

    //use the difffuse lighting of the ambient probes as an approximation for indirect multi-scattering
    //Unity's encoding for ambient diffuse assumes no 1/PI normalization factor so we need to multiply by Pi to correct for that here
    float3 diffuseProbeSample = GetBuiltInAmbientDiffuse(worldPos, selfShadowNormal, _FurAmbientLightingDirectionality) * cPi;

    float3 multiscatteringColor = GetHairMultiscattering(albedo, reflectiveness, iridescence);

    //self shadow in the direction of the self shadow normal, using the maximum roughness bias
    multiscatteringColor *= GetSelfShadowing(1.0, selfShadowOpacity, selfShadowParams, 1.0);

    lighting += multiscatteringColor * diffuseProbeSample;

    return max(0.0, lighting);
}

//Matches behavior of Shade4PointLights(...) but for the hair lighting model
float3 GetUnimportantLightsForHair(float3 worldPos, float3 selfShadowOpacity, float3 selfShadowNormal, float2 selfShadowParams)
{
    float3 totalLighting = 0.0;

    [loop]
    for (uint lightIndex = 0; lightIndex < 4; lightIndex++)
    {
        //skip any lights that won't actually contribute
        if (all(unity_LightColor[lightIndex] < cEpsilon))
        {
            continue;
        }

        //get the parameters of the light
        float3 toLight = float3(unity_4LightPosX0[lightIndex],
                                unity_4LightPosY0[lightIndex],
                                unity_4LightPosZ0[lightIndex]);
        toLight -= worldPos;

        float lightSquareDistance = max(0.0, dot(toLight, toLight));
        float3 lightDirection = lightSquareDistance > cEpsilon ? toLight / sqrt(lightSquareDistance) : selfShadowNormal;
        float3 lightAttenuation = saturate(1.0 / (1.0 + lightSquareDistance * unity_4LightAtten0[lightIndex]));

        //get the light intensity
        float3 lighting = unity_LightColor[lightIndex].rgb * lightAttenuation;

        //get the self shadowing
        float remappedLambert = RemapLambert(dot(lightDirection, selfShadowNormal), _FurRemapStart, _FurRemapEnd);
        lighting *= GetSelfShadowing(remappedLambert, selfShadowOpacity, selfShadowParams);

        totalLighting += lighting;
    }

    return totalLighting * cPi; //Unity's built in shaders implicitly multiply light strength by PI
}

//Main Lighting Helper -----------------------------------------------------------------------------

//evaluate the entire appearance of the material
float3 GetFullLightingModel(float3 worldPos,
                            float3 normal,
                            float anisotropyStrength,
                            float3 anisotropyTangent,
                            float3 anisotropyBitangent,
                            float3 hairTangent,
                            float3 albedo,
                            float3 emission,
                            float roughness,
                            float reflectiveness,
                            float iridescentThickness,
                            float ambientOcclusion,
                            float furness,
                            float2 selfShadowParams,
                            float3 selfShadowNormal,
                            float transmissionOcclusion,
                            float diffuseNormalBias)
{
    ForkInit(worldPos);

    //get light parameters
    float3 lightDirection = GetBuiltInLightDirection(worldPos);
    float3 lightColor = GetBuiltInLightColor() * GetBuiltInLightAttenuation(worldPos) * GetBuiltInLightRealtimeShadows(worldPos);

    //get view direction
    float3 viewDirection = normalize(_WorldSpaceCameraPos - worldPos);

    //get normal for diffuse
    float3 diffuseNormal = normalize(lerp(normal, selfShadowNormal, diffuseNormalBias));

    //get hair material parameters
    float3 hairAbsorption = HairAbsorptionFromAlbedo(albedo);
    float hairReflectiveness = lerp(_FurBaselineReflectiveness, 1.0, reflectiveness);

    //
    float3 selfShadowOpacity = GetSelfShadowOpacity(hairAbsorption, hairReflectiveness, furness);

    //initialize lighting to emission value
    #ifdef BASE_LIGHTING_PASS
    float3 lighting = emission;
    #else
    float3 lighting = 0;
    #endif

    //if furness is > 0, evaluate hair lighting
    [branch]
    if (furness > cEpsilon)
    {
        ForkInitNormal(selfShadowNormal, viewDirection, lightColor, roughness);

        float3 hairLighting = GetHairDirectLighting(lightDirection,
                                                    viewDirection,
                                                    hairTangent,
                                                    albedo,
                                                    hairAbsorption,
                                                    roughness,
                                                    hairReflectiveness,
                                                    iridescentThickness,
                                                    selfShadowNormal,
                                                    selfShadowOpacity,
                                                    selfShadowParams,
                                                    lightColor);
        //hairLighting *= lightColor;
        hairLighting *= lerp(1.0, ambientOcclusion, _FurDirectLightingOcclusion);

#ifdef BASE_LIGHTING_PASS

        //get the contribution of all the unimportant lights lights, using a simplified lighting model for unimportant lights that only accounts for multiscattering

        float3 unimportantLighting = GetUnimportantLightsForHair(worldPos, selfShadowOpacity, selfShadowNormal, selfShadowParams);

        //since this isn't accounting for specular, just use 0 for the iridescent  color to factor it out of the multiscattering
        unimportantLighting *= GetHairMultiscattering(albedo, hairReflectiveness, 0.0);
        unimportantLighting *= lerp(1.0, ambientOcclusion, _FurDirectLightingOcclusion);

        hairLighting += unimportantLighting;

        //indirect lighting
        float3 hairIndirectLighting = GetHairIndirectLighting(worldPos,
                                                              viewDirection,
                                                              hairTangent,
                                                              selfShadowNormal,
                                                              albedo,
                                                              hairAbsorption,
                                                              roughness,
                                                              hairReflectiveness,
                                                              iridescentThickness,
                                                              selfShadowOpacity,
                                                              selfShadowParams,
                                                              transmissionOcclusion);
        hairIndirectLighting *= ambientOcclusion;

        hairLighting += hairIndirectLighting;

#endif //BASE_LIGHTING_PASS

        lighting += hairLighting * furness;
    }

    [branch]
    if (furness < (1.0 - cEpsilon))
    {
        ForkInitNormal(normal, viewDirection, lightColor, roughness);

        float3 standardLighting = GetNonHairDirectLighting(lightDirection,
                                                           viewDirection,
                                                           diffuseNormal,
                                                           normal,
                                                           albedo,
                                                           roughness,
                                                           anisotropyStrength,
                                                           anisotropyTangent,
                                                           anisotropyBitangent,
                                                           reflectiveness,
                                                           iridescentThickness,
                                                           lightColor);
        //standardLighting *= lightColor;

        //apply hair self shadowing to non-hair lighting as well
        float2 nonHairSelfShadowParams = float2(selfShadowParams.x * _SelfShadowNonFurStrengthMultiplier, 0.0);
        float3 directLightHairShadow = GetSelfShadowing(1.0, selfShadowOpacity, nonHairSelfShadowParams);

        standardLighting *= directLightHairShadow;

#ifdef BASE_LIGHTING_PASS

        //evaluate non-important lights with a diffuse only lighting model
        float3 unimportantLighting = Shade4PointLights(unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                                                       unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                                                       unity_4LightAtten0, worldPos, normal);
        unimportantLighting *= albedo * GetDiffuseEnergyConservationFactor(reflectiveness);
        unimportantLighting *= directLightHairShadow;

        standardLighting += unimportantLighting;

        //indirect lighting
        float3 standardIndirectLighting = GetNonHairIndirectLighting(worldPos,
                                                                     viewDirection,
                                                                     diffuseNormal,
                                                                     normal,
                                                                     albedo,
                                                                     anisotropyBitangent,
                                                                     anisotropyStrength,
                                                                     roughness,
                                                                     reflectiveness,
                                                                     iridescentThickness);
        standardIndirectLighting *= ambientOcclusion;
        standardIndirectLighting *= GetSelfShadowing(1.0, selfShadowOpacity, nonHairSelfShadowParams, 1.0);

        standardLighting += standardIndirectLighting;

#endif //BASE_LIGHTING_PASS

        lighting += standardLighting * (1.0 - furness);
    }

    lighting = ClampBrightness(lighting);

    return ApplyBuiltInFog(lighting, worldPos);
}
