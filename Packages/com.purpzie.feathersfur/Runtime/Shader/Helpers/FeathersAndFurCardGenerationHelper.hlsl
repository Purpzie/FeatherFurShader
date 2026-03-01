#pragma once

#include "FeathersAndFurCommonHelper.hlsl"

//Structs ------------------------------------------------------------------------------------------

struct CardGenerationVertexInput
{
    float3 position : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAl;
    float4 tangent : TANGENT;

#if defined(_BINDPOSEUVCHANNEL_UV2)
    float4 bindPose : TEXCOORD1;
#elif defined(_BINDPOSEUVCHANNEL_UV3)
    float4 bindPose : TEXCOORD2;
#elif defined(_BINDPOSEUVCHANNEL_UV4)
    float4 bindPose : TEXCOORD3;
#elif defined(_BINDPOSEUVCHANNEL_UV5)
    float4 bindPose : TEXCOORD4;
#elif defined(_BINDPOSEUVCHANNEL_UV6)
    float4 bindPose : TEXCOORD5;
#elif defined(_BINDPOSEUVCHANNEL_UV7)
    float4 bindPose : TEXCOORD6;
#elif defined(_BINDPOSEUVCHANNEL_UV8)
    float4 bindPose : TEXCOORD7;
#endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct CardGenerationTessellationControlPoint
{
    float2 uv : TEXCOORD0;
    float3 worldPosition : TEXCOORD1;
    float3 normal : TEXCOORD2;
    float4 tangent : TEXCOORD3;
    float3 bindPosition : TEXCOORD4;
    float skinnedMeshScale : TEXCOORD5;

    UNITY_VERTEX_OUTPUT_STEREO
};

struct CardGenerationTessellationConstants
{
    float TessFactor[3]    : SV_TessFactor;
    float InsideTessFactor : SV_InsideTessFactor;
    float triangleArea : TEXCOORD0;
    uint triangleHash : TEXCOORD1;
};

struct CardGenerationGeometryInput
{
    float2 uv : TEXCOORD0;
    float3 worldPosition : TEXCOORD1;
    float3 normal : TEXCOORD2;
    float4 tangent : TEXCOORD3;
    float skinnedMeshScale : TEXCOORD4;
    uint cardIndex : TEXCOORD5;
    float sourceTriangleArea : TEXCOORD6;
    float sourceTriangleHash : TEXCOORD7; //this is a float so the shadow pass can pack a UV component into it

    UNITY_VERTEX_OUTPUT_STEREO
};

struct CardGenerationInfo
{
    float3 cardLengthAxis;
    float3 cardWidthAxis;

