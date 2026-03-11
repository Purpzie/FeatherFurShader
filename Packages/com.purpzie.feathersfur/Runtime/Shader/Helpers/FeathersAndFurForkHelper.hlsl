#ifdef _LIGHT_VOLUMES_ON
#include "Packages/red.sim.lightvolumes/Shaders/LightVolumes.cginc"
#endif

#ifdef _PURPZIE_GRYPHON_AUDIOLINK_ON
#include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"
float _PurpzieGryphonAudiolinkStrength;
UNITY_DECLARE_TEX2D(_PurpzieGryphonAudiolinkTexture);
float3 PurpzieGryphonAudiolinkEmission(float2 uv, float3 albedo) {
	if (AudioLinkIsAvailable()) {
		float3 emission = 0;
		float3 map = UNITY_SAMPLE_TEX2D(_PurpzieGryphonAudiolinkTexture, uv);
		emission += map.r * AudioLinkData(ALPASS_AUDIOLINK + uint2(0, 2)).r * AudioLinkData(ALPASS_THEME_COLOR0);
		emission += map.g * AudioLinkData(ALPASS_AUDIOLINK + uint2(0, 0)).r * AudioLinkData(ALPASS_THEME_COLOR1);
		emission += map.b * AudioLinkData(ALPASS_AUDIOLINK + uint2(0, 3)).r * AudioLinkData(ALPASS_THEME_COLOR2);
		return emission * 6 * albedo * _PurpzieGryphonAudiolinkStrength;
	}
	return 0;
}
#endif
