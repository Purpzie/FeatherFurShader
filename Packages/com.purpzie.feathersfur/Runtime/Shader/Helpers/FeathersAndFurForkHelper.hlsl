#pragma once

#ifdef _LIGHT_VOLUMES_ON
#include "Packages/red.sim.lightvolumes/Shaders/LightVolumes.cginc"
#endif

#ifdef _PURPZIE_GRYPHON_AUDIOLINK_ON
#include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"
float _PurpzieGryphonAudiolinkStrength;
UNITY_DECLARE_TEX2D_NOSAMPLER(_PurpzieGryphonAudiolinkTexture);
float3 PurpzieGryphonAudiolinkEmission(float2 uv, float3 albedo) {
	if (AudioLinkIsAvailable()) {
		float3 emission = 0;
		#ifdef UNDERCOAT_PASS
		float3 map = UNITY_SAMPLE_TEX2D_SAMPLER(_PurpzieGryphonAudiolinkTexture, _UndercoatAlbedoTexture, uv);
		#elif defined(COAT_PASS)
		float3 map = UNITY_SAMPLE_TEX2D_SAMPLER(_PurpzieGryphonAudiolinkTexture, _CoatAlbedoTexture, uv);
		#endif
		emission += map.r * AudioLinkData(ALPASS_AUDIOLINK + uint2(0, 2)).r * AudioLinkData(ALPASS_THEME_COLOR0);
		emission += map.g * AudioLinkData(ALPASS_AUDIOLINK + uint2(0, 0)).r * AudioLinkData(ALPASS_THEME_COLOR1);
		emission += map.b * AudioLinkData(ALPASS_AUDIOLINK + uint2(0, 3)).r * AudioLinkData(ALPASS_THEME_COLOR2);
		return emission * 3 * albedo * _PurpzieGryphonAudiolinkStrength;
	}
	return 0;
}
#endif

// Reuse these variables across the different shading types for optimization
float3 CacheLightDirection = 0;
float3 CacheLightColor = 0;
float3 CacheSpecLightColor = 0;
float3 CacheLightProbeInfluence = 0;

void ForkInit(float3 worldPos) {
	#if defined(BASE_LIGHTING_PASS) && defined(_LIGHT_VOLUMES_ON)
	// replace probes with volumes (which falls back to probes if not present)
	float3 L0, L1r, L1g, L1b;
	LightVolumeSH(worldPos, L0, L1r, L1g, L1b);
	unity_SHAr = float4(L1r, L0.r);
	unity_SHAg = float4(L1g, L0.g);
	unity_SHAb = float4(L1b, L0.b);
	unity_SHBr = 0;
	unity_SHBg = 0;
	unity_SHBb = 0;
	unity_SHC = 0;
	#endif

	CacheLightDirection = Unity_SafeNormalize(UnityWorldSpaceLightDir(worldPos));
	#ifdef BASE_LIGHTING_PASS
		// fake specular from probes
		float3 ambientDir = 0.22 * unity_SHAr.xyz + 0.707 * unity_SHAg.xyz + 0.071 * unity_SHAb.xyz;
		float directLightLuminance = Luminance(_LightColor0.rgb);
		CacheLightProbeInfluence = saturate((0.1 - directLightLuminance) * 10);
		CacheLightDirection = Unity_SafeNormalize(
			CacheLightDirection * directLightLuminance
			+ ambientDir * CacheLightProbeInfluence
		);
	#endif
}

void ForkInitNormal(float3 normal, float3 viewDir, float3 lightColor, inout float roughness) {
	// specular antialiasing
	float dx = ddx(normal);
	float dy = ddy(normal);
	float roughnessFactor = pow(saturate(max(dot(dx, dx), dot(dy, dy))), 0.333);
	roughness = max(roughness, roughnessFactor);

	CacheSpecLightColor = lightColor;
	#ifdef BASE_LIGHTING_PASS
	#ifdef _LIGHT_VOLUMES_ON
	float3 ambientReflections = LightVolumeEvaluate(
		reflect(-viewDir, normal),
		float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w),
		unity_SHAr.xyz,
		unity_SHAg.xyz,
		unity_SHAb.xyz
	);
	#else
	float3 ambientReflections = ShadeSH9(float4(reflect(-viewDir, normal), 1));
	#endif
	CacheSpecLightColor += ambientReflections * CacheLightProbeInfluence;
	#endif
}