    uint flipbookIndex;
    bool mirrorUvHorizontal;

#ifndef DEPTH_ONLY_PASS //self shadowing parameters not used for depth only passes
    float3 selfShadowLengthAxis;
    float3 selfShadowWidthAxis;
    float3 baseSelfShadowNormal;
    float selfShadowDensity;
#endif
};

//Helpers ------------------------------------------------------------------------------------------

//check if we are rendering from the main camera (as opposed to rendering into a shadow map) by checking if
//the current view and projection matrices match the main camera matrices
bool IsMainCameraPass()
{
    return all(UNITY_MATRIX_V[0] == unity_WorldToCamera[0])
        && all(UNITY_MATRIX_V[1] == unity_WorldToCamera[1])
        && all(UNITY_MATRIX_V[2] == -unity_WorldToCamera[2])
        && (abs(UNITY_MATRIX_P._m00) == abs(unity_CameraProjection._m00))
        && (abs(UNITY_MATRIX_P._m11) == abs(unity_CameraProjection._m11));
}

//check if we are rendering in a mirror by checking if the view matrix is flipped
//Unity's view matrix has a negative determinant by default 
bool IsMirrored()
{
    return determinant((float3x3)UNITY_MATRIX_V) > 0.0;
}

//randomly generates a float in the 0-1 range along with a new seed for the next random number
//via https://www.reddit.com/r/RNG/comments/jqnq20/the_wang_and_jenkins_integer_hash_functions_just/
float RandomNormalized(inout uint seed)
{
    seed ^= seed >> 16;
    seed *= 0xa812d533;
    seed ^= seed >> 15;
    seed *= 0xb278e4ad;
    seed ^= seed >> 17;

    return saturate(seed / 4294967295.0f);
}

//low descrepency sequence, via "The Unreasonable Effectiveness of Quasirandom Sequences"
//https://extremelearning.com.au/unreasonable-effectiveness-of-quasirandom-sequences/
float2 RobertsSequence2D(uint index)
{
    index = index % 65657; //avoid percision issues by limiting the range, the value at intex 65657 is close to the one at 0

    return frac((float2(0.75487768650054931640625, 0.56984031200408935546875) * index) + 0.5);
}

//get the max component of the world transform scale
float GetMaxCardTransformScale()
{
    float3 scale = float3(length(unity_ObjectToWorld._m00_m10_m20),
                          length(unity_ObjectToWorld._m01_m11_m21),
                          length(unity_ObjectToWorld._m02_m12_m22));
    scale *= abs(_CardRescale);

    return max(max(scale.x, scale.y), scale.z);
}

//get the amount of spacing between cards enforced by the LOD
float GetLodSpacing(float distance, float maxScale, bool isShadowPass)
{
    static const uint cMinLodResolution = 10;

    float minSpacing = isShadowPass ? max(_CardLodSpacingMin, _CardLodShadowSpacingMin) : _CardLodSpacingMin;

    distance /= maxScale; //when scale is non-uniform, just use the maximum component of scale as an approximation
    bool isOrthographic = UNITY_MATRIX_P._m33 != 0.0;
    float perspectiveAdjustedDistance = (isOrthographic ? 1.0 : distance) / abs(UNITY_MATRIX_P._m11);

    float renderResoltuion = _CardLodFixedResolutionEnabled ? max(cMinLodResolution, _CardLodFixedResolution) : _ScreenParams.y;

    float lodSpacing = _CardLodFactor * perspectiveAdjustedDistance / renderResoltuion;

    return max(minSpacing, min(lodSpacing, _CardLodSpacingMax));
}

//check if any of the cards a source triangle will generate will actually be visible on screen
//based on the source triangle's vertices' clip positions and the maximum extent of its cards
bool AreCardsFromSourceTriangleOffScreen(float4 clipPosA, float4 clipPosB, float4 clipPosC, float maxCardDistanceFromTriangle)
{
    float minDepth = min(min(clipPosA.w, clipPosB.w), clipPosC.w);
    float closestCardDepth = minDepth - maxCardDistanceFromTriangle;

    //if any of the resulting cards could be behind the camera
    if (closestCardDepth < 0.0)
    {
        //check if any of the resulting cards are in front of the camera
        float maxDepth = max(clipPosA.w, max(clipPosB.w, clipPosC.w));
        return maxDepth + maxCardDistanceFromTriangle < 0;
    }

    float2 normalizedDeviceCoordA = clipPosA.xy / clipPosA.w;
    float2 normalizedDeviceCoordB = clipPosB.xy / clipPosB.w;
    float2 normalizedDeviceCoordC = clipPosC.xy / clipPosC.w;

    float2 minTriangleCorner = min(min(normalizedDeviceCoordA, normalizedDeviceCoordB), normalizedDeviceCoordC);
    float2 maxTriangleCorner = max(max(normalizedDeviceCoordA, normalizedDeviceCoordB), normalizedDeviceCoordC);

    float2 distanceToScreenEdge = max(minTriangleCorner, -maxTriangleCorner) - 1.0;
    float2 clipSpaceDistanceToScreenEdge = distanceToScreenEdge * closestCardDepth;

    float2 fovAdjustedCardExtents = maxCardDistanceFromTriangle * abs(UNITY_MATRIX_P._m00_m11);

    return any(clipSpaceDistanceToScreenEdge > fovAdjustedCardExtents);
}

//get the minimum and maximum sizes of all the cards generated from a source triangle from the optimization texturre
//uses the uv of each of the source triangle's vertices
float2 GetMinMaxCardSizeForTriangle(float2 uvA, float2 uvB, float2 uvC)
{
    uvA = TRANSFORM_TEX(uvA, _CoatParametersTexture);
    uvB = TRANSFORM_TEX(uvB, _CoatParametersTexture);
    uvC = TRANSFORM_TEX(uvC, _CoatParametersTexture);

    float2 lowerUVCorner = min(min(uvA, uvB), uvC);
    float2 upperUVCorner = max(max(uvA, uvB), uvC);

    //determine the mip level where the uv bounding box is enclosed by a 2x2 set of texels
    float2 uvBoundingBoxSize = upperUVCorner - lowerUVCorner;
    float2 sizeInTexels = uvBoundingBoxSize * _CoatOptimizationTexture_TexelSize.zw;
    float mipLevel = ceil(log2(sizeInTexels)); //out of bounds mips are automaticly clamped

    //gather the min and max values from the 2x2 set of texels
    //(min size is stored in the green channel and max size is stored in the red channel)
    float minSize = 1.0;
    float maxSize = 0.0;

    float2 texelValues = _CoatOptimizationTexture.SampleLevel(sampler_PointRepeat, lowerUVCorner, mipLevel);
    minSize = min(minSize, texelValues.g);
    maxSize = max(maxSize, texelValues.r);

    texelValues = _CoatOptimizationTexture.SampleLevel(sampler_PointRepeat, float2(lowerUVCorner.x, upperUVCorner.y), mipLevel);
    minSize = min(minSize, texelValues.g);
    maxSize = max(maxSize, texelValues.r);

    texelValues = _CoatOptimizationTexture.SampleLevel(sampler_PointRepeat, float2(upperUVCorner.x, lowerUVCorner.y), mipLevel);
    minSize = min(minSize, texelValues.g);
    maxSize = max(maxSize, texelValues.r);

    texelValues = _CoatOptimizationTexture.SampleLevel(sampler_PointRepeat, upperUVCorner, mipLevel);
    minSize = min(minSize, texelValues.g);
    maxSize = max(maxSize, texelValues.r);

    return saturate(float2(minSize, maxSize));
}

//calculate the tessellation factors that will cause the tessellation stage to generate the specified number of vertices 
uint4 GetTessellationFactorsToGenerateSpecifiedVertexCount(uint idealVertexCount, bool onlyRenderBaseTriangleInDepthPass)
{
    //3169 is the max number of vertices tessellation can generate, but one is reserved for the base triangle during shadowcasting
    idealVertexCount = min(idealVertexCount, 3168);

#ifdef DEPTH_ONLY_PASS
    //add an extra tri for the base triangle in depth only mode
    idealVertexCount = onlyRenderBaseTriangleInDepthPass ? 1 : idealVertexCount + 1;
#endif

    //we can't create less than 3 vertices without completely culling the triangle
    if (idealVertexCount <= 3)
    {
        //this just creates 3 vertices
        return uint4(1, 1, 1, 0);
    }

    uint vertexCount = 3; //we are always generating at least 3 vertices

    //-0.155 bias always gives an inside tessellation factor that will result in slightly less vertices than requested
    uint insideTessellationFactor = floor(sqrt((idealVertexCount - vertexCount) / 0.75) + 1.0 + -0.155);
    insideTessellationFactor = clamp(insideTessellationFactor, 2, 64); //an inside tessellation factor of < 2 does nothing

    //add the number of vertices that will be actually be created from the inside tessellation to the count
    vertexCount += ceil(pow(insideTessellationFactor - 1, 2) * 0.75);

    //generate the rest of the vertices with the edge tessellation
    uint edgeTessellationFactors[3];
    for (uint edgeIndex = 0; edgeIndex < 3; edgeIndex++)
    {
        //we can generate between 0 and 63 additional vertices per edge
        uint additionalVerticesFromEdge = clamp(idealVertexCount - vertexCount, 0, 63);

        edgeTessellationFactors[edgeIndex] = additionalVerticesFromEdge + 1;

        vertexCount += additionalVerticesFromEdge;
    }

    return uint4(edgeTessellationFactors[0], edgeTessellationFactors[1], edgeTessellationFactors[2], insideTessellationFactor);
}

//get an ordered index for each of the vertices being generated by the tessellation stage based on their domain location
uint GetTessellatedVertexOrdering(float3 domainLocation, uint insideTessellationFactor, uint3 edgeTessellationFactors)
{
    float barycentricDistanceFromClosestEdge = min(min(domainLocation.x, domainLocation.y), domainLocation.z);

    //group the vertices into 3 symetrical sectors based on which edge they are closest to

    static const float cBarycentricDistanceEpsilon = 0.0001; //getting more precise than this causes errors
    bool3 isClosestToEdge = abs(domainLocation - barycentricDistanceFromClosestEdge) < cBarycentricDistanceEpsilon;

    uint sectorIndex = 3; //if there is a vertex right in the middle of the source triangle it gets put into a "fourth" sector
    if (isClosestToEdge.x && !isClosestToEdge.z) //break ties with radial symmetry
    {
        sectorIndex = 0;
    }
    else if (isClosestToEdge.y && !isClosestToEdge.x)
    {
        sectorIndex = 1;
    }
    else if (isClosestToEdge.z && !isClosestToEdge.y)
    {
        sectorIndex = 2;
    }

    //get the number of vertices in the inner region off each sector (not including the vertices on the edge)

    //sectors are pyramid shaped, get the width from the middle column to the edge
    uint sectorInnerHalfWidth = insideTessellationFactor > 2 ? insideTessellationFactor / 2 : 0;
    uint sectorInnerHeight = (insideTessellationFactor - 1) / 2;
    uint totalInInnerSector = sectorInnerHalfWidth * sectorInnerHeight;

    //get the position of the vertex in the sector 

    float widthPosition = barycentricDistanceFromClosestEdge / 2.0;
    widthPosition += sectorIndex == 0 ? domainLocation.y : (sectorIndex == 1 ? domainLocation.z : domainLocation.x);

    float heightPosition = 1.0 - saturate(barycentricDistanceFromClosestEdge * 3.0);

    //get the coordinates of the vertex in the sector, and use that to calculate a flattened index

    uint rowIndex = round(heightPosition * (sectorInnerHeight + 1)) - 1;

    uint index = 0;
    if (rowIndex >= sectorInnerHeight) //if this vertex is on the outer edge of the triangle
    {
        //the number of vertices on the edge is determined by the edge tessellation factor
        uint edgeColumnIndex = round(widthPosition * edgeTessellationFactors[sectorIndex]);

        //order the vertices on the edge after all the vertices in the inner sector
        index = edgeColumnIndex + totalInInnerSector;
    }
    else
    {
        uint columnIndex = round(widthPosition * insideTessellationFactor) - 1;

        //fold over the right half of the pyramid to make a rectangle 
        if (columnIndex >= sectorInnerHalfWidth)
        {
            columnIndex -= sectorInnerHalfWidth;
            rowIndex = (sectorInnerHeight - 1) - rowIndex;
        }

        index = columnIndex + (rowIndex * sectorInnerHalfWidth);
    }

    //special case for the center vert: it's the only vertex in its "sector" so just set its index to 0
    if (sectorIndex > 2)
    {
        index = 0;
    }

    //offset the starting index for each sector by the total number of vertices in all previous sectors
    for (uint previousSector = 0; previousSector < sectorIndex; previousSector++)
    {
        index += totalInInnerSector + edgeTessellationFactors[previousSector];
    }

    return index;
}

//apply LODing by discarding excess cards and adjusting the size of the remaining cards (return negative size for culled cards)
float2 CullCardsAndAdjustSizeForLod(uint cardIndex, float3 worldPosition,
                                    float2 cardSize, float cardSpacing,
                                    float triangleArea, float skinnedMeshScale,
                                    bool isShadowPass)
{
    float distanceToCamera = length(worldPosition - _WorldSpaceCameraPos);
    float maxScale = GetMaxCardTransformScale() * skinnedMeshScale;
    float lodSpacing = GetLodSpacing(distanceToCamera, maxScale, isShadowPass);

    //calculate the maximum number of cards based on the LOD spacing and throw out anything beyond that
    uint lodMaxCardCount = max(0.0, (triangleArea / (lodSpacing * lodSpacing)));
    if (cardIndex > lodMaxCardCount)
    {
        -1.0;
    }

    //resize remaining cards to cover gaps caused by the LOD removing cardss
    float spacingDelta = max(0.0, lodSpacing - cardSpacing);
    return cardSize + (spacingDelta * _CardLodGrowth);
}

//check if this card should be thrown out based on the actual desired card cout at this location, the coat parameters texture mask,
//and the opacity cutout (the cloathing mask is pre-combined with the mask and so is handled implicitly)
bool ShouldDiscardCard(uint cardIndex, float cardMask, float cardSpacing, float triangleArea, float2 uv, inout uint triangeHash)
{
    float idealCardCount = (triangleArea / (cardSpacing * cardSpacing)) * saturate(cardMask);

    //when the ideal card count is not a round number, give the last card a chance of being discarded based on the fractional part
    float discardChance = (cardIndex + 1) - idealCardCount;
    if (RandomNormalized(triangeHash) < discardChance)
    {
        return true;
    }

    [branch]
    if (_CoatCutoutEnabled)
    {
        float coatAlpha = _CoatAlbedoTexture.SampleLevel(sampler_CoatAlbedoTexture, TRANSFORM_TEX(uv, _CoatAlbedoTexture), 0.0).a;

        if (coatAlpha < _CoatCutoutThreshold)
        {
            return true;
        }
    }

    return false;
}

//get the length and width directions of the the card's rectangle in local space (use inout for the random seed so further random numbers are not repeated)
void GetCardLocalDirections(float2 uv, float3 worldPosition, float3 normal, float3 tangent, float3 bitangent, float cardSize,
                            out float3 lengthDirection, out float3 widthDirection, inout uint cardSeed)
{
    //card direction is in tangent space
    float3 coatDirection = UnpackNormal(_CoatDirectionTexture.SampleLevel(sampler_CoatDirectionTexture, TRANSFORM_TEX(uv, _CoatDirectionTexture), 0.0));

    //adjust the elevation of the card

    float randomElevation = RandomNormalized(cardSeed);
    float cardElevation = lerp(coatDirection.z, randomElevation, _CardElevationRandomness);
    cardElevation = lerp(_CardElevationMin, _CardElevationMax, saturate(cardElevation));

    //adjust the orientation of the card

    float randomAngle = RandomNormalized(cardSeed) * 2.0 * cPi;
    float randomRadius = max(cEpsilon, sqrt(RandomNormalized(cardSeed)));
    float2 randomPointOnCircle = float2(cos(randomAngle), sin(randomAngle)) * randomRadius;
    float2 cardOrientation = lerp(coatDirection.xy, randomPointOnCircle, _CardOrientationRandomness);
    cardOrientation = length(cardOrientation) > cEpsilon ? cardOrientation : randomPointOnCircle;
    cardOrientation = normalize(cardOrientation);

    //rescale the orientation so the combined direction is normalized, but bias a little to avoid the singularity
    cardOrientation *= max(cEpsilon, sqrt(1.0 - saturate(cardElevation * cardElevation)));

    lengthDirection = (cardOrientation.x * tangent)
                    + (cardOrientation.y * bitangent)
                    + (cardElevation * normal);
    lengthDirection = normalize(lengthDirection);

    //randomly rotate the card about it's length direction

    float rotation = saturate((cardElevation - _CardRotationRandomnessElevationStart) / (_CardRotationRandomnessElevationEnd - _CardRotationRandomnessElevationStart));
    rotation = lerp(_CardRotationRandomnessMin, _CardRotationRandomnessMax, rotation);
    rotation *= (RandomNormalized(cardSeed) - 0.5) * 2.0;

    float3 cardNormal = normalize(normal - (lengthDirection * dot(normal, lengthDirection)));
    cardNormal = normalize(cardNormal + (cross(lengthDirection, cardNormal) * rotation));

    //apply billboarding

    //get the strength of the billboarding

    float billboardElevationStrength = saturate((cardElevation - _CardBillboardingElevationStart) / (_CardBillboardingElevationEnd - _CardBillboardingElevationStart));
    float billboardSizeStrength = saturate((cardSize - _CardBillboardingSizeStart) / (_CardBillboardingSizeEnd - _CardBillboardingSizeStart));
    float billboardStrength = lerp(_CardBillboardingMin, _CardBillboardingMax, billboardElevationStrength * billboardSizeStrength);

    //get the view vector in local space

#ifdef USING_STEREO_MATRICES
    //use the point inbetween the eyes for billboarding so there isn't a weird mismatch between the left and right eyes
    float3 cameraCenterPosition = (unity_StereoMatrixInvV[0]._m03_m13_m23 + unity_StereoMatrixInvV[1]._m03_m13_m23) / 2.0;
#else
    float3 cameraCenterPosition = unity_MatrixInvV._m03_m13_m23;
#endif
    bool isOrthographic = UNITY_MATRIX_P._m33 != 0.0;
    float3 viewDirection = isOrthographic ? UNITY_MATRIX_I_V._m02_m12_m22 : cameraCenterPosition - worldPosition;
    float3 localViewDirection = normalize(mul(unity_WorldToObject, float4(viewDirection, 0.0)).xyz);

    //rotate the card normal towards the view direction

    //scale down the view direction when it is perpendicular to the original card normal which has
    //the effect of reducing the amount of billboarding at grazing angles and avoiding sudden flips in direction
    //this also ensures that cards which are already facing away from the camera will turn further away rather than spinning around 
    float3 scaledViewDirection = localViewDirection * dot(localViewDirection, cardNormal);

    float3 adjustedCardNormal = lerp(cardNormal, scaledViewDirection, billboardStrength);

    widthDirection = normalize(cross(lengthDirection, adjustedCardNormal));
}

//get the information needed to generate vertices for a card
bool GetCardGenerationInfo(CardGenerationGeometryInput input, out CardGenerationInfo output)
{
    UNITY_INITIALIZE_OUTPUT(CardGenerationInfo, output);

    //get the basic parameters of the card

    float4 cardParameters = _CoatParametersTexture.SampleLevel(sampler_CoatParametersTexture, TRANSFORM_TEX(input.uv, _CoatParametersTexture), 0.0);
    float cardSpacing = GetCardSpacing(cardParameters.x);
    float2 cardSize = GetCardShape(cardParameters.x) * cardSpacing;

    //apply LODing

    float2 cardLodSize = CullCardsAndAdjustSizeForLod(input.cardIndex, input.worldPosition, cardSize, cardSpacing, input.sourceTriangleArea, input.skinnedMeshScale, false);

    if (any(cardLodSize <= 0.0))
    {
        return false; //cards that are culled by LODing have their size set to a negative value
    }

    float cardMask = min(cardParameters.w, GetClothingMask(input.uv).x);

    //check if this card should be discarded

    uint sourceTriangleHash = asuint(input.sourceTriangleHash);
    if (ShouldDiscardCard(input.cardIndex, cardMask, cardSpacing, input.sourceTriangleArea, input.uv, sourceTriangleHash))
    {
        return false;
    }

    //get the card's axes

    uint cardSeed = sourceTriangleHash + input.cardIndex;
    float3 bitangent = cross(input.normal, input.tangent.xyz) * input.tangent.w * unity_WorldTransformParams.w;

    float3 cardLocalLengthDirection;
    float3 cardLocalWidthDirection;
    GetCardLocalDirections(input.uv,
                           input.worldPosition,
                           input.normal,
                           input.tangent.xyz,
                           bitangent,
                           cardParameters.x,
                           cardLocalLengthDirection,
                           cardLocalWidthDirection,
                           cardSeed);

    output.cardWidthAxis = cardLocalWidthDirection * cardLodSize.x * abs(_CardRescale) * input.skinnedMeshScale;
    output.cardWidthAxis = mul((float3x3)unity_ObjectToWorld, output.cardWidthAxis);

    output.cardLengthAxis = cardLocalLengthDirection * cardLodSize.y * abs(_CardRescale) * input.skinnedMeshScale;
    output.cardLengthAxis = mul((float3x3)unity_ObjectToWorld, output.cardLengthAxis);

    //get card flipbook index and uv mirroring

    float flipbookFactor = RandomNormalized(cardSeed);
    output.mirrorUvHorizontal = cardSeed & 1u;

    output.flipbookIndex = 0;
    if (_CardAtlasTextureCount > 1)
    {
        output.flipbookIndex = frac(cardParameters.y + (cardParameters.z * flipbookFactor)) * _CardAtlasTextureCount;
        output.flipbookIndex = max(0, min(output.flipbookIndex, _CardAtlasTextureCount - 1));
    }

#ifndef DEPTH_ONLY_PASS
    //get self shadowing parameters not used for depth only passes

    output.selfShadowLengthAxis = cardLocalLengthDirection * cardSize.y;
    output.selfShadowWidthAxis = cardLocalWidthDirection * cardSize.x;

    output.baseSelfShadowNormal = UnpackNormalWithScale(_CoatFurRootNormalTexture.SampleLevel(sampler_CoatFurRootNormalTexture, TRANSFORM_TEX(input.uv, _CoatFurRootNormalTexture), 0.0), _CoatFurRootNormalStrength);
    output.baseSelfShadowNormal = (output.baseSelfShadowNormal.x * input.tangent.xyz)
                                + (output.baseSelfShadowNormal.y * bitangent)
                                + (output.baseSelfShadowNormal.z * input.normal);
    output.baseSelfShadowNormal = normalize(output.baseSelfShadowNormal);

    output.selfShadowDensity = cardMask * cardSize.x * cardSize.y / (cardSpacing * cardSpacing);
#endif

    return true;
}

//transform the UVs to sample a given texture in the atlas
float2 GetCardTextureAtlasUv(float2 baseUv, uint textureIndex)
{
    //if the texture atlas dosn't have multiple textures in it, just return the original UV
    if (_CardAtlasTextureCount <= 1)
    {
        return baseUv;
    }
    
    textureIndex = min(textureIndex, _CardAtlasTextureCount - 1); //shouldn't be necessary, but just in case

    uint texturesPerRow = clamp(_CardAtlasTexturesPerRow, 1, _CardAtlasTextureCount);
    uint texturesPerColumn = (_CardAtlasTextureCount + texturesPerRow - 1) / texturesPerRow; //round up

    uint2 atlasTextureCoordinate = uint2(textureIndex % texturesPerRow, textureIndex / texturesPerRow);
    return (baseUv + atlasTextureCoordinate) / float2(texturesPerRow, texturesPerColumn);
}

//recreate functionality of UnityClipSpaceShadowCasterPos() but return a world position instead
float3 WorldSpaceShadowCasterPos(float3 worldPosition, float3 worldNormal)
{
#if !defined(SHADOWS_CUBE) || defined(SHADOWS_CUBE_IN_DEPTH_TEX)
    if (unity_LightShadowBias.z != 0.0)
    {
        float3 wLight = normalize(UnityWorldSpaceLightDir(worldPosition));

        float shadowCos = dot(worldNormal, wLight);
        float shadowSine = sqrt(1.0 - saturate(shadowCos * shadowCos));
        float normalBias = unity_LightShadowBias.z * shadowSine;

        worldPosition -= worldNormal * normalBias;
    }
#endif

    return worldPosition;
}

//Shader Functions ---------------------------------------------------------------------------------

CardGenerationTessellationControlPoint CardGenerationVertexShader(CardGenerationVertexInput input)
{
    UNITY_SETUP_INSTANCE_ID(input);

    CardGenerationTessellationControlPoint output;
    UNITY_INITIALIZE_OUTPUT(CardGenerationTessellationControlPoint, output);

    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    output.uv = input.uv;

    output.worldPosition = mul(unity_ObjectToWorld, float4(input.position, 1.0));

    output.normal = normalize(input.normal);
    output.tangent.xyz = normalize(input.tangent.xyz);
    output.tangent.w = input.tangent.w;

    //if any bind pose is set, pass it to the tessellation shader 
#if defined(_BINDPOSEUVCHANNEL_UV2) || defined(_BINDPOSEUVCHANNEL_UV3) || defined(_BINDPOSEUVCHANNEL_UV4) || defined(_BINDPOSEUVCHANNEL_UV5) || defined(_BINDPOSEUVCHANNEL_UV6) || defined(_BINDPOSEUVCHANNEL_UV7) || defined(_BINDPOSEUVCHANNEL_UV8)
    output.bindPosition = input.bindPose.xyz;

    if (_SkinnedMeshScaleFixupEnabled)
    {
        output.skinnedMeshScale = max(0.0, abs(length(input.normal) / input.bindPose.w));
    }
    else
    {
        output.skinnedMeshScale = 1.0;
    }
#else
    //by default just use the actual vertex positions to generate the cards
    output.bindPosition = input.position;
    output.skinnedMeshScale = 1.0;
#endif

    return output;
}

[domain("tri")]
[partitioning("integer")]
[outputtopology("point")]
[patchconstantfunc("CardGenerationHullPatchConstantsShader")]
[outputcontrolpoints(3)]
CardGenerationTessellationControlPoint CardGenerationHullShader(InputPatch<CardGenerationTessellationControlPoint, 3> controlPoints, uint controlPointID : SV_OutputControlPointID)
{
    return controlPoints[controlPointID]; //passthrough
}

CardGenerationTessellationConstants CardGenerationHullPatchConstantsShader(InputPatch<CardGenerationTessellationControlPoint, 3> controlPoints, uint primitiveId : SV_PrimitiveID)
{
    CardGenerationTessellationConstants output;
    UNITY_INITIALIZE_OUTPUT(CardGenerationTessellationConstants, output);

    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(controlPoints[0]);

    //determine what kind of pass this is 
    bool isMainCameraPass = IsMainCameraPass();
#ifdef DEPTH_ONLY_PASS
    bool isShadowPass = !isMainCameraPass;
#else 
    bool isShadowPass = false;
#endif

    //get the minimum and maximum card size for this triangle from the optimization texture

    float2 mixMaxCardSize = GetMinMaxCardSizeForTriangle(controlPoints[0].uv, controlPoints[1].uv, controlPoints[2].uv);

    //get the distance from the main camera to the closest and furthest points on the triangle

    float3 distanceToTriangleVertices = float3(length(controlPoints[0].worldPosition - _WorldSpaceCameraPos),
                                               length(controlPoints[1].worldPosition - _WorldSpaceCameraPos),
                                               length(controlPoints[2].worldPosition - _WorldSpaceCameraPos));

    float minDistanceToTriangle = min(min(distanceToTriangleVertices.x, distanceToTriangleVertices.y), distanceToTriangleVertices.z);
    float maxDistanceToTriangle = max(max(distanceToTriangleVertices.x, distanceToTriangleVertices.y), distanceToTriangleVertices.z);

    //get the maximum ammount any card on this triangle can be scaled up by when being transformed to world space

    float maxTransformScale = GetMaxCardTransformScale();
    maxTransformScale *= max(max(controlPoints[0].skinnedMeshScale, controlPoints[1].skinnedMeshScale), controlPoints[2].skinnedMeshScale);

    //get the min and max spacing between cards for this triangle from both the card size and the LODing

    float minSpacingForTriangle = GetCardSpacing(mixMaxCardSize.x);
    float maxSpacingForTriangle = GetCardSpacing(mixMaxCardSize.y);

    float minLodSpacingForTriangle = GetLodSpacing(minDistanceToTriangle, maxTransformScale, isShadowPass);
    float maxLodSpacingForTriangle = GetLodSpacing(maxDistanceToTriangle, maxTransformScale, isShadowPass);

    //get the maximum distance a card can extend from the source triangle

    //shape is nonlinear so just get the max of the extremes
    float2 maxCardShape = max(GetCardShape(mixMaxCardSize.x), GetCardShape(mixMaxCardSize.y));
    float maxLodSpacingDelta = max(0.0, maxLodSpacingForTriangle - minSpacingForTriangle);

    float2 maxCardExtents = (maxCardShape * maxSpacingForTriangle) + (maxLodSpacingDelta * _CardLodGrowth);
    maxCardExtents.x *= 0.5; //the card is centered widthwise so it only extends half the width

    float maxCardDistanceFromTriangle = length(maxCardExtents) * maxTransformScale;

    //check for situations where we would not need to generate/render cards from this triangle

    bool triangleHasNoCards = (mixMaxCardSize.x - mixMaxCardSize.y) > 0.5; //for triangles that have no cards, min size = 1 and max size = 0

    bool isOffScreen = AreCardsFromSourceTriangleOffScreen(UnityWorldToClipPos(controlPoints[0].worldPosition),
                                                           UnityWorldToClipPos(controlPoints[1].worldPosition),
                                                           UnityWorldToClipPos(controlPoints[2].worldPosition),
                                                           maxCardDistanceFromTriangle);

    bool areAllCardsFadedOut = (minDistanceToTriangle - maxCardDistanceFromTriangle) > (_CardFadeStart + max(_CardFadeLength, 0.0));
    areAllCardsFadedOut = areAllCardsFadedOut && (_CardFadeStart >= 0); //if _CardFadeStart is < 0 then fading is disabled

    bool cullForMirror = isMainCameraPass && IsMirrored() && !_CardRenderInMirrors;

    //early return 0 for all tessellation factors to cull this triangle and generate no vertices

#ifdef DEPTH_ONLY_PASS
    //in depth only mode we always need to create at least 1 vertex to recreate the base triangle
    //so we can only cull this triangle completely if it is off screen
    if (isOffScreen)
    {
        return output;
    }
#else
    //cull this triangle if it is off screen or will render no cards
    if (isOffScreen || triangleHasNoCards || areAllCardsFadedOut || cullForMirror)
    {
        return output;
    }
#endif

    //get the maximum number of cards this triangle can create

    float actualMinSpacingForTriangle = max(minSpacingForTriangle, minLodSpacingForTriangle);
    float3 triangleArea = 0.5 * length(cross((controlPoints[1].bindPosition - controlPoints[0].bindPosition),
                                             (controlPoints[2].bindPosition - controlPoints[0].bindPosition)));
    uint idealCardCount = ceil(triangleArea / (actualMinSpacingForTriangle * actualMinSpacingForTriangle)); //round up

    //(this is only used in depth only passes) if this triangle does not have any visible cards we still
    //need to render one vertex to recreate create the base triangle
    //if a depth pass is not a main camera pass then it is a shadowcaster pass
    bool onlyRenderBaseTriangleInDepthPass = triangleHasNoCards
                                           || areAllCardsFadedOut
                                           || cullForMirror
                                           || (!isMainCameraPass && !_CardRenderInShadows);

    //get the tessellation factors to generate the maximum number of cards this triangle could need, and no more

    uint4 tessellationFactors = GetTessellationFactorsToGenerateSpecifiedVertexCount(idealCardCount, onlyRenderBaseTriangleInDepthPass);
    output.TessFactor[0] = tessellationFactors.x;
    output.TessFactor[1] = tessellationFactors.y;
    output.TessFactor[2] = tessellationFactors.z;
    output.InsideTessFactor = tessellationFactors.w;

    //pass the other per-triangle properties to the domain shader

    output.triangleArea = triangleArea;

    output.triangleHash = primitiveId;
    RandomNormalized(output.triangleHash);
    output.triangleHash += _RandomSeed;
    RandomNormalized(output.triangleHash);

    return output;
}

[domain("tri")]
void CardGenerationDomainShader(OutputPatch<CardGenerationTessellationControlPoint, 3> controlPoints,
                                CardGenerationTessellationConstants tessellationConstants,
                                float3 domainLocation : SV_DomainLocation,
                                uint primitiveId : SV_PrimitiveID,
                                out CardGenerationGeometryInput output)
{
    UNITY_INITIALIZE_OUTPUT(CardGenerationGeometryInput, output);

    UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(controlPoints[0], output);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(controlPoints[0]);

    uint cardIndex = GetTessellatedVertexOrdering(domainLocation, tessellationConstants.InsideTessFactor, uint3(tessellationConstants.TessFactor[0],
                                                                                                                tessellationConstants.TessFactor[1],
                                                                                                                tessellationConstants.TessFactor[2]));

    //for the depth only passes, we need to handle both the base mesh and the card generation in a single pass
#ifdef DEPTH_ONLY_PASS
    if (cardIndex == 0) //first vertex will be used to recreate the base triangle
    {
        cardIndex = cDepthPassBaseTriangleIndex; //set this to a special index so we can identify it in the geometry shader

        //store the shadow caster position in the world position, normal, and tangent outputs since they are unused for this triangle
        output.worldPosition = WorldSpaceShadowCasterPos(controlPoints[0].worldPosition, UnityObjectToWorldNormal(controlPoints[0].normal));
        output.normal        = WorldSpaceShadowCasterPos(controlPoints[1].worldPosition, UnityObjectToWorldNormal(controlPoints[1].normal));
        output.tangent.xyz   = WorldSpaceShadowCasterPos(controlPoints[2].worldPosition, UnityObjectToWorldNormal(controlPoints[2].normal));

        output.uv = controlPoints[0].uv;

        //pack the second vertex's uv into other unused values
        output.tangent.w = controlPoints[1].uv.x;
        output.skinnedMeshScale = controlPoints[1].uv.y;

        //pack the third vertex's uv into more unused values
        output.sourceTriangleArea = controlPoints[2].uv.x;
        output.sourceTriangleHash = controlPoints[2].uv.y;

        output.cardIndex = cardIndex;

        return; //return now so the output doesn't get overridden by the normal card generation path
    }
    else
    {
        cardIndex -= 1; //need to account for the fact that the first vertex is being used for the base triangle
    }
#endif

    //rather than normal barycentric interpolation, randomize the positions of the generated vertices on the source triangle

    float2 randomCoord = RobertsSequence2D(tessellationConstants.triangleHash + cardIndex); //low discrepancy random point on square
    randomCoord = (randomCoord.x + randomCoord.y) > 1.0 ? 1.0 - randomCoord.yx : randomCoord; //fold square distribution into triangle, preserves low discrepancy
    float3 barycentricCoords = float3(randomCoord, 1.0 - (randomCoord.x + randomCoord.y)); //evenly spaced low discrepancy distribution of points on triangle

    //interpolate the source triangle vertex values

    output.uv = (controlPoints[0].uv * barycentricCoords.x)
              + (controlPoints[1].uv * barycentricCoords.y)
              + (controlPoints[2].uv * barycentricCoords.z);

    output.worldPosition = (controlPoints[0].worldPosition * barycentricCoords.x)
                         + (controlPoints[1].worldPosition * barycentricCoords.y)
                         + (controlPoints[2].worldPosition * barycentricCoords.z);

    output.normal = (controlPoints[0].normal * barycentricCoords.x)
                  + (controlPoints[1].normal * barycentricCoords.y)
                  + (controlPoints[2].normal * barycentricCoords.z);

    output.tangent = (controlPoints[0].tangent * barycentricCoords.x)
                   + (controlPoints[1].tangent * barycentricCoords.y)
                   + (controlPoints[2].tangent * barycentricCoords.z);

    output.skinnedMeshScale = (controlPoints[0].skinnedMeshScale * barycentricCoords.x)
                            + (controlPoints[1].skinnedMeshScale * barycentricCoords.y)
                            + (controlPoints[2].skinnedMeshScale * barycentricCoords.z);

    //pass in the other card generation data

    output.cardIndex = cardIndex;
    output.sourceTriangleArea = tessellationConstants.triangleArea;
    output.sourceTriangleHash = asfloat(tessellationConstants.triangleHash);
}