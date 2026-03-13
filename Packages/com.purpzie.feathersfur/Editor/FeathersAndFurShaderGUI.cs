using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

//used for shader properties
namespace FeathersAndFurShaderEnums
{
    enum CardMaterialBlendMode
    {
        Off = 0,
        Override = 1,
        Additive = 2,
        Subtractive = 3,
        Multiply = 4,
        Screen = 5,
        Min = 6,
        Max = 7,
        AlphaBlendAlbedoSource = 8,
        AlphaBlendEmissiveSource = 9
    };
}

internal class FeathersAndFurShaderGUI : ShaderGUI
{
    //Constants ------------------------------------------------------------------------------------

    private static readonly Type cCoatPaintingToolType = Type.GetType("FeathersAndFurCoatPaintingTool");
    private static readonly Type cClothingMaskEditorType = Type.GetType("FeathersAndFurClothingMaskEditor");

    //Structs --------------------------------------------------------------------------------------

    private struct Foldouts
    {
        public bool forkOptions;

        public bool cards;
        public bool cardsCoat;
        public bool cardsTextures;
        public bool cardsCutout;
        public bool cardsSpacing;
        public bool cardsLength;
        public bool cardsWidth;
        public bool cardsAdjustment;
        public bool cardsRotation;
        public bool cardsBillboarding;

        public bool color;
        public bool colorUndercoat;
        public bool colorCoat;
        public bool colorCard;

        public bool emission;
        public bool emissionUndercoat;
        public bool emissionCoat;
        public bool emissionCard;

        public bool materialParameters;
        public bool materialParametersUndercoat;
        public bool materialParametersCoat;
        public bool materialParametersCard;

        public bool additionalMaterialParameters;
        public bool additionalMaterialParametersUndercoat;
        public bool additionalMaterialParametersCoat;

        public bool normals;
        public bool normalsUndercoat;
        public bool normalsCoat;
        public bool normalsCard;

        public bool clothing;
        public bool clothingMaskFull;
        public bool clothingMaskPacked;
        public bool clothingMaskPackedModesA;
        public bool clothingMaskPackedModesB;
        public bool clothingMaskPackedModesC;
        public bool clothingMaskPackedModesD;
        public bool clothingCutout;

        public bool lighting;
        public bool lightingSelfShadow;
        public bool lightingFur;
        public bool lightingDiffuse;
        public bool lightingSpecular;
        public bool lightingAmbient;
        public bool lightingProbes;
        public bool lightingMiscellaneous;

        public bool optimization;
        public bool optimizationTexture;
        public bool optimizationLod;
        public bool optimizationFade;
        public bool optimizationOffScreen;

        public bool miscellaneous;
        public bool miscellaneousSkinning;
        public bool miscellaneousOptions;
        public bool miscellaneousFallback;

        public Foldouts(bool dummy)
        {
            forkOptions = true;

            cards = true;
            cardsCoat = true;
            cardsTextures = true;
            cardsCutout = true;
            cardsSpacing = true;
            cardsLength = true;
            cardsWidth = true;
            cardsAdjustment = true;
            cardsRotation = true;
            cardsBillboarding = true;

            color = true;
            colorUndercoat = true;
            colorCoat = true;
            colorCard = true;

            emission = true;
            emissionUndercoat = true;
            emissionCoat = true;
            emissionCard = true;

            materialParameters = true;
            materialParametersUndercoat = true;
            materialParametersCoat = true;
            materialParametersCard = true;

            additionalMaterialParameters = true;
            additionalMaterialParametersUndercoat = true;
            additionalMaterialParametersCoat = true;

            normals = true;
            normalsUndercoat = true;
            normalsCoat = true;
            normalsCard = true;

            clothing = true;
            clothingMaskFull = true;
            clothingMaskPacked = true;
            clothingMaskPackedModesA = false;
            clothingMaskPackedModesB = false;
            clothingMaskPackedModesC = false;
            clothingMaskPackedModesD = false;
            clothingCutout = true;

            lighting = true;
            lightingSelfShadow = true;
            lightingFur = true;
            lightingDiffuse = true;
            lightingSpecular = true;
            lightingAmbient = true;
            lightingProbes = true;
            lightingMiscellaneous = true;

            optimization = true;
            optimizationTexture = true;
            optimizationLod = true;
            optimizationFade = true;
            optimizationOffScreen = true;

            miscellaneous = true;
            miscellaneousSkinning = true;
            miscellaneousOptions = true;
            miscellaneousFallback = true;
        }
    }

    private struct UndercoatAndCoatLinkingToggles
    {
        public bool color;
        public bool emission;
        public bool materialParameters;
        public bool additionalMaterialParameters;
        public bool normals;

        public UndercoatAndCoatLinkingToggles(bool dummy)
        {
            color = true;
            emission = true;
            materialParameters = true;
            additionalMaterialParameters = true;
            normals = true;
        }
    }

    private struct FeathersAndFurMaterialProperties
    {
        //Fur Cards

        public MaterialProperty coatParametersTexture;
        public MaterialProperty coatDirectionTexture;

        public MaterialProperty cardAtlasTextureCount;
        public MaterialProperty cardAtlasTexturesPerRow;

        public MaterialProperty cardCutoutTexture;
        public MaterialProperty cardCutoutTextureAtlasEnabled;
        public MaterialProperty cardCutoutThreshold;

        public MaterialProperty cardSizeMin;
        public MaterialProperty cardSizeMax;

        public MaterialProperty cardShapeLengthMin;
        public MaterialProperty cardShapeLengthMax;
        public MaterialProperty cardShapeLengthCurve;

        public MaterialProperty cardShapeWidthMin;
        public MaterialProperty cardShapeWidthMax;
        public MaterialProperty cardShapeWidthCurve;

        public MaterialProperty cardElevationMin;
        public MaterialProperty cardElevationMax;
        public MaterialProperty cardElevationRandomness;
        public MaterialProperty cardOrientationRandomness;

        public MaterialProperty cardRotationRandomnessMin;
        public MaterialProperty cardRotationRandomnessMax;
        public MaterialProperty cardRotationRandomnessElevationStart;
        public MaterialProperty cardRotationRandomnessElevationEnd;

        public MaterialProperty cardBillboardingMin;
        public MaterialProperty cardBillboardingMax;
        public MaterialProperty cardBillboardingElevationStart;
        public MaterialProperty cardBillboardingElevationEnd;
        public MaterialProperty cardBillboardingSizeStart;
        public MaterialProperty cardBillboardingSizeEnd;

        //Color

        public MaterialProperty undercoatAlbedoTexture;
        public MaterialProperty undercoatAlbedoTint;
        public MaterialProperty undercoatCutoutEnabled;
        public MaterialProperty undercoatCutoutThreshold;

        public MaterialProperty coatAlbedoTexture;
        public MaterialProperty coatAlbedoTint;
        public MaterialProperty coatCutoutEnabled;
        public MaterialProperty coatCutoutThreshold;

        public MaterialProperty cardAlbedoTexture;
        public MaterialProperty cardAlbedoTextureAtlasEnabled;
        public MaterialProperty cardAlbedoTint;
        public MaterialProperty cardAlbedoBlendMode;

        //Emission

        public MaterialProperty undercoatEmissionTexture;
        public MaterialProperty undercoatEmissionTint;

        public MaterialProperty coatEmissionTexture;
        public MaterialProperty coatEmissionTint;

        public MaterialProperty cardEmissionTexture;
        public MaterialProperty cardEmissionTextureAtlasEnabled;
        public MaterialProperty cardEmissionTint;
        public MaterialProperty cardEmissionBlendMode;

        //Material Parameters

        public MaterialProperty undercoatMaterialParametersTexture;
        public MaterialProperty undercoatReflectivenessMin;
        public MaterialProperty undercoatReflectivenessMax;
        public MaterialProperty undercoatRoughnessMin;
        public MaterialProperty undercoatRoughnessMax;
        public MaterialProperty undercoatIridescentThicknessMin;
        public MaterialProperty undercoatIridescentThicknessMax;
        public MaterialProperty undercoatAmbientOcclusionMin;
        public MaterialProperty undercoatAmbientOcclusionMax;

        public MaterialProperty coatMaterialParametersTexture;
        public MaterialProperty coatReflectivenessMin;
        public MaterialProperty coatReflectivenessMax;
        public MaterialProperty coatRoughnessMin;
        public MaterialProperty coatRoughnessMax;
        public MaterialProperty coatIridescentThicknessMin;
        public MaterialProperty coatIridescentThicknessMax;
        public MaterialProperty coatAmbientOcclusionMin;
        public MaterialProperty coatAmbientOcclusionMax;

        public MaterialProperty cardMaterialParametersTexture;
        public MaterialProperty cardMaterialParametersTextureAtlasEnabled;
        public MaterialProperty cardReflectivenessMin;
        public MaterialProperty cardReflectivenessMax;
        public MaterialProperty cardReflectivenessBlendMode;
        public MaterialProperty cardRoughnessMin;
        public MaterialProperty cardRoughnessMax;
        public MaterialProperty cardRoughnessBlendMode;
        public MaterialProperty cardIridescentThicknessMin;
        public MaterialProperty cardIridescentThicknessMax;
        public MaterialProperty cardIridescentThicknessBlendMode;
        public MaterialProperty cardAmbientOcclusionMin;
        public MaterialProperty cardAmbientOcclusionMax;
        public MaterialProperty cardAmbientOcclusionBlendMode;

        //Additional Material Parameters

        public MaterialProperty undercoatAdditionalMaterialParametersTexture;
        public MaterialProperty undercoatFurnessReadCoatParametersMask;
        public MaterialProperty undercoatFurnessMin;
        public MaterialProperty undercoatFurnessMax;
        public MaterialProperty undercoatDiameterMin;
        public MaterialProperty undercoatDiameterMax;
        public MaterialProperty undercoatSelfShadowMaskMin;
        public MaterialProperty undercoatSelfShadowMaskMax;
        public MaterialProperty undercoatAmbientTransmissionOcclusionMin;
        public MaterialProperty undercoatAmbientTransmissionOcclusionMax;

        public MaterialProperty coatAdditionalMaterialParametersTexture;
        public MaterialProperty coatFurnessMin;
        public MaterialProperty coatFurnessMax;
        public MaterialProperty coatDiameterMin;
        public MaterialProperty coatDiameterMax;
        public MaterialProperty coatSelfShadowMaskMin;
        public MaterialProperty coatSelfShadowMaskMax;
        public MaterialProperty coatAmbientTransmissionOcclusionMin;
        public MaterialProperty coatAmbientTransmissionOcclusionMax;

        //Normals, Fur Tangents, and Anisotropy

        public MaterialProperty undercoatNormalTexture;
        public MaterialProperty undercoatNormalStrength;
        public MaterialProperty undercoatNormalFurInfluence;

        public MaterialProperty undercoatAnisotropyTexture;
        public MaterialProperty undercoatAnisotropyFlattenFurTangents;
        public MaterialProperty undercoatAnisotropyStrength;

        public MaterialProperty undercoatFurRootNormalTexture;
        public MaterialProperty undercoatFurRootNormalStrength;
        public MaterialProperty undercoatFurRootNormalDiffuseInfluence;

        public MaterialProperty coatFurRootNormalTexture;
        public MaterialProperty coatFurRootNormalStrength;
        public MaterialProperty coatFurRootNormalDiffuseInfluence;

        public MaterialProperty cardNormalTexture;
        public MaterialProperty cardNormalTextureAtlasEnabled;
        public MaterialProperty cardNormalStrength;
        public MaterialProperty cardNormalFurInfluence;

        public MaterialProperty cardAnisotropyTexture;
        public MaterialProperty cardAnisotropyTextureAtlasEnabled;
        public MaterialProperty cardAnisotropyFlattenFurTangents;
        public MaterialProperty cardAnisotropyStrength;

        //Clothing

        public MaterialProperty clothingMaskFullTexture;
        public MaterialProperty clothingMaskFullRedChannelMode;
        public MaterialProperty clothingMaskFullGreenChannelMode;
        public MaterialProperty clothingMaskFullBlueChannelMode;
        public MaterialProperty clothingMaskFullAlphaChannelMode;

        public MaterialProperty clothingMaskPackedTexture;
        public MaterialProperty clothingMaskPackedUvWrapEnabled;
        public MaterialProperty[] clothingMaskPackedModes;

        public MaterialProperty clothingMaskCutoutThreshold;

        //Lighting

        public MaterialProperty selfShadowColoredStrength;
        public MaterialProperty selfShadowUncoloredStrength;
        public MaterialProperty selfShadowNonFurStrengthMultiplier;
        public MaterialProperty selfShadowCardTipOpacity;

