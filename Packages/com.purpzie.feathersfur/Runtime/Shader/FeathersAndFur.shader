Shader "normalizedcrow/Feathers and Fur"
{
    Properties
    {
        [Toggle] _LIGHT_VOLUMES ("Light Volumes", Int) = 0
        [Toggle] _PURPZIE_GRYPHON_AUDIOLINK ("Gryphon Audiolink", Int) = 0
        [Toggle] _COLOR_ADJUST ("Color Adjust", Int) = 0
        _ColorAdjustHue ("Hue", Range(0, 1)) = 0
        _ColorAdjustSaturation ("Saturation", Range(-1, 5)) = 0
        _ColorAdjustValue ("Value", Range(-1, 2)) = 0
        [NoScaleOffset] _PurpzieGryphonAudiolinkTexture ("Gryphon Audiolink Texture", 2D) = "black" {}
        _PurpzieGryphonAudiolinkStrength ("Gryphon Audiolink Strength", Range(0, 1)) = 0.5

        //Fur Cards -----------------------------------------------------------------------

        //Coat
        _CoatParametersTexture("Coat Parameters Texture", 2D) = "black" {}
        _CoatDirectionTexture("Coat Direction Texture", 2D) = "bump" {}

        //Card Atlas Texture
        _CardAtlasTextureCount("Card Atlas Textures in Atlas", Int) = 1
        _CardAtlasTexturesPerRow("Card Atlas Textures per Row", Int) = 1

        _CardCutoutTexture("Card Cutout Opacity Texture", 2D) = "white" {}
        [ToggleUI] _CardCutoutTextureAtlasEnabled("Card Cutout Opacity Use Texture Atlas", Int) = 1
        _CardCutoutThreshold("Card Cutout Threshold", Range(0.0, 1.0)) = 0.5

        //Size
        [PowerSlider(2.72)] _CardSizeMin("Min Card Size", Range(0.001, 0.1)) = 0.005
        [PowerSlider(2.72)] _CardSizeMax("Max Card Size", Range(0.001, 0.1)) = 0.025

        //Shape Length
        _CardShapeLengthMin("Min Card Shape Length", Range(0.0, 30.0)) = 5.0
        _CardShapeLengthMax("Max Card Shape Length", Range(0.0, 30.0)) = 5.0
        _CardShapeLengthCurve("Card Shape Length Transition Curve", Range(-5.0, 5.0)) = 0

        //Shape Width
        _CardShapeWidthMin("Min Card Shape Width", Range(0.0, 30.0)) = 2.0
        _CardShapeWidthMax("Max Card Shape Width", Range(0.0, 30.0)) = 2.0
        _CardShapeWidthCurve("Card Shape Width Transition Curve", Range(-5.0, 5.0)) = 0

        //Direction Adjustment
        _CardElevationMin("Min Card Elevation", Range(0.0, 1.0)) = 0.0
        _CardElevationMax("Max Card Elevation", Range(0.0, 1.0)) = 1.0
        _CardElevationRandomness("Card Elevation Randomness", Range(0.0, 1.0)) = 0.0
        _CardOrientationRandomness("Card Orientation Randomness", Range(0.0, 1.0)) = 0.0

        //Rotation
        _CardRotationRandomnessMin("Min Card Rotation Randomness", Range(0.0, 1.0)) = 0.0
        _CardRotationRandomnessMax("Max Card Rotation Randomness", Range(0.0, 1.0)) = 0.0
        _CardRotationRandomnessElevationStart("Card Elevation for Min Rotation Randomness", Range(0.0, 1.0)) = 0.0
        _CardRotationRandomnessElevationEnd("Card Elevation for Max Rotation Randomness", Range(0.0, 1.0)) = 1.0

        //Billboarding
        _CardBillboardingMin("Min Card Billboarding", Range(0.0, 1.0)) = 0.0
        _CardBillboardingMax("Max Card Billboarding", Range(0.0, 1.0)) = 0.0
        _CardBillboardingElevationStart("Card Elevation for Min Billboarding", Range(0.0, 1.0)) = 0.0
        _CardBillboardingElevationEnd("Card Elevation for Max Billboarding", Range(0.0, 1.0)) = 1.0
        _CardBillboardingSizeStart("Card Size for Min Billboarding", Range(0.0, 1.0)) = 0.0
        _CardBillboardingSizeEnd("Card Size for Max Billboarding", Range(0.0, 1.0)) = 1.0

        //Color -----------------------------------------------------------------------------------

        //Undercoat
        _UndercoatAlbedoTexture("Undercoat Color And Cutout Opacity Texture", 2D) = "white" {}
        _UndercoatAlbedoTint("Undercoat Color Tint", Color) = (1.0, 1.0, 1.0, 1.0)
        [ToggleUI] _UndercoatCutoutEnabled("Undercoat Use Cutout", Int) = 0
        _UndercoatCutoutThreshold("Undercoat Cutout Threshold", Range(0.0, 1.0)) = 0.5

        //Coat
        _CoatAlbedoTexture("Coat Color And Cutout Opacity Texture", 2D) = "white" {}
        _CoatAlbedoTint("Coat Color Tint", Color) = (1.0, 1.0, 1.0, 1.0)
        [ToggleUI] _CoatCutoutEnabled("Coat Use Cutout", Int) = 0
        _CoatCutoutThreshold("Coat Cutout Threshold", Range(0.0, 1.0)) = 0.5

        //Card
        _CardAlbedoTexture("Card Color Texture", 2D) = "white" {}
        [ToggleUI] _CardAlbedoTextureAtlasEnabled("Card Color Use Texture Atlas", Int) = 1
        [HDR] _CardAlbedoTint("Card Color Tint", Color) = (1.0, 1.0, 1.0, 1.0)
        [Enum(Off, 0, Override, 1, Additive, 2, Subtractive, 3, Tint, 4, Alpha, 5, Premultiplied Alpha, 6)] _CardAlbedoBlendMode("Card Color Blend Mode", Int) = 0

        //Emission --------------------------------------------------------------------------------

        //Undercoat
        _UndercoatEmissionTexture("Undercoat Emission Texture", 2D) = "white" {}
        [HDR] _UndercoatEmissionTint("Undercoat Emission Tint", Color) = (0.0, 0.0, 0.0, 1.0)

        //Coat
        _CoatEmissionTexture("Coat Emission Texture", 2D) = "white" {}
        [HDR] _CoatEmissionTint("Coat Emission Tint", Color) = (0.0, 0.0, 0.0, 1.0)

        //Card
        _CardEmissionTexture("Card Emission Texture", 2D) = "white" {}
        [ToggleUI] _CardEmissionTextureAtlasEnabled("Card Emission Use Texture Atlas", Int) = 1
        [HDR] _CardEmissionTint("Card Emission Tint", Color) = (1.0, 1.0, 1.0, 1.0)
        [Enum(Off, 0, Override, 1, Additive, 2, Subtractive, 3, Tint, 4, Alpha, 5, Premultiplied Alpha, 6)] _CardEmissionBlendMode("Card Emission Blend Mode", Int) = 0

        //Material Parameters ---------------------------------------------------------------------

        //Undercoat
        _UndercoatMaterialParametersTexture("Undercoat Material Parameters Texture", 2D) = "white" {}
        _UndercoatReflectivenessMin("Undercoat Min Reflectiveness / Metalness", Range(0.0, 1.0)) = 0.0
        _UndercoatReflectivenessMax("Undercoat Max Reflectiveness / Metalness", Range(0.0, 1.0)) = 0.0
        _UndercoatRoughnessMin("Undercoat Min Roughness", Range(0.0, 1.0)) = 0.0
        _UndercoatRoughnessMax("Undercoat Max Roughness", Range(0.0, 1.0)) = 1.0
        _UndercoatIridescentThicknessMin("Undercoat Min Iridescent Thickness", Range(0.0, 1.0)) = 0.0
        _UndercoatIridescentThicknessMax("Undercoat Max Iridescent Thickness", Range(0.0, 1.0)) = 1.0
        _UndercoatAmbientOcclusionMin("Undercoat Min Ambient Occlusion", Range(0.0, 1.0)) = 0.0
        _UndercoatAmbientOcclusionMax("Undercoat Max Ambient Occlusion", Range(0.0, 1.0)) = 1.0

        //Coat
        _CoatMaterialParametersTexture("Coat Material Parameters Texture", 2D) = "white" {}
        _CoatReflectivenessMin("Coat Min Reflectiveness / Metalness", Range(0.0, 1.0)) = 0.0
        _CoatReflectivenessMax("Coat Max Reflectiveness / Metalness", Range(0.0, 1.0)) = 0.0
        _CoatRoughnessMin("Coat Min Roughness", Range(0.0, 1.0)) = 0.0
        _CoatRoughnessMax("Coat Max Roughness", Range(0.0, 1.0)) = 1.0
        _CoatIridescentThicknessMin("Coat Min Iridescent Thickness", Range(0.0, 1.0)) = 0.0
        _CoatIridescentThicknessMax("Coat Max Iridescent Thickness", Range(0.0, 1.0)) = 1.0
        _CoatAmbientOcclusionMin("Coat Min Ambient Occlusion", Range(0.0, 1.0)) = 0.0
        _CoatAmbientOcclusionMax("Coat Max Ambient Occlusion", Range(0.0, 1.0)) = 1.0

        //Card
        _CardMaterialParametersTexture("Card Material Parameters Texture", 2D) = "white" {}
        [ToggleUI] _CardMaterialParametersTextureAtlasEnabled("Card Material Parameters Use Texture Atlas", Int) = 1
        _CardReflectivenessMin("Card Min Reflectiveness / Metalness", Range(0.0, 1.0)) = 0.0
        _CardReflectivenessMax("Card Max Reflectiveness / Metalness", Range(0.0, 1.0)) = 1.0
        [Enum(FeathersAndFurShaderEnums.CardMaterialBlendMode)] _CardReflectivenessBlendMode("Card Reflectiveness / Metalness Blend Mode", Int) = 0
        _CardRoughnessMin("Card Min Roughness", Range(0.0, 1.0)) = 0.0
        _CardRoughnessMax("Card Max Roughness", Range(0.0, 1.0)) = 1.0
        [Enum(FeathersAndFurShaderEnums.CardMaterialBlendMode)] _CardRoughnessBlendMode("Card Roughness Blend Mode", Int) = 0
        _CardIridescentThicknessMin("Card Min Iridescent Thickness", Range(0.0, 1.0)) = 0.0
        _CardIridescentThicknessMax("Card Max Iridescent Thickness", Range(0.0, 1.0)) = 1.0
        [Enum(FeathersAndFurShaderEnums.CardMaterialBlendMode)] _CardIridescentThicknessBlendMode("Card Iridescent Thickness Blend Mode", Int) = 0
        _CardAmbientOcclusionMin("Card Min Ambient Occlusion", Range(0.0, 1.0)) = 0.0
        _CardAmbientOcclusionMax("Card Max Ambient Occlusion", Range(0.0, 1.0)) = 1.0
        [Enum(FeathersAndFurShaderEnums.CardMaterialBlendMode)] _CardAmbientOcclusionBlendMode("Card Ambient Occlusion Blend Mode", Int) = 0

        //Additional Material Parameters ----------------------------------------------------------

        //Undercoat
        _UndercoatAdditionalMaterialParametersTexture("Undercoat Additional Material Parameters Texture", 2D) = "white" {}
        [ToggleUI] _UndercoatFurnessReadCoatParametersMask("Undercoat Get Furness From Coat Parameters Mask", Int) = 1
        _UndercoatFurnessMin("Undercoat Min Furness", Range(0.0, 1.0)) = 0.0
        _UndercoatFurnessMax("Undercoat Max Furness", Range(0.0, 1.0)) = 1.0
        [PowerSlider(2.72)] _UndercoatDiameterMin("Undercoat Min Model Diameter", Range(0.01, 5.0)) = 0.0
        [PowerSlider(2.72)] _UndercoatDiameterMax("Undercoat Max Model Diameter", Range(0.01, 5.0)) = 1.0
        _UndercoatSelfShadowMaskMin("Undercoat Min Self Shadow Mask", Range(0.0, 1.0)) = 0.0
        _UndercoatSelfShadowMaskMax("Undercoat Max Self Shadow Mask", Range(0.0, 1.0)) = 1.0
        _UndercoatAmbientTransmissionOcclusionMin("Undercoat Min Ambient Transmission Occlusion", Range(0.0, 1.0)) = 0.0
        _UndercoatAmbientTransmissionOcclusionMax("Undercoat Max Ambient Transmission Occlusion", Range(0.0, 1.0)) = 1.0

        //Coat
        _CoatAdditionalMaterialParametersTexture("Coat Additional Material Parameters Texture", 2D) = "white" {}
        _CoatFurnessMin("Coat Min Furness", Range(0.0, 1.0)) = 0.0
        _CoatFurnessMax("Coat Max Furness", Range(0.0, 1.0)) = 1.0
        [PowerSlider(2.72)] _CoatDiameterMin("Coat Min Model Diameter", Range(0.01, 5.0)) = 0.0
        [PowerSlider(2.72)] _CoatDiameterMax("Coat Max Model Diameter", Range(0.01, 5.0)) = 1.0
        _CoatSelfShadowMaskMin("Coat Min Self Shadow Mask", Range(0.0, 1.0)) = 0.0
        _CoatSelfShadowMaskMax("Coat Max Self Shadow Mask", Range(0.0, 1.0)) = 1.0
        _CoatAmbientTransmissionOcclusionMin("Coat Min Ambient Transmission Occlusion", Range(0.0, 1.0)) = 0.0
        _CoatAmbientTransmissionOcclusionMax("Coat Max Ambient Transmission Occlusion", Range(0.0, 1.0)) = 1.0

        //Normals, Fur Tangents, and Anisotropy -------------------------------------------

        //Undercoat
        _UndercoatNormalTexture("Undercoat Normal Map Texture", 2D) = "bump" {}
        _UndercoatNormalStrength("Undercoat Normal Strength", Range(0.0, 1.0)) = 1.0
        _UndercoatNormalFurInfluence("Undercoat Normal Influence on Fur Tangents", Range(0.0, 1.0)) = 1.0

        _UndercoatAnisotropyTexture("Undercoat Fur Tangents / Anisotropy Texture", 2D) = "bump" {}
        _UndercoatAnisotropyFlattenFurTangents("Undercoat Flatten Fur Tangents To Surface", Range(0.0, 1.0)) = 0.0
        _UndercoatAnisotropyStrength("Undercoat Anisotropy Strength", Range(-1.0, 1.0)) = 0.0

        _UndercoatFurRootNormalTexture("Undercoat Fur Root Normal Map Texture", 2D) = "bump" {}
        _UndercoatFurRootNormalStrength("Undercoat Fur Root Normal Strength", Range(0.0, 1.0)) = 1.0
        _UndercoatFurRootNormalDiffuseInfluence("Undercoat Adjust Diffuse to Fur Root Normal", Range(0.0, 1.0)) = 0.0

        //Coat
        _CoatFurRootNormalTexture("Coat Fur Root Normal Map Texture", 2D) = "bump" {}
        _CoatFurRootNormalStrength("Coat Fur Root Normal Strength", Range(0.0, 1.0)) = 1.0
        _CoatFurRootNormalDiffuseInfluence("Coat Adjust Diffuse to Fur Root Normal", Range(0.0, 1.0)) = 0.0

        //Card
        _CardNormalTexture("Card Normal Map Texture", 2D) = "bump" {}
        [ToggleUI] _CardNormalTextureAtlasEnabled("Card Normal Map Use Texture Atlas", Int) = 1
        _CardNormalStrength("Card Normal Strength", Range(0.0, 1.0)) = 1.0
        _CardNormalFurInfluence("Card Normal Influence on Fur Tangents", Range(0.0, 1.0)) = 1.0

        _CardAnisotropyTexture("Card Fur Tangents / Anisotropy Texture", 2D) = "black" {}
        [ToggleUI] _CardAnisotropyTextureAtlasEnabled("Card Fur Tangents / Anisotropy Use Texture Atlas", Int) = 1
        _CardAnisotropyFlattenFurTangents("Card Flatten Fur Tangents To Surface", Range(0.0, 1.0)) = 1.0
        _CardAnisotropyStrength("Card Anisotropy Strength", Range(-1.0, 1.0)) = 0.0

        //Clothing --------------------------------------------------------------------------------

        //Mask 0
        _ClothingMaskFullTexture("Clothing Mask Full Texture", 2D) = "white" {}
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskFullRedChannelMode("Clothing Mask Full Red Channel Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskFullGreenChannelMode("Clothing Mask Full Green Channel Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskFullBlueChannelMode("Clothing Mask Full Blue Channel Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskFullAlphaChannelMode("Clothing Mask Full Alpha Channel Mode", Int) = 0

        _ClothingMaskPackedTexture("Clothing Mask Packed Texture", 2D) = "black" {}
        [ToggleUI] _ClothingMaskPackedUvWrapEnabled("Clothing Mask Packed Use UV Wrap", Int) = 1
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked0BitMode("Clothing Mask Packed 0 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked1BitMode("Clothing Mask Packed 1 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked2BitMode("Clothing Mask Packed 2 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked3BitMode("Clothing Mask Packed 3 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked4BitMode("Clothing Mask Packed 4 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked5BitMode("Clothing Mask Packed 5 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked6BitMode("Clothing Mask Packed 6 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked7BitMode("Clothing Mask Packed 7 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked8BitMode("Clothing Mask Packed 8 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked9BitMode("Clothing Mask Packed 9 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked10BitMode("Clothing Mask Packed 10 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked11BitMode("Clothing Mask Packed 11 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked12BitMode("Clothing Mask Packed 12 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked13BitMode("Clothing Mask Packed 13 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked14BitMode("Clothing Mask Packed 14 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked15BitMode("Clothing Mask Packed 15 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked16BitMode("Clothing Mask Packed 16 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked17BitMode("Clothing Mask Packed 17 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked18BitMode("Clothing Mask Packed 18 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked19BitMode("Clothing Mask Packed 19 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked20BitMode("Clothing Mask Packed 20 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked21BitMode("Clothing Mask Packed 21 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked22BitMode("Clothing Mask Packed 22 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked23BitMode("Clothing Mask Packed 23 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked24BitMode("Clothing Mask Packed 24 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked25BitMode("Clothing Mask Packed 25 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked26BitMode("Clothing Mask Packed 26 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked27BitMode("Clothing Mask Packed 27 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked28BitMode("Clothing Mask Packed 28 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked29BitMode("Clothing Mask Packed 29 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked30BitMode("Clothing Mask Packed 30 Bit Mode", Int) = 0
        [Enum(Ignore, 0, Hide Cards, 1, Cutout, 2)] _ClothingMaskPacked31BitMode("Clothing Mask Packed 31 Bit Mode", Int) = 0

        //Cutout
        _ClothingMaskCutoutThreshold("Clothing Mask Cutout Threshold", Range(0.0, 1.0)) = 0.5

        //Lighting --------------------------------------------------------------------------------

        //Self Shadowing
        _SelfShadowColoredStrength("Self Shadow Colored Strength", Range(0.0, 0.1)) = 0.01
        _SelfShadowUncoloredStrength("Self Shadow Uncolored Strength", Range(0.0, 0.1)) = 0.01
        _SelfShadowNonFurStrengthMultiplier("Self Shadow Non-Fur Strength Multiplier", Range(0.0, 5.0)) = 1.0
        _SelfShadowCardTipOpacity("Self Shadow Card Tip Opacity Approximation", Range(0.0, 1.0)) = 0.5

        //Fur
        _FurDirectLightingOcclusion("Fur AO Affects Direct Lighting", Range(0.0, 1.0)) = 0.0
        _FurShift("Fur Highlight Shift", Range(0.0, 0.25)) = 0.05
        _FurRemapStart("Fur Remap Start", Range(-1.0, 1.0)) = 0.0
        _FurRemapEnd("Fur Remap End", Range(-1.0, 1.0)) = 1.0
        _FurBaselineReflectiveness("Fur Base Reflectiveness", Range(0.0, 0.2)) = 0.047
        _FurFresnelStrength("Fur Fresnel Strength", Range(0.0, 1.0)) = 1.0
        [NoScaleOffset] _FurIridescenceLUT("Fur Iridescence LUT", 2D) = "white" {}

        //Diffuse
        _DiffuseRoughnessInfluence("Diffuse Roughness Influence", Range(0.0, 1.0)) = 1.0
        _DiffuseRemapStart("Diffuse Remap Start", Range(-1.0, 1.0)) = 0.0
        _DiffuseRemapEnd("Diffuse Remap End", Range(-1.0, 1.0)) = 1.0

        //Specular
        _SpecularBaselineReflectiveness("Specular Base Reflectiveness", Range(0.0, 0.2)) = 0.03
        _SpecularFresnelStrength("Specular Fresnel Strength", Range(0.0, 1.0)) = 1.0
        [NoScaleOffset] _SpecularIridescenceLUT("Specular Iridescence LUT", 2D) = "white" {}

        //Ambient Lighting
        [Enum(Off, 0, Override, 1, Additive, 2, Max Per Channel, 3, Max Luminance, 4)] _AmbientLightingOverrideMode("Ambient Lighting Override Mode", Int) = 0
        [HDR] _AmbientLightingOverrideColor("Ambient Lighting Override Color", Color) = (0.1, 0.1, 0.1, 1.0)
        _FurAmbientLightingDirectionality("Fur Ambient Lighting Directionality", Range(0.0, 1.0)) = 1.0
        _DiffuseAmbientLightingDirectionality("Diffuse Ambient Lighting Directionality", Range(0.0, 1.0)) = 1.0

        //Reflection Probes
        [ToggleUI] _FurCustomReflectionProbeEnabled("Use Custom Fur Reflection", Int) = 0
        [NoScaleOffset] _FurCustomReflectionProbe("Custom Fur Reflection Probe", Cube) = "black" {}
        [ToggleUI] _FurCustomTransmissionProbeEnabled("Use Custom Fur Transmission", Int) = 0
        [NoScaleOffset] _FurCustomTransmissionProbe("Custom Fur Transmission Probe", Cube) = "black" {}
        [ToggleUI] _SpecularCustomReflectionProbeEnabled("Use Custom Specular Reflection", Int) = 0
        [NoScaleOffset] _SpecularCustomReflectionProbe("Custom Specular Reflection Probe", Cube) = "black" {}

        //Miscellaneous
        _BrightnessClamp("Brightness Clamp", Float) = -1.0

        //Optimization ----------------------------------------------------------------------------

        //Coat
        [NoScaleOffset] _CoatOptimizationTexture("Coat Optimization Texture", 2D) = "red" {}

        //LOD
        _CardLodFactor("LOD Factor", Range(0.0, 5.0)) = 2.5
        _CardLodGrowth("LOD Card Growth Factor", Range(0.0, 5.0)) = 1.0
        [ToggleUI] _CardLodFixedResolutionEnabled("LOD Assume Fixed Resolution", Int) = 0
        _CardLodFixedResolution("LOD Fixed Resolution", Int) = 1080
        [PowerSlider(2.72)] _CardLodSpacingMax("LOD Maximum Spacing", Range(0.0, 0.1)) = 0.05
        [PowerSlider(2.72)] _CardLodSpacingMin("LOD Force Minimum Spacing", Range(0.0, 0.1)) = 0.0
        [PowerSlider(2.72)] _CardLodShadowSpacingMin("LOD Force Minimum Spacing in Shadows", Range(0.0, 0.1)) = 0.01

        //Fade
        _CardFadeStart("Fade Start Distance", Float) = 25.0
        _CardFadeLength("Fade Length", Float) = 5.0

        //Off-Screen Rendering
        [ToggleUI] _CardRenderInMirrors("Render Cards In Mirrors", Int) = 1
        [ToggleUI] _CardRenderInShadows("Render Cards In Shadows", Int) = 1

        //Miscellaneous ---------------------------------------------------------------------------

        //Skinned Mesh
        [KeywordEnum(None, UV2, UV3, UV4, UV5, UV6, UV7, UV8)] _BindPoseUvChannel("Bind Pose UV Channel", Int) = 0
        [ToggleUI] _SkinnedMeshScaleFixupEnabled("Use Skinned Mesh Scale Fixup", Int) = 1
        _CardRescale("Card Rescale", Vector) = (1.0, 1.0, 1.0, 1.0)

        //Rendering Options
        [Enum(UnityEngine.Rendering.CullMode)] _UndercoatCullMode("Undercoat Face Culling Mode", Int) = 2
        [Enum(UnityEngine.Rendering.CullMode)] _UndercoatShadowCullMode("Shadow Undercoat Face Culling Mode", Int) = 2
        _CardShadowBias("Distance to Bias Cards in Shadows", Range(0.0, 1.0)) = 0.05
        _RandomSeed("Random Seed", Integer) = 0

        //VRC Fallback
        _MainTex("VRC Fallback Unlit Color Texture", 2D) = "black" {}
    }

    CustomEditor "FeathersAndFurShaderGUI"

    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry" "IgnoreProjector" = "True" "VRCFallback" = "Unlit"}

        //Undercoat Base Pass
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            Cull [_UndercoatCullMode]
            ZWrite On
            ZTest LEqual
            Blend Off

            HLSLPROGRAM

            #pragma target 5.0
            #pragma multi_compile_fwdbase novertexlight nolightmap nodynlightmap nodirlightmap
            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            #pragma shader_feature_local_fragment __ _LIGHT_VOLUMES_ON
            #pragma shader_feature_local_fragment __ _PURPZIE_GRYPHON_AUDIOLINK_ON
            #pragma shader_feature_local_fragment __ _COLOR_ADJUST_ON

            #define BASE_LIGHTING_PASS
            #define UNDERCOAT_PASS

            #pragma vertex BaseVertexShader
            #pragma fragment BasePixelShader

            #include "Helpers/FeathersAndFurUndercoatPassHelper.hlsl"

            ENDHLSL
        }

        //Coat Base Pass
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            Cull Off
            ZWrite On
            ZTest LEqual
            Blend Off

            HLSLPROGRAM

            #pragma target 5.0
            #pragma multi_compile_fwdbase novertexlight nolightmap nodynlightmap nodirlightmap
            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            #pragma shader_feature_local_fragment __ _LIGHT_VOLUMES_ON
            #pragma shader_feature_local_fragment __ _PURPZIE_GRYPHON_AUDIOLINK_ON
            #pragma shader_feature_local_fragment __ _COLOR_ADJUST_ON

            #define BASE_LIGHTING_PASS
            #define COAT_PASS
            #pragma shader_feature_local __ _BINDPOSEUVCHANNEL_UV2 _BINDPOSEUVCHANNEL_UV3 _BINDPOSEUVCHANNEL_UV4 _BINDPOSEUVCHANNEL_UV5 _BINDPOSEUVCHANNEL_UV6 _BINDPOSEUVCHANNEL_UV7 _BINDPOSEUVCHANNEL_UV8

            #pragma vertex CardGenerationVertexShader
            #pragma hull CardGenerationHullShader
            #pragma domain CardGenerationDomainShader
            #pragma geometry CoatGeometryShader
            #pragma fragment CoatPixelShader

            #include "Helpers/FeathersAndFurCoatPassHelper.hlsl"

            ENDHLSL
        }

        //Undercoat Additive Pass
        Pass
        {
            Tags { "LightMode" = "ForwardAdd" }

            Cull [_UndercoatCullMode]
            ZWrite Off
            ZTest Equal
            Blend One One, Zero One
            Fog { Color(0,0,0,0) }

            HLSLPROGRAM

            #pragma target 5.0
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_instancing
            #pragma multi_compile_fog

            #pragma shader_feature_local_fragment __ _COLOR_ADJUST_ON

            #pragma vertex BaseVertexShader
            #pragma fragment BasePixelShader

            #include "Helpers/FeathersAndFurUndercoatPassHelper.hlsl"

            ENDHLSL
        }

        //Coat Additive Pass
        Pass
        {
            Tags { "LightMode" = "ForwardAdd" }

            Cull Off
            ZWrite Off
            ZTest Equal
            Blend One One, Zero One
            Fog { Color(0,0,0,0) }

            HLSLPROGRAM

            #pragma target 5.0
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_instancing
            #pragma multi_compile_fog

            #pragma shader_feature_local __ _BINDPOSEUVCHANNEL_UV2 _BINDPOSEUVCHANNEL_UV3 _BINDPOSEUVCHANNEL_UV4 _BINDPOSEUVCHANNEL_UV5 _BINDPOSEUVCHANNEL_UV6 _BINDPOSEUVCHANNEL_UV7 _BINDPOSEUVCHANNEL_UV8
            #pragma shader_feature_local_fragment __ _COLOR_ADJUST_ON

            #pragma vertex CardGenerationVertexShader
            #pragma hull CardGenerationHullShader
            #pragma domain CardGenerationDomainShader
            #pragma geometry CoatGeometryShader
            #pragma fragment CoatPixelShader

            #include "Helpers/FeathersAndFurCoatPassHelper.hlsl"

            ENDHLSL
        }

        //Shadowcaster Pass
        Pass
        {
            Tags { "LightMode" = "ShadowCaster" }

            Cull Off
            ZWrite On
            ZTest LEqual
            Blend Off

            HLSLPROGRAM

            #pragma target 5.0
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing

            #define DEPTH_ONLY_PASS
            #pragma shader_feature_local __ _BINDPOSEUVCHANNEL_UV2 _BINDPOSEUVCHANNEL_UV3 _BINDPOSEUVCHANNEL_UV4 _BINDPOSEUVCHANNEL_UV5 _BINDPOSEUVCHANNEL_UV6 _BINDPOSEUVCHANNEL_UV7 _BINDPOSEUVCHANNEL_UV8

            #pragma vertex CardGenerationVertexShader
            #pragma hull CardGenerationHullShader
            #pragma domain CardGenerationDomainShader
            #pragma geometry ShadowGeometryShader
            #pragma fragment ShadowPixelShader

            #include "Helpers/FeathersAndFurShadowPassHelper.hlsl"

            ENDHLSL
        }
    }
}