        public MaterialProperty furDirectLightingOcclusion;
        public MaterialProperty furShift;
        public MaterialProperty furRemapStart;
        public MaterialProperty furRemapEnd;
        public MaterialProperty furBaselineReflectiveness;
        public MaterialProperty furFresnelStrength;
        public MaterialProperty furIridescenceLUT;

        public MaterialProperty diffuseRoughnessInfluence;
        public MaterialProperty diffuseRemapStart;
        public MaterialProperty diffuseRemapEnd;

        public MaterialProperty specularBaselineReflectiveness;
        public MaterialProperty specularFresnelStrength;
        public MaterialProperty specularIridescenceLUT;

        public MaterialProperty ambientLightingOverrideMode;
        public MaterialProperty ambientLightingOverrideColor;
        public MaterialProperty furAmbientLightingDirectionality;
        public MaterialProperty diffuseAmbientLightingDirectionality;

        public MaterialProperty furCustomReflectionProbeEnabled;
        public MaterialProperty furCustomReflectionProbe;
        public MaterialProperty furCustomTransmissionProbeEnabled;
        public MaterialProperty furCustomTransmissionProbe;
        public MaterialProperty specularCustomReflectionProbeEnabled;
        public MaterialProperty specularCustomReflectionProbe;

        public MaterialProperty brightnessClamp;

        //Optimization

        public MaterialProperty coatOptimizationTexture;

        public MaterialProperty cardLodFactor;
        public MaterialProperty cardLodGrowth;
        public MaterialProperty cardLodFixedResolutionEnabled;
        public MaterialProperty cardLodFixedResolution;
        public MaterialProperty cardLodSpacingMin;
        public MaterialProperty cardLodSpacingMax;
        public MaterialProperty cardLodShadowSpacingMin;

        public MaterialProperty cardFadeStart;
        public MaterialProperty cardFadeLength;

        public MaterialProperty cardRenderInMirrors;
        public MaterialProperty cardRenderInShadows;

        //Miscellaneous

        public MaterialProperty bindPoseUvChannel;
        public MaterialProperty skinnedMeshScaleFixupEnabled;
        public MaterialProperty cardRescale;

        public MaterialProperty undercoatCullMode;
        public MaterialProperty undercoatShadowCullMode;
        public MaterialProperty cardShadowBias;
        public MaterialProperty randomSeed;

        public MaterialProperty fallbackTexture;

        // Fork options
        public MaterialProperty lightVolumes;
        public MaterialProperty colorAdjust;
        public MaterialProperty colorAdjustHue;
        public MaterialProperty colorAdjustSaturation;
        public MaterialProperty colorAdjustValue;
        public MaterialProperty purpzieGryphonAudiolink;
        public MaterialProperty purpzieGryphonAudiolinkTexture;

        public FeathersAndFurMaterialProperties(MaterialProperty[] props)
        {
            // Fork options
            lightVolumes = FindProperty("_LIGHT_VOLUMES", props);
            colorAdjust = FindProperty("_COLOR_ADJUST", props);
            colorAdjustHue = FindProperty("_ColorAdjustHue", props);
            colorAdjustSaturation = FindProperty("_ColorAdjustSaturation", props);
            colorAdjustValue = FindProperty("_ColorAdjustValue", props);
            purpzieGryphonAudiolink = FindProperty("_PURPZIE_GRYPHON_AUDIOLINK", props);
            purpzieGryphonAudiolinkTexture = FindProperty("_PurpzieGryphonAudiolinkTexture", props);

            //Fur Cards

            coatParametersTexture = FindProperty("_CoatParametersTexture", props);
            coatDirectionTexture = FindProperty("_CoatDirectionTexture", props);

            cardAtlasTextureCount = FindProperty("_CardAtlasTextureCount", props);
            cardAtlasTexturesPerRow = FindProperty("_CardAtlasTexturesPerRow", props);

            cardCutoutTexture = FindProperty("_CardCutoutTexture", props);
            cardCutoutTextureAtlasEnabled = FindProperty("_CardCutoutTextureAtlasEnabled", props);
            cardCutoutThreshold = FindProperty("_CardCutoutThreshold", props);

            cardSizeMin = FindProperty("_CardSizeMin", props);
            cardSizeMax = FindProperty("_CardSizeMax", props);

            cardShapeLengthMin = FindProperty("_CardShapeLengthMin", props);
            cardShapeLengthMax = FindProperty("_CardShapeLengthMax", props);
            cardShapeLengthCurve = FindProperty("_CardShapeLengthCurve", props);

            cardShapeWidthMin = FindProperty("_CardShapeWidthMin", props);
            cardShapeWidthMax = FindProperty("_CardShapeWidthMax", props);
            cardShapeWidthCurve = FindProperty("_CardShapeWidthCurve", props);

            cardElevationMin = FindProperty("_CardElevationMin", props);
            cardElevationMax = FindProperty("_CardElevationMax", props);
            cardElevationRandomness = FindProperty("_CardElevationRandomness", props);
            cardOrientationRandomness = FindProperty("_CardOrientationRandomness", props);

            cardRotationRandomnessMin = FindProperty("_CardRotationRandomnessMin", props);
            cardRotationRandomnessMax = FindProperty("_CardRotationRandomnessMax", props);
            cardRotationRandomnessElevationStart = FindProperty("_CardRotationRandomnessElevationStart", props);
            cardRotationRandomnessElevationEnd = FindProperty("_CardRotationRandomnessElevationEnd", props);

            cardBillboardingMin = FindProperty("_CardBillboardingMin", props);
            cardBillboardingMax = FindProperty("_CardBillboardingMax", props);
            cardBillboardingElevationStart = FindProperty("_CardBillboardingElevationStart", props);
            cardBillboardingElevationEnd = FindProperty("_CardBillboardingElevationEnd", props);
            cardBillboardingSizeStart = FindProperty("_CardBillboardingSizeStart", props);
            cardBillboardingSizeEnd = FindProperty("_CardBillboardingSizeEnd", props);

            //Color

            undercoatAlbedoTexture = FindProperty("_UndercoatAlbedoTexture", props);
            undercoatAlbedoTint = FindProperty("_UndercoatAlbedoTint", props);
            undercoatCutoutEnabled = FindProperty("_UndercoatCutoutEnabled", props);
            undercoatCutoutThreshold = FindProperty("_UndercoatCutoutThreshold", props);

            coatAlbedoTexture = FindProperty("_CoatAlbedoTexture", props);
            coatAlbedoTint = FindProperty("_CoatAlbedoTint", props);
            coatCutoutEnabled = FindProperty("_CoatCutoutEnabled", props);
            coatCutoutThreshold = FindProperty("_CoatCutoutThreshold", props);

            cardAlbedoTexture = FindProperty("_CardAlbedoTexture", props);
            cardAlbedoTextureAtlasEnabled = FindProperty("_CardAlbedoTextureAtlasEnabled", props);
            cardAlbedoTint = FindProperty("_CardAlbedoTint", props);
            cardAlbedoBlendMode = FindProperty("_CardAlbedoBlendMode", props);

            //Emission

            undercoatEmissionTexture = FindProperty("_UndercoatEmissionTexture", props);
            undercoatEmissionTint = FindProperty("_UndercoatEmissionTint", props);

            coatEmissionTexture = FindProperty("_CoatEmissionTexture", props);
            coatEmissionTint = FindProperty("_CoatEmissionTint", props);

            cardEmissionTexture = FindProperty("_CardEmissionTexture", props);
            cardEmissionTextureAtlasEnabled = FindProperty("_CardEmissionTextureAtlasEnabled", props);
            cardEmissionTint = FindProperty("_CardEmissionTint", props);
            cardEmissionBlendMode = FindProperty("_CardEmissionBlendMode", props);

            //Material Parameters

            undercoatMaterialParametersTexture = FindProperty("_UndercoatMaterialParametersTexture", props);
            undercoatReflectivenessMin = FindProperty("_UndercoatReflectivenessMin", props);
            undercoatReflectivenessMax = FindProperty("_UndercoatReflectivenessMax", props);
            undercoatRoughnessMin = FindProperty("_UndercoatRoughnessMin", props);
            undercoatRoughnessMax = FindProperty("_UndercoatRoughnessMax", props);
            undercoatIridescentThicknessMin = FindProperty("_UndercoatIridescentThicknessMin", props);
            undercoatIridescentThicknessMax = FindProperty("_UndercoatIridescentThicknessMax", props);
            undercoatAmbientOcclusionMin = FindProperty("_UndercoatAmbientOcclusionMin", props);
            undercoatAmbientOcclusionMax = FindProperty("_UndercoatAmbientOcclusionMax", props);

            coatMaterialParametersTexture = FindProperty("_CoatMaterialParametersTexture", props);
            coatReflectivenessMin = FindProperty("_CoatReflectivenessMin", props);
            coatReflectivenessMax = FindProperty("_CoatReflectivenessMax", props);
            coatRoughnessMin = FindProperty("_CoatRoughnessMin", props);
            coatRoughnessMax = FindProperty("_CoatRoughnessMax", props);
            coatIridescentThicknessMin = FindProperty("_CoatIridescentThicknessMin", props);
            coatIridescentThicknessMax = FindProperty("_CoatIridescentThicknessMax", props);
            coatAmbientOcclusionMin = FindProperty("_CoatAmbientOcclusionMin", props);
            coatAmbientOcclusionMax = FindProperty("_CoatAmbientOcclusionMax", props);

            cardMaterialParametersTexture = FindProperty("_CardMaterialParametersTexture", props);
            cardMaterialParametersTextureAtlasEnabled = FindProperty("_CardMaterialParametersTextureAtlasEnabled", props);
            cardReflectivenessMin = FindProperty("_CardReflectivenessMin", props);
            cardReflectivenessMax = FindProperty("_CardReflectivenessMax", props);
            cardReflectivenessBlendMode = FindProperty("_CardReflectivenessBlendMode", props);
            cardRoughnessMin = FindProperty("_CardRoughnessMin", props);
            cardRoughnessMax = FindProperty("_CardRoughnessMax", props);
            cardRoughnessBlendMode = FindProperty("_CardRoughnessBlendMode", props);
            cardIridescentThicknessMin = FindProperty("_CardIridescentThicknessMin", props);
            cardIridescentThicknessMax = FindProperty("_CardIridescentThicknessMax", props);
            cardIridescentThicknessBlendMode = FindProperty("_CardIridescentThicknessBlendMode", props);
            cardAmbientOcclusionMin = FindProperty("_CardAmbientOcclusionMin", props);
            cardAmbientOcclusionMax = FindProperty("_CardAmbientOcclusionMax", props);
            cardAmbientOcclusionBlendMode = FindProperty("_CardAmbientOcclusionBlendMode", props);

            //Additional Material Parameters

            undercoatAdditionalMaterialParametersTexture = FindProperty("_UndercoatAdditionalMaterialParametersTexture", props);
            undercoatFurnessReadCoatParametersMask = FindProperty("_UndercoatFurnessReadCoatParametersMask", props);
            undercoatFurnessMin = FindProperty("_UndercoatFurnessMin", props);
            undercoatFurnessMax = FindProperty("_UndercoatFurnessMax", props);
            undercoatDiameterMin = FindProperty("_UndercoatDiameterMin", props);
            undercoatDiameterMax = FindProperty("_UndercoatDiameterMax", props);
            undercoatSelfShadowMaskMin = FindProperty("_UndercoatSelfShadowMaskMin", props);
            undercoatSelfShadowMaskMax = FindProperty("_UndercoatSelfShadowMaskMax", props);
            undercoatAmbientTransmissionOcclusionMin = FindProperty("_UndercoatAmbientTransmissionOcclusionMin", props);
            undercoatAmbientTransmissionOcclusionMax = FindProperty("_UndercoatAmbientTransmissionOcclusionMax", props);

            coatAdditionalMaterialParametersTexture = FindProperty("_CoatAdditionalMaterialParametersTexture", props);
            coatFurnessMin = FindProperty("_CoatFurnessMin", props);
            coatFurnessMax = FindProperty("_CoatFurnessMax", props);
            coatDiameterMin = FindProperty("_CoatDiameterMin", props);
            coatDiameterMax = FindProperty("_CoatDiameterMax", props);
            coatSelfShadowMaskMin = FindProperty("_CoatSelfShadowMaskMin", props);
            coatSelfShadowMaskMax = FindProperty("_CoatSelfShadowMaskMax", props);
            coatAmbientTransmissionOcclusionMin = FindProperty("_CoatAmbientTransmissionOcclusionMin", props);
            coatAmbientTransmissionOcclusionMax = FindProperty("_CoatAmbientTransmissionOcclusionMax", props);

            //Normals, Fur Tangents, and Anisotropy

            undercoatNormalTexture = FindProperty("_UndercoatNormalTexture", props);
            undercoatNormalStrength = FindProperty("_UndercoatNormalStrength", props);
            undercoatNormalFurInfluence = FindProperty("_UndercoatNormalFurInfluence", props);

            undercoatAnisotropyTexture = FindProperty("_UndercoatAnisotropyTexture", props);
            undercoatAnisotropyFlattenFurTangents = FindProperty("_UndercoatAnisotropyFlattenFurTangents", props);
            undercoatAnisotropyStrength = FindProperty("_UndercoatAnisotropyStrength", props);

            undercoatFurRootNormalTexture = FindProperty("_UndercoatFurRootNormalTexture", props);
            undercoatFurRootNormalStrength = FindProperty("_UndercoatFurRootNormalStrength", props);
            undercoatFurRootNormalDiffuseInfluence = FindProperty("_UndercoatFurRootNormalDiffuseInfluence", props);

            coatFurRootNormalTexture = FindProperty("_CoatFurRootNormalTexture", props);
            coatFurRootNormalStrength = FindProperty("_CoatFurRootNormalStrength", props);
            coatFurRootNormalDiffuseInfluence = FindProperty("_CoatFurRootNormalDiffuseInfluence", props);

            cardNormalTexture = FindProperty("_CardNormalTexture", props);
            cardNormalTextureAtlasEnabled = FindProperty("_CardNormalTextureAtlasEnabled", props);
            cardNormalStrength = FindProperty("_CardNormalStrength", props);
            cardNormalFurInfluence = FindProperty("_CardNormalFurInfluence", props);

            cardAnisotropyTexture = FindProperty("_CardAnisotropyTexture", props);
            cardAnisotropyTextureAtlasEnabled = FindProperty("_CardAnisotropyTextureAtlasEnabled", props);
            cardAnisotropyFlattenFurTangents = FindProperty("_CardAnisotropyFlattenFurTangents", props);
            cardAnisotropyStrength = FindProperty("_CardAnisotropyStrength", props);

            //Clothing

            clothingMaskFullTexture = FindProperty("_ClothingMaskFullTexture", props);
            clothingMaskFullRedChannelMode = FindProperty("_ClothingMaskFullRedChannelMode", props);
            clothingMaskFullGreenChannelMode = FindProperty("_ClothingMaskFullGreenChannelMode", props);
            clothingMaskFullBlueChannelMode = FindProperty("_ClothingMaskFullBlueChannelMode", props);
            clothingMaskFullAlphaChannelMode = FindProperty("_ClothingMaskFullAlphaChannelMode", props);

            clothingMaskPackedTexture = FindProperty("_ClothingMaskPackedTexture", props);
            clothingMaskPackedUvWrapEnabled = FindProperty("_ClothingMaskPackedUvWrapEnabled", props);

            clothingMaskPackedModes = new MaterialProperty[32];
            for(int index = 0; index < 32; index++)
            {
                clothingMaskPackedModes[index] = FindProperty("_ClothingMaskPacked" + index + "BitMode", props);
            }

            clothingMaskCutoutThreshold = FindProperty("_ClothingMaskCutoutThreshold", props);

            //Lighting

            selfShadowColoredStrength = FindProperty("_SelfShadowColoredStrength", props);
            selfShadowUncoloredStrength = FindProperty("_SelfShadowUncoloredStrength", props);
            selfShadowNonFurStrengthMultiplier = FindProperty("_SelfShadowNonFurStrengthMultiplier", props);
            selfShadowCardTipOpacity = FindProperty("_SelfShadowCardTipOpacity", props);

            furDirectLightingOcclusion = FindProperty("_FurDirectLightingOcclusion", props);
            furShift = FindProperty("_FurShift", props);
            furRemapStart = FindProperty("_FurRemapStart", props);
            furRemapEnd = FindProperty("_FurRemapEnd", props);
            furBaselineReflectiveness = FindProperty("_FurBaselineReflectiveness", props);
            furFresnelStrength = FindProperty("_FurFresnelStrength", props);
            furIridescenceLUT = FindProperty("_FurIridescenceLUT", props);

            diffuseRoughnessInfluence = FindProperty("_DiffuseRoughnessInfluence", props);
            diffuseRemapStart = FindProperty("_DiffuseRemapStart", props);
            diffuseRemapEnd = FindProperty("_DiffuseRemapEnd", props);

            specularBaselineReflectiveness = FindProperty("_SpecularBaselineReflectiveness", props);
            specularFresnelStrength = FindProperty("_SpecularFresnelStrength", props);
            specularIridescenceLUT = FindProperty("_SpecularIridescenceLUT", props);

            ambientLightingOverrideMode = FindProperty("_AmbientLightingOverrideMode", props);
            ambientLightingOverrideColor = FindProperty("_AmbientLightingOverrideColor", props);
            furAmbientLightingDirectionality = FindProperty("_FurAmbientLightingDirectionality", props);
            diffuseAmbientLightingDirectionality = FindProperty("_DiffuseAmbientLightingDirectionality", props);

            furCustomReflectionProbeEnabled = FindProperty("_FurCustomReflectionProbeEnabled", props);
            furCustomReflectionProbe = FindProperty("_FurCustomReflectionProbe", props);
            furCustomTransmissionProbeEnabled = FindProperty("_FurCustomTransmissionProbeEnabled", props);
            furCustomTransmissionProbe = FindProperty("_FurCustomTransmissionProbe", props);
            specularCustomReflectionProbeEnabled = FindProperty("_SpecularCustomReflectionProbeEnabled", props);
            specularCustomReflectionProbe = FindProperty("_SpecularCustomReflectionProbe", props);

            brightnessClamp = FindProperty("_BrightnessClamp", props);

            //Optimization

            coatOptimizationTexture = FindProperty("_CoatOptimizationTexture", props);

            cardLodFactor = FindProperty("_CardLodFactor", props);
            cardLodGrowth = FindProperty("_CardLodGrowth", props);
            cardLodFixedResolutionEnabled = FindProperty("_CardLodFixedResolutionEnabled", props);
            cardLodFixedResolution = FindProperty("_CardLodFixedResolution", props);
            cardLodSpacingMax = FindProperty("_CardLodSpacingMax", props);
            cardLodSpacingMin = FindProperty("_CardLodSpacingMin", props);
            cardLodShadowSpacingMin = FindProperty("_CardLodShadowSpacingMin", props);

            cardFadeStart = FindProperty("_CardFadeStart", props);
            cardFadeLength = FindProperty("_CardFadeLength", props);

            cardRenderInMirrors = FindProperty("_CardRenderInMirrors", props);
            cardRenderInShadows = FindProperty("_CardRenderInShadows", props);

            //Miscellaneous

            bindPoseUvChannel = FindProperty("_BindPoseUvChannel", props);
            skinnedMeshScaleFixupEnabled = FindProperty("_SkinnedMeshScaleFixupEnabled", props);
            cardRescale = FindProperty("_CardRescale", props);

            undercoatCullMode = FindProperty("_UndercoatCullMode", props);
            undercoatShadowCullMode = FindProperty("_UndercoatShadowCullMode", props);
            cardShadowBias = FindProperty("_CardShadowBias", props);
            randomSeed = FindProperty("_RandomSeed", props);

            fallbackTexture = FindProperty("_MainTex", props);
        }
    };

    //Variables ------------------------------------------------------------------------------------

    private static Foldouts sFoldouts = new Foldouts(true);
    private static bool sShowPerformanceWarnings = true;

    private UndercoatAndCoatLinkingToggles mLinkingToggles = new UndercoatAndCoatLinkingToggles(true);

    //Main GUI Functions ---------------------------------------------------------------------------

    //called when the shader inspector is drawn
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
        FeathersAndFurMaterialProperties properties = new FeathersAndFurMaterialProperties(props);

        DrawShaderInspector(materialEditor, properties);
    }

    //create all the GUI for the shader inspector, and return if any changes were made
    private bool DrawShaderInspector(MaterialEditor materialEditor, FeathersAndFurMaterialProperties properties)
    {
        const float cMinCardSizeBeforePerformanceWarning = 0.0025f;
        const float cMaxCardLengthBeforePerformanceWarning = 10.0f;
        const float cMaxCardWidthBeforePerformanceWarning = 5.0f;

        //match unity default inspector formatting
        EditorGUIUtility.labelWidth = 0.0f;
        EditorGUIUtility.fieldWidth = 64.0f;
        FeathersAndFurToolUtilities.sFoldoutIndentBackgroundCorrection = 20.0f;

        //if this material is being viewed on a renderer, get that renderer
        Renderer targetRenderer = null;
        if (Selection.activeGameObject)
        {
            targetRenderer = Selection.activeGameObject.GetComponent<Renderer>();
        }

        EditorGUI.BeginChangeCheck();

        //Detect Configuration Errors --------------------------------------------------------------

        //if this material has a coat parameters texture but no optimization texture baked
        //display a warning and add a button to open the optimization texture baker
        if (properties.coatParametersTexture.textureValue != null && properties.coatOptimizationTexture.textureValue == null)
        {
            EditorGUILayout.HelpBox("No optimization texture set! " +
                                    "Once you are done editing the Card Parameters texture, " +
                                    "bake an optimization texture to improve performance!", MessageType.Warning);

            BakeOptimizationTextureToolButton(materialEditor);

            EditorGUILayout.Space();
        }

        //get the bind pose uv channel index
        int bindUvChannel = (int)properties.bindPoseUvChannel.floatValue;

        //if the bind pose is disabled and this material is being viewed on a skinned mesh renderer
        //display a warning and add a button to open the bind pose baker
        if (bindUvChannel < 1 && targetRenderer is SkinnedMeshRenderer)
        {
            EditorGUILayout.HelpBox("This material is being used on a SkinnedMeshRenderer, but there is no baked bind pose set! " +
                                    "If the mesh's bind pose is not baked there will be artifacts as the mesh animates!", MessageType.Warning);

            BakeBindPoseToolButton(materialEditor, targetRenderer);

            EditorGUILayout.Space();
        }

        //if the bind pose is enabled
        if (bindUvChannel > 0 && bindUvChannel < 8)
        {
            //get the mesh this material is being used on
            Mesh targetMesh = FeathersAndFurToolUtilities.GetMeshFromRenderer(targetRenderer);

            if (targetMesh != null)
            {
                List<Vector4> dummy = new List<Vector4>();
                targetMesh.GetUVs(bindUvChannel, dummy);

                //if this mesh does not have anything in the UV channel that the bind pose is supposed to be in
                //display an error and add controls to fix it
                if (dummy.Count == 0)
                {
                    string uvName = "UV" + (bindUvChannel + 1);
                    string errorMessage = "This material has its Bind Pose UV Channel set to " + uvName + ", " +
                                            "but the mesh being rendered does have any baked data in " + uvName + "!\n";

                    errorMessage += "Bake a bind pose for this mesh or set the Bind Pose UV Channel to none!";
                    EditorGUILayout.HelpBox(errorMessage, MessageType.Error);

                    materialEditor.ShaderProperty(properties.bindPoseUvChannel, "Bind Pose UV Channel");
                    BakeBindPoseToolButton(materialEditor, targetRenderer);
                }
            }
        }

        if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.forkOptions, "Fork Options"))
        {
            materialEditor.ShaderProperty(properties.lightVolumes, "Light Volumes");
            materialEditor.ShaderProperty(properties.colorAdjust, "Color Adjust");
            if (properties.colorAdjust.floatValue > 0)
            {
                EditorGUI.indentLevel += 1;
                materialEditor.ShaderProperty(properties.colorAdjustHue, "Hue");
                materialEditor.ShaderProperty(properties.colorAdjustSaturation, "Saturation");
                materialEditor.ShaderProperty(properties.colorAdjustValue, "Value");
                EditorGUI.indentLevel -= 1;
            }
            materialEditor.ShaderProperty(properties.purpzieGryphonAudiolink, "Gryphon Audiolink");
            if (properties.purpzieGryphonAudiolink.floatValue > 0)
            {
                EditorGUI.indentLevel += 1;
                materialEditor.ShaderProperty(properties.purpzieGryphonAudiolinkTexture, "Glowsticks Bake");
                EditorGUI.indentLevel -= 1;
            }
            FeathersAndFurToolUtilities.EndFoldout();
        }

        EditorGUILayout.Space();

        //Fur Card Properties ----------------------------------------------------------------------

        if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.cards, "Fur Cards"))
        {
            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.cardsCoat, "Coat"))
            {
                if (targetRenderer is SkinnedMeshRenderer || targetRenderer is MeshRenderer)
                {
                    CoatPaintingToolButton(materialEditor, targetRenderer, properties);

                    EditorGUILayout.Space();
                }
                else if (cCoatPaintingToolType != null
                            && targetRenderer == null
                            && properties.coatParametersTexture.textureValue == null
                            && properties.coatDirectionTexture.textureValue == null)
                {
                    //if the user has the coat painting tool and is inspecting this material directly and has not assigned any coat textures yet
                    //inform them that they can open the coat painting tool by inspecting this material on a renderer
                    EditorGUILayout.HelpBox("To open the Coat Painting Tool and paint on feather/fur cards, " +
                                            "apply this material to a renderer and view it on the renderer's inspector.", MessageType.Info);
                }

                materialEditor.ShaderProperty(properties.coatParametersTexture, "Coat Parameters");
                materialEditor.ShaderProperty(properties.coatDirectionTexture, "Coat Direction");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.cardsTextures, "Texture Atlas Dimensions"))
            {
                materialEditor.ShaderProperty(properties.cardAtlasTextureCount, "Textures in Atlas");
                materialEditor.ShaderProperty(properties.cardAtlasTexturesPerRow, "Textures per Row");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.cardsCutout, "Cutout"))
            {
                materialEditor.ShaderProperty(properties.cardCutoutTexture, "Opacity (A)");
                materialEditor.ShaderProperty(properties.cardCutoutTextureAtlasEnabled, "Use Texture Atlas");
                materialEditor.ShaderProperty(properties.cardCutoutThreshold, "Cutout Threshold");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.cardsSpacing, "Size"))
            {
                materialEditor.ShaderProperty(properties.cardSizeMin, "Min Size");
                materialEditor.ShaderProperty(properties.cardSizeMax, "Max Size");

                if (sShowPerformanceWarnings && properties.cardSizeMin.floatValue < cMinCardSizeBeforePerformanceWarning)
                {
                    EditorGUILayout.HelpBox("Very small card sizes can lead to an excessive number of cards being generated, " +
                                            "reducing performance!", MessageType.Warning);
                }

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.cardsLength, "Shape Length"))
            {
                materialEditor.ShaderProperty(properties.cardShapeLengthMin, "Min Length");
                materialEditor.ShaderProperty(properties.cardShapeLengthMax, "Max Length");
                materialEditor.ShaderProperty(properties.cardShapeLengthCurve, "Transition Curve");

                if (sShowPerformanceWarnings && Mathf.Max(properties.cardShapeLengthMin.floatValue, properties.cardShapeLengthMax.floatValue) > cMaxCardLengthBeforePerformanceWarning)
                {
                    EditorGUILayout.HelpBox("Very long cards can cause excessive overdraw, reducing performance!", MessageType.Warning);
                }

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.cardsWidth, "Shape Width"))
            {
                materialEditor.ShaderProperty(properties.cardShapeWidthMin, "Min Width");
                materialEditor.ShaderProperty(properties.cardShapeWidthMax, "Max Width");
                materialEditor.ShaderProperty(properties.cardShapeWidthCurve, "Transition Curve");

                if (sShowPerformanceWarnings && Mathf.Max(properties.cardShapeWidthMin.floatValue, properties.cardShapeWidthMax.floatValue) > cMaxCardWidthBeforePerformanceWarning)
                {
                    EditorGUILayout.HelpBox("Very wide cards can cause excessive overdraw, reducing performance!", MessageType.Warning);
                }

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.cardsAdjustment, "Direction Adjustment"))
            {
                materialEditor.ShaderProperty(properties.cardElevationMin, "Min Elevation");
                materialEditor.ShaderProperty(properties.cardElevationMax, "Max Elevation");

                EditorGUILayout.Space();

                materialEditor.ShaderProperty(properties.cardElevationRandomness, "Elevation Randomness");
                materialEditor.ShaderProperty(properties.cardOrientationRandomness, "Orientation Randomness");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.cardsRotation, "Rotation"))
            {
                materialEditor.ShaderProperty(properties.cardRotationRandomnessMin, "Min Rotation Randomness");
                materialEditor.ShaderProperty(properties.cardRotationRandomnessMax, "Max Rotation Randomness");

                EditorGUILayout.Space();

                materialEditor.ShaderProperty(properties.cardRotationRandomnessElevationStart, "Elevation for Min Randomness");
                materialEditor.ShaderProperty(properties.cardRotationRandomnessElevationEnd, "Elevation for Max Randomness ");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.cardsBillboarding, "Billboarding"))
            {
                materialEditor.ShaderProperty(properties.cardBillboardingMin, "Min Billboarding");
                materialEditor.ShaderProperty(properties.cardBillboardingMax, "Max Billboarding");

                EditorGUILayout.Space();

                materialEditor.ShaderProperty(properties.cardBillboardingElevationStart, "Elevation for Min Billboarding");
                materialEditor.ShaderProperty(properties.cardBillboardingElevationEnd, "Elevation for Max Billboarding");

                EditorGUILayout.Space();

                materialEditor.ShaderProperty(properties.cardBillboardingSizeStart, "Size for Min Billboarding");
                materialEditor.ShaderProperty(properties.cardBillboardingSizeEnd, "Size for Max Billboarding");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            FeathersAndFurToolUtilities.EndFoldout();
        }

        EditorGUILayout.Space();

        //Color Properties -------------------------------------------------------------------------

        if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.color, "Color"))
        {
            bool doValuesMatch = DoUndercoatAndCoatColorPropertiesMatch(properties);
            LinkUnlinkParametersButton(doValuesMatch, ref mLinkingToggles.color, ref sFoldouts.colorUndercoat, ref sFoldouts.colorCoat);

            //undercoat (or linked undercoat and coat) properties
            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.colorUndercoat, mLinkingToggles.color ? "Coat and Undercoat" : "Undercoat"))
            {
                materialEditor.ShaderProperty(properties.undercoatAlbedoTexture, "Color (RGB) / Cutout Opacity (A)");
                materialEditor.ShaderProperty(properties.undercoatAlbedoTint, "Tint");

                EditorGUILayout.Space();

                materialEditor.ShaderProperty(properties.undercoatCutoutEnabled, "Use Cutout");
                materialEditor.ShaderProperty(properties.undercoatCutoutThreshold, "Cutout Threshold");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            //if undercoat and coat linking is enabled
            if (mLinkingToggles.color)
            {
                //match the coat properties to the undercoat
                MatchUndercoatAndCoatColorProperties(properties);
            }
            else
            {
                //coat properties
                if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.colorCoat, "Coat"))
                {
                    materialEditor.ShaderProperty(properties.coatAlbedoTexture, "Color (RGB) / Cutout Opacity (A)");
                    materialEditor.ShaderProperty(properties.coatAlbedoTint, "Tint");

                    EditorGUILayout.Space();

                    materialEditor.ShaderProperty(properties.coatCutoutEnabled, "Use Cutout");
                    materialEditor.ShaderProperty(properties.coatCutoutThreshold, "Cutout Threshold");

                    FeathersAndFurToolUtilities.EndFoldout();
                }

                EditorGUILayout.Space();
            }

            //card properties
            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.colorCard, "Card"))
            {
                materialEditor.ShaderProperty(properties.cardAlbedoTexture, "Color");
                materialEditor.ShaderProperty(properties.cardAlbedoTextureAtlasEnabled, "Use Texture Atlas");
                materialEditor.ShaderProperty(properties.cardAlbedoTint, "Tint");

                EditorGUILayout.Space();

                materialEditor.ShaderProperty(properties.cardAlbedoBlendMode, "Blend Mode");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            FeathersAndFurToolUtilities.EndFoldout();
        }

        EditorGUILayout.Space();

        //Emission Properties ----------------------------------------------------------------------

        if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.emission, "Emission"))
        {
            bool doValuesMatch = DoUndercoatAndCoatEmissionPropertiesMatch(properties);
            LinkUnlinkParametersButton(doValuesMatch, ref mLinkingToggles.emission, ref sFoldouts.emissionUndercoat, ref sFoldouts.emissionCoat);

            //undercoat (or linked undercoat and coat) properties
            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.emissionUndercoat, mLinkingToggles.emission ? "Coat and Undercoat" : "Undercoat"))
            {
                materialEditor.ShaderProperty(properties.undercoatEmissionTexture, "Emission");
                materialEditor.ShaderProperty(properties.undercoatEmissionTint, "Tint");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            //if undercoat and coat linking is enabled
            if (mLinkingToggles.emission)
            {
                //match the coat properties to the undercoat
                MatchUndercoatAndCoatEmissionProperties(properties);
            }
            else
            {
                //coat properties
                if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.emissionCoat, "Coat"))
                {
                    materialEditor.ShaderProperty(properties.coatEmissionTexture, "Emission");
                    materialEditor.ShaderProperty(properties.coatEmissionTint, "Tint");

                    FeathersAndFurToolUtilities.EndFoldout();
                }

                EditorGUILayout.Space();
            }

            //card properties
            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.emissionCard, "Card"))
            {
                materialEditor.ShaderProperty(properties.cardEmissionTexture, "Emission");
                materialEditor.ShaderProperty(properties.cardEmissionTextureAtlasEnabled, "Use Texture Atlas");
                materialEditor.ShaderProperty(properties.cardEmissionTint, "Tint");

                EditorGUILayout.Space();

                materialEditor.ShaderProperty(properties.cardEmissionBlendMode, "Blend Mode");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            FeathersAndFurToolUtilities.EndFoldout();
        }

        EditorGUILayout.Space();

        //Material Parameters Properties -----------------------------------------------------------

        if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.materialParameters, "Material Parameters"))
        {
            bool doValuesMatch = DoUndercoatAndCoatMaterialPropertiesMatch(properties);
            LinkUnlinkParametersButton(doValuesMatch, ref mLinkingToggles.materialParameters, ref sFoldouts.materialParametersUndercoat, ref sFoldouts.materialParametersCoat);

            //undercoat (or linked undercoat and coat) properties
            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.materialParametersUndercoat, mLinkingToggles.materialParameters ? "Coat and Undercoat" : "Undercoat"))
            {
                materialEditor.ShaderProperty(properties.undercoatMaterialParametersTexture, "Material Parameters");

                EditorGUILayout.Space();

                //only display the min and max properties if a texture is set
                //otherwise only display the max properties as controls for a constant value
                if (properties.undercoatMaterialParametersTexture.textureValue != null)
                {
                    EditorGUILayout.LabelField("Reflectiveness / Metalness (R)");
                    EditorGUI.indentLevel++;
                    materialEditor.ShaderProperty(properties.undercoatReflectivenessMin, "Min");
                    materialEditor.ShaderProperty(properties.undercoatReflectivenessMax, "Max");
                    EditorGUI.indentLevel--;

                    EditorGUILayout.Space();

                    EditorGUILayout.LabelField("Roughness (G)");
                    EditorGUI.indentLevel++;
                    materialEditor.ShaderProperty(properties.undercoatRoughnessMin, "Min");
                    materialEditor.ShaderProperty(properties.undercoatRoughnessMax, "Max");
                    EditorGUI.indentLevel--;

                    EditorGUILayout.Space();

                    EditorGUILayout.LabelField("Iridescent Thickness (B)");
                    EditorGUI.indentLevel++;
                    materialEditor.ShaderProperty(properties.undercoatIridescentThicknessMin, "Min");
                    materialEditor.ShaderProperty(properties.undercoatIridescentThicknessMax, "Max");
                    EditorGUI.indentLevel--;

                    EditorGUILayout.Space();

                    EditorGUILayout.LabelField("Ambient Occlusion (A)");
                    EditorGUI.indentLevel++;
                    materialEditor.ShaderProperty(properties.undercoatAmbientOcclusionMin, "Min");
                    materialEditor.ShaderProperty(properties.undercoatAmbientOcclusionMax, "Max");
                    EditorGUI.indentLevel--;
                }
                else
                {
                    materialEditor.ShaderProperty(properties.undercoatReflectivenessMax, "Reflectiveness / Metalness (R)");
                    materialEditor.ShaderProperty(properties.undercoatRoughnessMax, "Roughness (G)");
                    materialEditor.ShaderProperty(properties.undercoatIridescentThicknessMax, "Iridescent Thickness (B)");
                    materialEditor.ShaderProperty(properties.undercoatAmbientOcclusionMax, "Ambient Occlusion (A)");
                }

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            //if undercoat and coat linking is enabled
            if (mLinkingToggles.materialParameters)
            {
                //match the coat properties to the undercoat
                MatchUndercoatAndCoatMaterialProperties(properties);
            }
            else
            {
                //coat properties
                if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.materialParametersCoat, "Coat"))
                {
                    materialEditor.ShaderProperty(properties.coatMaterialParametersTexture, "Material Parameters");

                    EditorGUILayout.Space();

                    //only display the min and max properties if a texture is set
                    //otherwise only display the max properties as controls for a constant value
                    if (properties.coatMaterialParametersTexture.textureValue != null)
                    {
                        EditorGUILayout.LabelField("Reflectiveness / Metalness (R)");
                        EditorGUI.indentLevel++;
                        materialEditor.ShaderProperty(properties.coatReflectivenessMin, "Min");
                        materialEditor.ShaderProperty(properties.coatReflectivenessMax, "Max");
                        EditorGUI.indentLevel--;

                        EditorGUILayout.Space();

                        EditorGUILayout.LabelField("Roughness (G)");
                        EditorGUI.indentLevel++;
                        materialEditor.ShaderProperty(properties.coatRoughnessMin, "Min");
                        materialEditor.ShaderProperty(properties.coatRoughnessMax, "Max");
                        EditorGUI.indentLevel--;

                        EditorGUILayout.Space();

                        EditorGUILayout.LabelField("Iridescent Thickness (B)");
                        EditorGUI.indentLevel++;
                        materialEditor.ShaderProperty(properties.coatIridescentThicknessMin, "Min");
                        materialEditor.ShaderProperty(properties.coatIridescentThicknessMax, "Max");
                        EditorGUI.indentLevel--;

                        EditorGUILayout.Space();

                        EditorGUILayout.LabelField("Ambient Occlusion (A)");
                        EditorGUI.indentLevel++;
                        materialEditor.ShaderProperty(properties.coatAmbientOcclusionMin, "Min");
                        materialEditor.ShaderProperty(properties.coatAmbientOcclusionMax, "Max");
                        EditorGUI.indentLevel--;
                    }
                    else
                    {
                        materialEditor.ShaderProperty(properties.coatReflectivenessMax, "Reflectiveness / Metalness (R)");
                        materialEditor.ShaderProperty(properties.coatRoughnessMax, "Roughness (G)");
                        materialEditor.ShaderProperty(properties.coatIridescentThicknessMax, "Iridescent Thickness (B)");
                        materialEditor.ShaderProperty(properties.coatAmbientOcclusionMax, "Ambient Occlusion (A)");
                    }

                    FeathersAndFurToolUtilities.EndFoldout();
                }

                EditorGUILayout.Space();
            }

            //card properties
            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.materialParametersCard, "Card"))
            {
                materialEditor.ShaderProperty(properties.cardMaterialParametersTexture, "Material Parameters");
                materialEditor.ShaderProperty(properties.cardMaterialParametersTextureAtlasEnabled, "Use Texture Atlas");

                EditorGUILayout.Space();

                //only display the min and max properties if a texture is set
                //otherwise only display the max properties as controls for a constant value
                if (properties.cardMaterialParametersTexture.textureValue != null)
                {
                    EditorGUILayout.LabelField("Reflectiveness / Metalness (R)");
                    EditorGUI.indentLevel++;
                    materialEditor.ShaderProperty(properties.cardReflectivenessMin, "Min");
                    materialEditor.ShaderProperty(properties.cardReflectivenessMax, "Max");
                    materialEditor.ShaderProperty(properties.cardReflectivenessBlendMode, "Blend Mode");
                    EditorGUI.indentLevel--;

                    EditorGUILayout.Space();

                    EditorGUILayout.LabelField("Roughness (G)");
                    EditorGUI.indentLevel++;
                    materialEditor.ShaderProperty(properties.cardRoughnessMin, "Min");
                    materialEditor.ShaderProperty(properties.cardRoughnessMax, "Max");
                    materialEditor.ShaderProperty(properties.cardRoughnessBlendMode, "Blend Mode");
                    EditorGUI.indentLevel--;

                    EditorGUILayout.Space();

                    EditorGUILayout.LabelField("Iridescent Thickness (B)");
                    EditorGUI.indentLevel++;
                    materialEditor.ShaderProperty(properties.cardIridescentThicknessMin, "Min");
                    materialEditor.ShaderProperty(properties.cardIridescentThicknessMax, "Max");
                    materialEditor.ShaderProperty(properties.cardIridescentThicknessBlendMode, "Blend Mode");
                    EditorGUI.indentLevel--;

                    EditorGUILayout.Space();

                    EditorGUILayout.LabelField("Ambient Occlusion (A)");
                    EditorGUI.indentLevel++;
                    materialEditor.ShaderProperty(properties.cardAmbientOcclusionMin, "Min");
                    materialEditor.ShaderProperty(properties.cardAmbientOcclusionMax, "Max");
                    materialEditor.ShaderProperty(properties.cardAmbientOcclusionBlendMode, "Blend Mode");
                    EditorGUI.indentLevel--;
                }
                else
                {
                    materialEditor.ShaderProperty(properties.cardReflectivenessMax, "Reflectiveness / Metalness (R)");
                    EditorGUI.indentLevel++;
                    materialEditor.ShaderProperty(properties.cardReflectivenessBlendMode, "Blend Mode");
                    EditorGUI.indentLevel--;

                    EditorGUILayout.Space();

                    materialEditor.ShaderProperty(properties.cardRoughnessMax, "Roughness (G)");
                    EditorGUI.indentLevel++;
                    materialEditor.ShaderProperty(properties.cardRoughnessBlendMode, "Blend Mode");
                    EditorGUI.indentLevel--;

                    EditorGUILayout.Space();

                    materialEditor.ShaderProperty(properties.cardIridescentThicknessMax, "Iridescent Thickness (B)");
                    EditorGUI.indentLevel++;
                    materialEditor.ShaderProperty(properties.cardIridescentThicknessBlendMode, "Blend Mode");
                    EditorGUI.indentLevel--;

                    EditorGUILayout.Space();

                    materialEditor.ShaderProperty(properties.cardAmbientOcclusionMax, "Ambient Occlusion (A)");
                    EditorGUI.indentLevel++;
                    materialEditor.ShaderProperty(properties.cardAmbientOcclusionBlendMode, "Blend Mode");
                    EditorGUI.indentLevel--;
                }

                FeathersAndFurToolUtilities.EndFoldout();
            }

            FeathersAndFurToolUtilities.EndFoldout();
        }

        EditorGUILayout.Space();

        //Additional Material Parameters Properties ------------------------------------------------

        if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.additionalMaterialParameters, "Additional Material Parameters"))
        {
            bool doValuesMatch = DoUndercoatAndCoatAdditionalMaterialPropertiesMatch(properties);
            LinkUnlinkParametersButton(doValuesMatch, ref mLinkingToggles.additionalMaterialParameters, ref sFoldouts.additionalMaterialParametersUndercoat, ref sFoldouts.additionalMaterialParametersCoat);

            //undercoat (or linked undercoat and coat) properties
            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.additionalMaterialParametersUndercoat, mLinkingToggles.additionalMaterialParameters ? "Coat and Undercoat" : "Undercoat"))
            {
                materialEditor.ShaderProperty(properties.undercoatAdditionalMaterialParametersTexture, "Additional Material Parameters");

                EditorGUILayout.Space();

                materialEditor.ShaderProperty(properties.undercoatFurnessReadCoatParametersMask, "Undercoat Get Furness From Coat Parameters Mask");

                //only display the min and max properties if a texture is set
                //otherwise only display the max properties as controls for a constant value
                if (properties.undercoatAdditionalMaterialParametersTexture.textureValue != null)
                {
                    EditorGUILayout.LabelField("Furness (R)");
                    EditorGUI.indentLevel++;
                    materialEditor.ShaderProperty(properties.undercoatFurnessMin, "Min");
                    materialEditor.ShaderProperty(properties.undercoatFurnessMax, "Max");
                    EditorGUI.indentLevel--;

                    EditorGUILayout.Space();

                    EditorGUILayout.LabelField("Model Diameter (G)");
                    EditorGUI.indentLevel++;
                    materialEditor.ShaderProperty(properties.undercoatDiameterMin, "Min");
                    materialEditor.ShaderProperty(properties.undercoatDiameterMax, "Max");
                    EditorGUI.indentLevel--;

                    EditorGUILayout.Space();

                    EditorGUILayout.LabelField("Self Shadow Mask (B)");
                    EditorGUI.indentLevel++;
                    materialEditor.ShaderProperty(properties.undercoatSelfShadowMaskMin, "Min");
                    materialEditor.ShaderProperty(properties.undercoatSelfShadowMaskMax, "Max");
                    EditorGUI.indentLevel--;

                    EditorGUILayout.Space();

                    EditorGUILayout.LabelField("Ambient Transmission Occlusion (A)");
                    EditorGUI.indentLevel++;
                    materialEditor.ShaderProperty(properties.undercoatAmbientTransmissionOcclusionMin, "Min");
                    materialEditor.ShaderProperty(properties.undercoatAmbientTransmissionOcclusionMax, "Max");
                    EditorGUI.indentLevel--;
                }
                else
                {
                    //if fur-ness is being driven by the coat parameters mask value
                    //display the min and max undercoat fur-ness properties even if a texture is not set
                    if (properties.undercoatFurnessReadCoatParametersMask.floatValue > 0.5f)
                    {
                        EditorGUILayout.LabelField("Furness (R)");
                        EditorGUI.indentLevel++;
                        materialEditor.ShaderProperty(properties.undercoatFurnessMin, "Min");
                        materialEditor.ShaderProperty(properties.undercoatFurnessMax, mLinkingToggles.additionalMaterialParameters ? "Max (and Coat Value)" : "Max");
                        EditorGUI.indentLevel--;

                        EditorGUILayout.Space();
                    }
                    else
                    {
                        materialEditor.ShaderProperty(properties.undercoatFurnessMax, "Furness (R)");
                    }

                    materialEditor.ShaderProperty(properties.undercoatDiameterMax, "Model Diameter (G)");
                    materialEditor.ShaderProperty(properties.undercoatSelfShadowMaskMax, "Self Shadow Mask (B)");
                    materialEditor.ShaderProperty(properties.undercoatAmbientTransmissionOcclusionMax, "Ambient Transmission Occlusion (A)");
                }

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            //if undercoat and coat linking is enabled
            if (mLinkingToggles.additionalMaterialParameters)
            {
                //match the coat properties to the undercoat
                MatchUndercoatAndCoatAdditionalMaterialProperties(properties);
            }
            else
            {
                //coat properties
                if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.additionalMaterialParametersCoat, "Coat"))
                {
                    materialEditor.ShaderProperty(properties.coatAdditionalMaterialParametersTexture, "Additional Material Parameters");

                    EditorGUILayout.Space();

                    //only display the min and max properties if a texture is set
                    //otherwise only display the max properties as controls for a constant value
                    if (properties.coatAdditionalMaterialParametersTexture.textureValue != null)
                    {
                        EditorGUILayout.LabelField("Furness (R)");
                        EditorGUI.indentLevel++;
                        materialEditor.ShaderProperty(properties.coatFurnessMin, "Min");
                        materialEditor.ShaderProperty(properties.coatFurnessMax, "Max");
                        EditorGUI.indentLevel--;

                        EditorGUILayout.Space();

                        EditorGUILayout.LabelField("Model Diameter (G)");
                        EditorGUI.indentLevel++;
                        materialEditor.ShaderProperty(properties.coatDiameterMin, "Min");
                        materialEditor.ShaderProperty(properties.coatDiameterMax, "Max");
                        EditorGUI.indentLevel--;

                        EditorGUILayout.Space();

                        EditorGUILayout.LabelField("Self Shadow Mask (B)");
                        EditorGUI.indentLevel++;
                        materialEditor.ShaderProperty(properties.coatSelfShadowMaskMin, "Min");
                        materialEditor.ShaderProperty(properties.coatSelfShadowMaskMax, "Max");
                        EditorGUI.indentLevel--;

                        EditorGUILayout.Space();

                        EditorGUILayout.LabelField("Ambient Transmission Occlusion (A)");
                        EditorGUI.indentLevel++;
                        materialEditor.ShaderProperty(properties.coatAmbientTransmissionOcclusionMin, "Min");
                        materialEditor.ShaderProperty(properties.coatAmbientTransmissionOcclusionMax, "Max");
                        EditorGUI.indentLevel--;
                    }
                    else
                    {
                        materialEditor.ShaderProperty(properties.coatFurnessMax, "Furness (R)");
                        materialEditor.ShaderProperty(properties.coatDiameterMax, "Model Diameter (G)");
                        materialEditor.ShaderProperty(properties.coatSelfShadowMaskMax, "Self Shadow Mask (B)");
                        materialEditor.ShaderProperty(properties.coatAmbientTransmissionOcclusionMax, "Ambient Transmission Occlusion (A)");
                    }

                    FeathersAndFurToolUtilities.EndFoldout();
                }
            }

            FeathersAndFurToolUtilities.EndFoldout();
        }

        EditorGUILayout.Space();

        //Normals/Tangents/Anisotropy Properties ---------------------------------------------------

        if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.normals, "Normals, Fur Tangents, and Anisotropy"))
        {
            bool doValuesMatch = DoUndercoatAndCoatNormalPropertiesMatch(properties);
            LinkUnlinkParametersButton(doValuesMatch, ref mLinkingToggles.normals, ref sFoldouts.normalsUndercoat, ref sFoldouts.normalsCoat);

            //undercoat properties
            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.normalsUndercoat, "Undercoat"))
            {
                materialEditor.ShaderProperty(properties.undercoatNormalTexture, "Normal Map");
                materialEditor.ShaderProperty(properties.undercoatNormalStrength, "Strength");
                materialEditor.ShaderProperty(properties.undercoatNormalFurInfluence, "Influence on Fur Tangents");

                EditorGUILayout.Space();
                EditorGUILayout.Space();

                materialEditor.ShaderProperty(properties.undercoatAnisotropyTexture, "Fur Tangents / Anisotropy");

                if (properties.undercoatAnisotropyTexture.textureValue == null && properties.coatDirectionTexture.textureValue != null)
                {
                    if (FeathersAndFurToolUtilities.IndentedButton("Set to Coat Direction Texture"))
                    {
                        properties.undercoatAnisotropyTexture.textureValue = properties.coatDirectionTexture.textureValue;
                        properties.undercoatAnisotropyTexture.textureScaleAndOffset = properties.coatDirectionTexture.textureScaleAndOffset;
                    }
                }

                materialEditor.ShaderProperty(properties.undercoatAnisotropyFlattenFurTangents, "Flatten Fur Tangents to Surface");
                materialEditor.ShaderProperty(properties.undercoatAnisotropyStrength, "Anisotropy Strength");

                //if undercoat and coat linking is disabled, display the undercoat fur root normal map properties
                //inside the undercoat foldout, rather than in the linked property foldout
                if (!mLinkingToggles.normals)
                {
                    EditorGUILayout.Space();
                    EditorGUILayout.Space();

                    materialEditor.ShaderProperty(properties.undercoatFurRootNormalTexture, "Fur Root Normal Map");
                    materialEditor.ShaderProperty(properties.undercoatFurRootNormalStrength, "Strength");
                    materialEditor.ShaderProperty(properties.undercoatFurRootNormalDiffuseInfluence, "Adjust Diffuse to Root Normal");
                }

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            //if undercoat and coat linking is enabled
            if (mLinkingToggles.normals)
            {
                //display the undercoat fur root normal map properties inside a separate linked property foldout
                if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.normalsCoat, "Coat and Undercoat"))
                {
                    materialEditor.ShaderProperty(properties.undercoatFurRootNormalTexture, "Fur Root Normal Map");
                    materialEditor.ShaderProperty(properties.undercoatFurRootNormalStrength, "Strength");
                    materialEditor.ShaderProperty(properties.undercoatFurRootNormalDiffuseInfluence, "Adjust Diffuse to Root Normal");

                    FeathersAndFurToolUtilities.EndFoldout();
                }

                //match the coat properties to the undercoat
                MatchUndercoatAndCoatNormalProperties(properties);
            }
            else
            {
                //coat properties
                if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.normalsCoat, "Coat"))
                {
                    materialEditor.ShaderProperty(properties.coatFurRootNormalTexture, "Fur Root Normal Map");
                    materialEditor.ShaderProperty(properties.coatFurRootNormalStrength, "Strength");
                    materialEditor.ShaderProperty(properties.coatFurRootNormalDiffuseInfluence, "Adjust Diffuse to Root Normal");

                    FeathersAndFurToolUtilities.EndFoldout();
                }
            }

            EditorGUILayout.Space();

            //card properties
            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.normalsCard, "Card"))
            {
                materialEditor.ShaderProperty(properties.cardNormalTexture, "Normal Map");
                materialEditor.ShaderProperty(properties.cardNormalTextureAtlasEnabled, "Use Texture Atlas");
                materialEditor.ShaderProperty(properties.cardNormalStrength, "Strength");
                materialEditor.ShaderProperty(properties.cardNormalFurInfluence, "Influence on Fur Tangents");

                EditorGUILayout.Space();
                EditorGUILayout.Space();

                materialEditor.ShaderProperty(properties.cardAnisotropyTexture, "Fur Tangents / Anisotropy");
                materialEditor.ShaderProperty(properties.cardAnisotropyTextureAtlasEnabled, "Use Texture Atlas");
                materialEditor.ShaderProperty(properties.cardAnisotropyFlattenFurTangents, "Flatten Fur Tangents to Surface");
                materialEditor.ShaderProperty(properties.cardAnisotropyStrength, "Anisotropy Strength");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            FeathersAndFurToolUtilities.EndFoldout();
        }

        EditorGUILayout.Space();

        //Clothing Properties ----------------------------------------------------------------------

        if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.clothing, "Clothing"))
        {
            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.clothingMaskFull, "Full Mask"))
            {
                //if this material is being used on a skinned mesh or static mesh
                //add a button to open the full mask version of the clothing mask tool
                if (targetRenderer is SkinnedMeshRenderer || targetRenderer is MeshRenderer)
                {
                    ClothingMaskToolButton(materialEditor, targetRenderer, false, properties);

                    EditorGUILayout.Space();
                }

                materialEditor.ShaderProperty(properties.clothingMaskFullTexture, "Mask");
                materialEditor.ShaderProperty(properties.clothingMaskFullRedChannelMode, "Red Channel Mode");
                materialEditor.ShaderProperty(properties.clothingMaskFullGreenChannelMode, "Green Channel Mode");
                materialEditor.ShaderProperty(properties.clothingMaskFullBlueChannelMode, "Blue Channel Mode");
                materialEditor.ShaderProperty(properties.clothingMaskFullAlphaChannelMode, "Alpha Channel Mode");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.clothingMaskPacked, "Packed Mask"))
            {
                //if this material is being used on a skinned mesh or static mesh
                //add a button to open the packed mask version of the clothing mask tool
                if (targetRenderer is SkinnedMeshRenderer || targetRenderer is MeshRenderer)
                {
                    ClothingMaskToolButton(materialEditor, targetRenderer, true, properties);

                    EditorGUILayout.Space();
                }

                materialEditor.ShaderProperty(properties.clothingMaskPackedTexture, "Mask");

                //display an error if the packed clothing mask texture is not using the correct format
                Texture2D packedMask = properties.clothingMaskPackedTexture.textureValue as Texture2D;
                if (packedMask != null && packedMask.format != TextureFormat.RFloat)
                {
                    EditorGUILayout.HelpBox("Texture is not using the correct format!\n" +
                                            "Regular RGBA textures should be put in the 'Full Mask' texture field.\n" +
                                            "Use the Clothing Mask Editor to create packed masks.", MessageType.Error);
                }

                materialEditor.ShaderProperty(properties.clothingMaskPackedUvWrapEnabled, "Use UV Wrap");

                //add the packed clothing mask modes in 4 groups of 8 with a separate foldout for each for better organization

                GUIStyle foldoutHeaderStyle = EditorStyles.foldout;
                foldoutHeaderStyle.fontStyle = FontStyle.Bold;

                sFoldouts.clothingMaskPackedModesA = EditorGUILayout.Foldout(sFoldouts.clothingMaskPackedModesA, "Bits 0-7", true, foldoutHeaderStyle);
                if (sFoldouts.clothingMaskPackedModesA)
                {
                    for (int index = 0; index < 8; index++)
                    {
                        materialEditor.ShaderProperty(properties.clothingMaskPackedModes[index], index + " Bit Mode");
                    }
                }

                sFoldouts.clothingMaskPackedModesB = EditorGUILayout.Foldout(sFoldouts.clothingMaskPackedModesB, "Bits 8-15", true, foldoutHeaderStyle);
                if (sFoldouts.clothingMaskPackedModesB)
                {
                    for (int index = 8; index < 16; index++)
                    {
                        materialEditor.ShaderProperty(properties.clothingMaskPackedModes[index], index + " Bit Mode");
                    }
                }

                sFoldouts.clothingMaskPackedModesC = EditorGUILayout.Foldout(sFoldouts.clothingMaskPackedModesC, "Bits 16-23", true, foldoutHeaderStyle);
                if (sFoldouts.clothingMaskPackedModesC)
                {
                    for (int index = 16; index < 24; index++)
                    {
                        materialEditor.ShaderProperty(properties.clothingMaskPackedModes[index], index + " Bit Mode");
                    }
                }

                sFoldouts.clothingMaskPackedModesD = EditorGUILayout.Foldout(sFoldouts.clothingMaskPackedModesD, "Bits 24-31", true, foldoutHeaderStyle);
                if (sFoldouts.clothingMaskPackedModesD)
                {
                    for (int index = 24; index < 32; index++)
                    {
                        materialEditor.ShaderProperty(properties.clothingMaskPackedModes[index], index + " Bit Mode");
                    }
                }

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.clothingCutout, "Cutout"))
            {
                materialEditor.ShaderProperty(properties.clothingMaskCutoutThreshold, "Cutout Threshold");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            FeathersAndFurToolUtilities.EndFoldout();
        }

        EditorGUILayout.Space();

        //Lighting Properties ----------------------------------------------------------------------

        if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.lighting, "Lighting"))
        {
            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.lightingSelfShadow, "Self Shadowing"))
            {
                materialEditor.ShaderProperty(properties.selfShadowColoredStrength, "Colored Strength");
                materialEditor.ShaderProperty(properties.selfShadowUncoloredStrength, "Uncolored Strength");
                materialEditor.ShaderProperty(properties.selfShadowNonFurStrengthMultiplier, "Non-Fur Strength Multiplier");
                materialEditor.ShaderProperty(properties.selfShadowCardTipOpacity, "Card Tip Opacity Approximation");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.lightingFur, "Fur"))
            {
                materialEditor.ShaderProperty(properties.furDirectLightingOcclusion, "AO Affects Direct Lighting");

                EditorGUILayout.Space();

                materialEditor.ShaderProperty(properties.furShift, "Highlight Shift");

                EditorGUILayout.Space();

                materialEditor.ShaderProperty(properties.furRemapStart, "Remap Start");
                materialEditor.ShaderProperty(properties.furRemapEnd, "Remap End");

                EditorGUILayout.Space();

                materialEditor.ShaderProperty(properties.furBaselineReflectiveness, "Base Reflectiveness");
                materialEditor.ShaderProperty(properties.furFresnelStrength, "Fresnel Strength");
                materialEditor.ShaderProperty(properties.furIridescenceLUT, "Iridescence LUT");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.lightingDiffuse, "Diffuse"))
            {
                materialEditor.ShaderProperty(properties.diffuseRoughnessInfluence, "Roughness Influence");

                EditorGUILayout.Space();

                materialEditor.ShaderProperty(properties.diffuseRemapStart, "Remap Start");
                materialEditor.ShaderProperty(properties.diffuseRemapEnd, "Remap End");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.lightingSpecular, "Specular"))
            {
                materialEditor.ShaderProperty(properties.specularBaselineReflectiveness, "Base Reflectiveness");
                materialEditor.ShaderProperty(properties.specularFresnelStrength, "Fresnel Strength");
                materialEditor.ShaderProperty(properties.specularIridescenceLUT, "Iridescence LUT");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.lightingAmbient, "Ambient Lighting"))
            {
                materialEditor.ShaderProperty(properties.ambientLightingOverrideMode, "Override Mode");
                materialEditor.ShaderProperty(properties.ambientLightingOverrideColor, "Override Color");

                EditorGUILayout.Space();

                materialEditor.ShaderProperty(properties.furAmbientLightingDirectionality, "Fur Directionality");
                materialEditor.ShaderProperty(properties.diffuseAmbientLightingDirectionality, "Diffuse Directionality");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.lightingProbes, "Reflection Probes"))
            {
                materialEditor.ShaderProperty(properties.furCustomReflectionProbeEnabled, "Use Custom Fur Reflection");
                materialEditor.ShaderProperty(properties.furCustomReflectionProbe, "Custom Fur Reflection Probe");

                EditorGUILayout.Space();

                materialEditor.ShaderProperty(properties.furCustomTransmissionProbeEnabled, "Use Custom Fur Transmission");
                materialEditor.ShaderProperty(properties.furCustomTransmissionProbe, "Custom Fur Transmission Probe");

                EditorGUILayout.Space();

                materialEditor.ShaderProperty(properties.specularCustomReflectionProbeEnabled, "Use Custom Specular Reflection");
                materialEditor.ShaderProperty(properties.specularCustomReflectionProbe, "Custom Specular Reflection Probe");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.lightingMiscellaneous, "Miscellaneous"))
            {
                materialEditor.ShaderProperty(properties.brightnessClamp, "Brightness Clamp (<0 Is Disabled)");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            FeathersAndFurToolUtilities.EndFoldout();
        }

        EditorGUILayout.Space();

        //Optimization Properties ------------------------------------------------------------------

        if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.optimization, "Optimization"))
        {
            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.optimizationTexture, "Coat"))
            {
                // if this material has a coat parameters texture, add a button to open the optimization texture baker
                if (properties.coatParametersTexture.textureValue != null)
                {
                    BakeOptimizationTextureToolButton(materialEditor);

                    EditorGUILayout.Space();
                }

                materialEditor.ShaderProperty(properties.coatOptimizationTexture, "Optimization Texture");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.optimizationLod, "LOD"))
            {
                materialEditor.ShaderProperty(properties.cardLodFactor, "LOD Factor");
                materialEditor.ShaderProperty(properties.cardLodGrowth, "Card Growth Factor");

                EditorGUILayout.Space();

                materialEditor.ShaderProperty(properties.cardLodFixedResolutionEnabled, "Assume Fixed Resolution");
                materialEditor.ShaderProperty(properties.cardLodFixedResolution, "Fixed Resolution");

                EditorGUILayout.Space();

                materialEditor.ShaderProperty(properties.cardLodSpacingMax, "Maximum Spacing from LOD");
                materialEditor.ShaderProperty(properties.cardLodSpacingMin, "Force Minimum Spacing");
                materialEditor.ShaderProperty(properties.cardLodShadowSpacingMin, "Force Minimum Spacing in Shadows");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.optimizationFade, "Fade"))
            {
                materialEditor.ShaderProperty(properties.cardFadeStart, "Start Distance (<0 Is Disabled)");
                materialEditor.ShaderProperty(properties.cardFadeLength, "Length");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.optimizationOffScreen, "Off-Screen Rendering"))
            {
                materialEditor.ShaderProperty(properties.cardRenderInMirrors, "Render Cards in Mirrors");
                materialEditor.ShaderProperty(properties.cardRenderInShadows, "Render Cards in Shadows");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            FeathersAndFurToolUtilities.EndFoldout();
        }

        EditorGUILayout.Space();

        //Miscellaneous Properties -----------------------------------------------------------------

        if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.miscellaneous, "Miscellaneous"))
        {
            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.miscellaneousSkinning, "Skinned Mesh"))
            {
                // if this material is being used on a skinned mesh, add a button to open the bind pose baker tool
                if (targetRenderer is SkinnedMeshRenderer || targetRenderer is MeshRenderer)
                {
                    BakeBindPoseToolButton(materialEditor, targetRenderer);

                    EditorGUILayout.Space();
                }

                materialEditor.ShaderProperty(properties.bindPoseUvChannel, "Bind Pose UV Channel");
                materialEditor.ShaderProperty(properties.skinnedMeshScaleFixupEnabled, "Use Skinned Mesh Scale Fixup");
                materialEditor.ShaderProperty(properties.cardRescale, "Card Rescale");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.miscellaneousOptions, "Rendering Options"))
            {
                materialEditor.ShaderProperty(properties.undercoatCullMode, "Base Mesh Face Culling Mode");

                EditorGUILayout.Space();

                materialEditor.ShaderProperty(properties.undercoatShadowCullMode, "Base Mesh Shadow Face Culling Mode");

                //add a warning if the user enables two sided shadow casting on a render using this material
                if (targetRenderer != null && targetRenderer.shadowCastingMode == ShadowCastingMode.TwoSided)
                {
                    EditorGUILayout.HelpBox("Setting 'Cast Shadows' to 'Two Sided' in the renderer does not work with this material! " +
                                            "Instead, set 'Shadow Base Mesh Face Culling Mode' to 'Off' on this material to achieve the same result.", MessageType.Warning);
                }

                materialEditor.ShaderProperty(properties.cardShadowBias, "Distance to Bias Cards in Shadows");

                EditorGUILayout.Space();

                materialEditor.ShaderProperty(properties.randomSeed, "Random Seed");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            EditorGUILayout.Space();

            if (FeathersAndFurToolUtilities.StartFoldout(ref sFoldouts.miscellaneousFallback, "VRC Fallback"))
            {
                materialEditor.ShaderProperty(properties.fallbackTexture, "Unlit Color");

                FeathersAndFurToolUtilities.EndFoldout();
            }

            FeathersAndFurToolUtilities.EndFoldout();
        }

        EditorGUILayout.Space();

        //Additional Material Settings -------------------------------------------------------------

        materialEditor.RenderQueueField();

        //display a warning if the material is not opaque
        if((materialEditor.target as Material).renderQueue > (int)RenderQueue.GeometryLast)
        {
            EditorGUILayout.HelpBox("This material is not intended to be rendered as transparent! " +
                                    "It is recommended to use a Render Queue of 2500 or less.", MessageType.Warning);
        }

        materialEditor.EnableInstancingField();
        materialEditor.DoubleSidedGIField();

        EditorGUILayout.Space();

        sShowPerformanceWarnings = EditorGUILayout.Toggle("Show Performance Warnings", sShowPerformanceWarnings);

        return EditorGUI.EndChangeCheck(); //return if any changes were made
    }

    //Utility Buttons ------------------------------------------------------------------------------

    //add a button to open the optimization texture tool
    private void BakeOptimizationTextureToolButton(MaterialEditor materialEditor)
    {
        if (FeathersAndFurToolUtilities.IndentedButton("Bake Optimization Texture"))
        {
            FeathersAndFurOptimizationTextureBaker optimizationTextureWindow = EditorWindow.GetWindow<FeathersAndFurOptimizationTextureBaker>(false, "Optimization Texture Baker", true);
            optimizationTextureWindow.SetTarget(materialEditor.target as Material);
            optimizationTextureWindow.Show();
        }
    }

    //add a button to open the bind pose baker
    private void BakeBindPoseToolButton(MaterialEditor materialEditor, Renderer targetRenderer)
    {
        if (FeathersAndFurToolUtilities.IndentedButton("Bake Mesh Bind Pose"))
        {
            FeathersAndFurBindPoseBaker meshBakingWindow = EditorWindow.GetWindow<FeathersAndFurBindPoseBaker>(false, "Bind Pose Baker", true);
            meshBakingWindow.SetTarget(materialEditor.target as Material, targetRenderer);
            meshBakingWindow.Show();
        }
    }

    //add a button to open the coat painting mask tool
    private void CoatPaintingToolButton(MaterialEditor materialEditor, Renderer targetRenderer, FeathersAndFurMaterialProperties properties)
    {
        //if the user has the coat painting tool in their project
        if (cCoatPaintingToolType != null)
        {
            //add the button to open it
            if (FeathersAndFurToolUtilities.IndentedButton("Open Coat Painting Tool"))
            {
                FeathersAndFurCoatPaintingToolWrapper paintingToolWindow = EditorWindow.GetWindow(cCoatPaintingToolType, false, "Coat Painting Tool", true) as FeathersAndFurCoatPaintingToolWrapper;
                paintingToolWindow.SetTarget(materialEditor.target as Material, targetRenderer);
                paintingToolWindow.Show();
            }
        }
        else if (properties.coatParametersTexture.textureValue == null
                    && properties.coatDirectionTexture.textureValue == null)
        {
            //if the user has not manually assigned textures and does not have the coat painting tool, tell them what it does
            EditorGUILayout.HelpBox("Get the premium version to paint feather/fur cards directly in the editor!", MessageType.Info);
        }
    }

    //add a button to open the clothing mask editor
    private void ClothingMaskToolButton(MaterialEditor materialEditor, Renderer targetRenderer, bool editingPackedMask, FeathersAndFurMaterialProperties properties)
    {
        //if the user has the clothing mask editor in their project
        if (cClothingMaskEditorType != null)
        {
            //change the tool name based on which type of mask we are editing
            string editorName = editingPackedMask ? "Packed Clothing Mask Editor" : "Full Clothing Mask Editor";

            if (FeathersAndFurToolUtilities.IndentedButton("Open " + editorName))
            {
                FeathersAndFurClothingMaskEditorWrapper clothingMaskWindow = EditorWindow.GetWindow(cClothingMaskEditorType, false, editorName, true) as FeathersAndFurClothingMaskEditorWrapper;
                clothingMaskWindow.SetTarget(materialEditor.target as Material, targetRenderer, editingPackedMask);
                clothingMaskWindow.Show();
            }
        }
        else
        {
            //if the user does not have the clothing mask editor and has not assigned a mask texture, tell them what it does
            if (editingPackedMask)
            {
                if (properties.clothingMaskPackedTexture.textureValue == null)
                {
                    EditorGUILayout.HelpBox("Get the premium version to pack up to 32 clothing masks into a single texture!", MessageType.Info);
                }
            }
            else
            {
                if (properties.clothingMaskFullTexture.textureValue == null)
                {
                    EditorGUILayout.HelpBox("Get the premium version to automatically generate clothing masks!", MessageType.Info);
                }
            }
        }
    }

    //add a button to enable or disable linking for a set of undercoat and coat properties
    public void LinkUnlinkParametersButton(bool doPropertiesMatch, ref bool linkingEnabled, ref bool undercoatDropdown, ref bool coatDropdown)
    {
        //automatically disable the linking if the properties do not actually match
        linkingEnabled = linkingEnabled && doPropertiesMatch;

        if (linkingEnabled) //if matching is enabled (and implicitly if the properties actually match)
        {
            if (FeathersAndFurToolUtilities.IndentedButton("Unlink Coat/Undercoat Properties"))
            {
                linkingEnabled = false;

                //open both dropdowns when linking is disabled
                undercoatDropdown = true;
                coatDropdown = true;
            }
        }
        else if (doPropertiesMatch) //if the properties match but linking is disabled
        {
            if (FeathersAndFurToolUtilities.IndentedButton("Link Coat/Undercoat Properties"))
            {
                linkingEnabled = true;

                //open both dropdowns when linking is enabled
                undercoatDropdown = true;
                coatDropdown = true;
            }
        }
        else //if the properties do not match
        {
            //draw a dark rectangle in the same place as the button
            Rect rect = EditorGUI.IndentedRect(EditorGUILayout.GetControlRect());
            EditorGUI.DrawRect(rect, FeathersAndFurToolUtilities.sBackgroundColor);

            //center the text
            rect.x += rect.width / 2.0f;
            rect.width = Mathf.Min(rect.width, 270.0f);
            rect.x -= rect.width / 2.0f;

            //for some inexplicable reason, using a label causes us to switch to editing a different property
            //when this if statement changes while dragging a slider
            //so just add a button that does nothing and looks like a label
            GUI.Button(rect, "Coat and Undercoat Properties Do Not Match", EditorStyles.label);
        }

        EditorGUILayout.Space();
    }

    //Shader Property Match Checking Helper Functions ----------------------------------------------

    private bool DoFloatPropertiesMatch(MaterialProperty first, MaterialProperty second)
    {
        return Mathf.Abs(first.floatValue - second.floatValue) < Mathf.Epsilon;
    }

    private bool DoColorPropertiesMatch(MaterialProperty first, MaterialProperty second)
    {
        //color properties are considered matching if the difference of their components is less than
        //the smallest possible difference between two 8-bit color values
        const float cColorEpsilon = 0.5f / 255.0f;

        Color difference = first.colorValue - second.colorValue;

        return Mathf.Abs(difference.r) < cColorEpsilon
            && Mathf.Abs(difference.g) < cColorEpsilon
            && Mathf.Abs(difference.b) < cColorEpsilon
            && Mathf.Abs(difference.a) < cColorEpsilon;
    }

    private bool DoTexturePropertiesMatch(MaterialProperty first, MaterialProperty second)
    {
        Vector4 scaleOffsetDifference = first.textureScaleAndOffset - second.textureScaleAndOffset;

        //texture properties will only be considered matching if both the texture itself
        //and the scale and offset settings are the same
        return first.textureValue == second.textureValue
            && Mathf.Abs(scaleOffsetDifference.x) < Mathf.Epsilon
            && Mathf.Abs(scaleOffsetDifference.y) < Mathf.Epsilon
            && Mathf.Abs(scaleOffsetDifference.z) < Mathf.Epsilon
            && Mathf.Abs(scaleOffsetDifference.w) < Mathf.Epsilon;
    }

    //Undercoat And Coat Match Checking Functions --------------------------------------------------

    private bool DoUndercoatAndCoatColorPropertiesMatch(FeathersAndFurMaterialProperties properties)
    {
        return DoTexturePropertiesMatch(properties.undercoatAlbedoTexture, properties.coatAlbedoTexture)
            && DoColorPropertiesMatch(properties.undercoatAlbedoTint, properties.coatAlbedoTint)
            && DoFloatPropertiesMatch(properties.undercoatCutoutEnabled, properties.coatCutoutEnabled)
            && DoFloatPropertiesMatch(properties.undercoatCutoutThreshold, properties.coatCutoutThreshold);
    }

    private bool DoUndercoatAndCoatEmissionPropertiesMatch(FeathersAndFurMaterialProperties properties)
    {
        return DoTexturePropertiesMatch(properties.undercoatEmissionTexture, properties.coatEmissionTexture)
            && DoColorPropertiesMatch(properties.undercoatEmissionTint, properties.coatEmissionTint);
    }

    private bool DoUndercoatAndCoatMaterialPropertiesMatch(FeathersAndFurMaterialProperties properties)
    {
        bool allMatching = DoTexturePropertiesMatch(properties.undercoatMaterialParametersTexture, properties.coatMaterialParametersTexture)
                        && DoFloatPropertiesMatch(properties.undercoatReflectivenessMax, properties.coatReflectivenessMax)
                        && DoFloatPropertiesMatch(properties.undercoatRoughnessMax, properties.coatRoughnessMax)
                        && DoFloatPropertiesMatch(properties.undercoatIridescentThicknessMax, properties.coatIridescentThicknessMax)
                        && DoFloatPropertiesMatch(properties.undercoatAmbientOcclusionMax, properties.coatAmbientOcclusionMax);

        //the min values are only used when a texture is set, so ignore them otherwise
        if (properties.undercoatMaterialParametersTexture.textureValue != null)
        {
            allMatching = allMatching
                        && DoFloatPropertiesMatch(properties.undercoatReflectivenessMin, properties.coatReflectivenessMin)
                        && DoFloatPropertiesMatch(properties.undercoatRoughnessMin, properties.coatRoughnessMin)
                        && DoFloatPropertiesMatch(properties.undercoatIridescentThicknessMin, properties.coatIridescentThicknessMin)
                        && DoFloatPropertiesMatch(properties.undercoatAmbientOcclusionMin, properties.coatAmbientOcclusionMin);
        }

        return allMatching;
    }

    private bool DoUndercoatAndCoatAdditionalMaterialPropertiesMatch(FeathersAndFurMaterialProperties properties)
    {
        bool allMatching = DoTexturePropertiesMatch(properties.undercoatAdditionalMaterialParametersTexture, properties.coatAdditionalMaterialParametersTexture)
                        && DoFloatPropertiesMatch(properties.undercoatFurnessMax, properties.coatFurnessMax)
                        && DoFloatPropertiesMatch(properties.undercoatDiameterMax, properties.coatDiameterMax)
                        && DoFloatPropertiesMatch(properties.undercoatSelfShadowMaskMax, properties.coatSelfShadowMaskMax)
                        && DoFloatPropertiesMatch(properties.undercoatAmbientTransmissionOcclusionMax, properties.coatAmbientTransmissionOcclusionMax);

        //the min values are only used when a texture is set, so ignore them otherwise
        if (properties.undercoatAdditionalMaterialParametersTexture.textureValue != null)
        {
            allMatching = allMatching
                        && DoFloatPropertiesMatch(properties.undercoatFurnessMin, properties.coatFurnessMin)
                        && DoFloatPropertiesMatch(properties.undercoatDiameterMin, properties.coatDiameterMin)
                        && DoFloatPropertiesMatch(properties.undercoatSelfShadowMaskMin, properties.coatSelfShadowMaskMin)
                        && DoFloatPropertiesMatch(properties.undercoatAmbientTransmissionOcclusionMin, properties.coatAmbientTransmissionOcclusionMin);
        }

        return allMatching;
    }

    private bool DoUndercoatAndCoatNormalPropertiesMatch(FeathersAndFurMaterialProperties properties)
    {
        return DoTexturePropertiesMatch(properties.undercoatFurRootNormalTexture, properties.coatFurRootNormalTexture)
            && DoFloatPropertiesMatch(properties.undercoatFurRootNormalStrength, properties.coatFurRootNormalStrength)
            && DoFloatPropertiesMatch(properties.undercoatFurRootNormalDiffuseInfluence, properties.coatFurRootNormalDiffuseInfluence);
    }

    //Match Undercoat And Coat Functions -----------------------------------------------------------

    private void MatchUndercoatAndCoatColorProperties(FeathersAndFurMaterialProperties properties)
    {
        if (!DoTexturePropertiesMatch(properties.undercoatAlbedoTexture, properties.coatAlbedoTexture))
        {
            properties.coatAlbedoTexture.textureValue = properties.undercoatAlbedoTexture.textureValue;
            properties.coatAlbedoTexture.textureScaleAndOffset = properties.undercoatAlbedoTexture.textureScaleAndOffset;
        }

        if (!DoColorPropertiesMatch(properties.undercoatAlbedoTint, properties.coatAlbedoTint))
        {
            properties.coatAlbedoTint.colorValue = properties.undercoatAlbedoTint.colorValue;
        }

        if (!DoFloatPropertiesMatch(properties.undercoatCutoutEnabled, properties.coatCutoutEnabled))
        {
            properties.coatCutoutEnabled.floatValue = properties.undercoatCutoutEnabled.floatValue;
        }

        if (!DoFloatPropertiesMatch(properties.undercoatCutoutThreshold, properties.coatCutoutThreshold))
        {
            properties.coatCutoutThreshold.floatValue = properties.undercoatCutoutThreshold.floatValue;
        }
    }

    private void MatchUndercoatAndCoatEmissionProperties(FeathersAndFurMaterialProperties properties)
    {
        if (!DoTexturePropertiesMatch(properties.undercoatEmissionTexture, properties.coatEmissionTexture))
        {
            properties.coatEmissionTexture.textureValue = properties.undercoatEmissionTexture.textureValue;
            properties.coatEmissionTexture.textureScaleAndOffset = properties.undercoatEmissionTexture.textureScaleAndOffset;
        }

        if (!DoColorPropertiesMatch(properties.undercoatEmissionTint, properties.coatEmissionTint))
        {
            properties.coatEmissionTint.colorValue = properties.undercoatEmissionTint.colorValue;
        }
    }

    private void MatchUndercoatAndCoatMaterialProperties(FeathersAndFurMaterialProperties properties)
    {
        //check the coat's texture as the undercoat's texture could have just been set
        //therefore the min values could have been ignored while checking if the properties matched this frame
        //as they would not have been in use prior to the texture being set
        bool minValuesUsed = properties.coatMaterialParametersTexture.textureValue != null;

        if (!DoTexturePropertiesMatch(properties.undercoatMaterialParametersTexture, properties.coatMaterialParametersTexture))
        {
            properties.coatMaterialParametersTexture.textureValue = properties.undercoatMaterialParametersTexture.textureValue;
            properties.coatMaterialParametersTexture.textureScaleAndOffset = properties.undercoatMaterialParametersTexture.textureScaleAndOffset;
        }

        if (!DoFloatPropertiesMatch(properties.undercoatReflectivenessMax, properties.coatReflectivenessMax))
        {
            properties.coatReflectivenessMax.floatValue = properties.undercoatReflectivenessMax.floatValue;
        }

        if (!DoFloatPropertiesMatch(properties.undercoatRoughnessMax, properties.coatRoughnessMax))
        {
            properties.coatRoughnessMax.floatValue = properties.undercoatRoughnessMax.floatValue;
        }

        if (!DoFloatPropertiesMatch(properties.undercoatIridescentThicknessMax, properties.coatIridescentThicknessMax))
        {
            properties.coatIridescentThicknessMax.floatValue = properties.undercoatIridescentThicknessMax.floatValue;
        }

        if (!DoFloatPropertiesMatch(properties.undercoatAmbientOcclusionMax, properties.coatAmbientOcclusionMax))
        {
            properties.coatAmbientOcclusionMax.floatValue = properties.undercoatAmbientOcclusionMax.floatValue;
        }

        //only match these values if they were in use at the start of this frame
        if (minValuesUsed)
        {
            if (!DoFloatPropertiesMatch(properties.undercoatReflectivenessMin, properties.coatReflectivenessMin))
            {
                properties.coatReflectivenessMin.floatValue = properties.undercoatReflectivenessMin.floatValue;
            }

            if (!DoFloatPropertiesMatch(properties.undercoatRoughnessMin, properties.coatRoughnessMin))
            {
                properties.coatRoughnessMin.floatValue = properties.undercoatRoughnessMin.floatValue;
            }

            if (!DoFloatPropertiesMatch(properties.undercoatIridescentThicknessMin, properties.coatIridescentThicknessMin))
            {
                properties.coatIridescentThicknessMin.floatValue = properties.undercoatIridescentThicknessMin.floatValue;
            }

            if (!DoFloatPropertiesMatch(properties.undercoatAmbientOcclusionMin, properties.coatAmbientOcclusionMin))
            {
                properties.coatAmbientOcclusionMin.floatValue = properties.undercoatAmbientOcclusionMin.floatValue;
            }
        }
    }

    private void MatchUndercoatAndCoatAdditionalMaterialProperties(FeathersAndFurMaterialProperties properties)
    {
        //check the coat's texture as the undercoat's texture could have just been set
        //therefore the min values could have been ignored while checking if the properties matched this frame
        //as they would not have been in use prior to the texture being set
        bool minValuesUsed = properties.coatAdditionalMaterialParametersTexture.textureValue != null;

        if (!DoTexturePropertiesMatch(properties.undercoatAdditionalMaterialParametersTexture, properties.coatAdditionalMaterialParametersTexture))
        {
            properties.coatAdditionalMaterialParametersTexture.textureValue = properties.undercoatAdditionalMaterialParametersTexture.textureValue;
            properties.coatAdditionalMaterialParametersTexture.textureScaleAndOffset = properties.undercoatAdditionalMaterialParametersTexture.textureScaleAndOffset;
        }

        if (!DoFloatPropertiesMatch(properties.undercoatFurnessMax, properties.coatFurnessMax))
        {
            properties.coatFurnessMax.floatValue = properties.undercoatFurnessMax.floatValue;
        }

        if (!DoFloatPropertiesMatch(properties.undercoatDiameterMax, properties.coatDiameterMax))
        {
            properties.coatDiameterMax.floatValue = properties.undercoatDiameterMax.floatValue;
        }

        if (!DoFloatPropertiesMatch(properties.undercoatSelfShadowMaskMax, properties.coatSelfShadowMaskMax))
        {
            properties.coatSelfShadowMaskMax.floatValue = properties.undercoatSelfShadowMaskMax.floatValue;
        }

        if (!DoFloatPropertiesMatch(properties.undercoatAmbientTransmissionOcclusionMax, properties.coatAmbientTransmissionOcclusionMax))
        {
            properties.coatAmbientTransmissionOcclusionMax.floatValue = properties.undercoatAmbientTransmissionOcclusionMax.floatValue;
        }

        //only match these values if they were in use at the start of this frame
        if (minValuesUsed)
        {
            if (!DoFloatPropertiesMatch(properties.undercoatFurnessMin, properties.coatFurnessMin))
            {
                properties.coatFurnessMin.floatValue = properties.undercoatFurnessMin.floatValue;
            }

            if (!DoFloatPropertiesMatch(properties.undercoatDiameterMin, properties.coatDiameterMin))
            {
                properties.coatDiameterMin.floatValue = properties.undercoatDiameterMin.floatValue;
            }

            if (!DoFloatPropertiesMatch(properties.undercoatSelfShadowMaskMin, properties.coatSelfShadowMaskMin))
            {
                properties.coatSelfShadowMaskMin.floatValue = properties.undercoatSelfShadowMaskMin.floatValue;
            }

            if (!DoFloatPropertiesMatch(properties.undercoatAmbientTransmissionOcclusionMin, properties.coatAmbientTransmissionOcclusionMin))
            {
                properties.coatAmbientTransmissionOcclusionMin.floatValue = properties.undercoatAmbientTransmissionOcclusionMin.floatValue;
            }
        }
    }

    private void MatchUndercoatAndCoatNormalProperties(FeathersAndFurMaterialProperties properties)
    {
        if (!DoTexturePropertiesMatch(properties.undercoatFurRootNormalTexture, properties.coatFurRootNormalTexture))
        {
            properties.coatFurRootNormalTexture.textureValue = properties.undercoatFurRootNormalTexture.textureValue;
            properties.coatFurRootNormalTexture.textureScaleAndOffset = properties.undercoatFurRootNormalTexture.textureScaleAndOffset;
        }

        if (!DoFloatPropertiesMatch(properties.undercoatFurRootNormalStrength, properties.coatFurRootNormalStrength))
        {
            properties.coatFurRootNormalStrength.floatValue = properties.undercoatFurRootNormalStrength.floatValue;
        }

        if (!DoFloatPropertiesMatch(properties.undercoatFurRootNormalDiffuseInfluence, properties.coatFurRootNormalDiffuseInfluence))
        {
            properties.coatFurRootNormalDiffuseInfluence.floatValue = properties.undercoatFurRootNormalDiffuseInfluence.floatValue;
        }
    }
}
