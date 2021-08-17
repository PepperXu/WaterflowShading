Shader "Peisen/WaterFlow"
{
    Properties
    {
        _BaseColor ("Color Tint", Color) = (1, 1, 1, 0.5)
        _MainTex ("Base Texture", 2D) = "White" {}
        
        //Reflection
        _ReflectionNoiseTex ("Reflection Noise", 2D) = "White" {}
        _ReflectionNoiseOpacity ("Reflection Noise Opacity", Float) = 0.5
        _HighlightOpacity ("Highlight Opacity", Float) = 0.7
        _HighlightThreshold ("Highlight Threshold", Float) = 0.8
        
        //Cel-shading
        _NoiseMin ("Noise Min", Float) = 0
        _NoiseMax ("Noise Max", Float) = 1

        //Movement

        _DistortAmount ("Distort Amount", Float) = 0.1
        _ScrollSpeed("Scroll Speed", Vector) = (0.1, 0.1, 0, 0)
        _MovementNoiseTex("Movement Noise", 2D) = "White" {}
        _WaveSpeed("Wave Speed", Float) = 1
        _WaveHeight("Wave Height", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float2 uv_reflection : TEXCOORD1;
                float2 uv_movement : TEXCOORD2;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 uv_reflection : TEXCOORD1;
                float3 normal_dynamic : TEXTCOORD2;
                float3 normal_static : TEXTCOORD3;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            
            sampler2D _ReflectionNoiseTex;
            float4 _ReflectionNoiseTex_ST;

            sampler2D _MovementNoiseTex;
            float4 _MovementNoiseTex_ST;
            float2 _MovementNoiseTex_TexelSize;

            float4 _BaseColor;
            
            float _ReflectionNoiseOpacity;
            float _HighlightOpacity;
            float _HighlightThreshold;
            float _NoiseMin;
            float _NoiseMax;

            float4 _ScrollSpeed;
            float _DistortAmount;
            float _WaveSpeed;
            float _WaveHeight;

            v2f vert (appdata v)
            {
                v2f o;

                //calculate vertex movement
                float2 movement_noise_uv = float2(v.uv_movement.x + _Time.y * _WaveSpeed, v.uv_movement.y + _Time.y * _WaveSpeed);
                float wave_distortion = tex2Dlod(_MovementNoiseTex, float4(movement_noise_uv.xy, 0, 0)).r;
                float sampleX = tex2Dlod(_MovementNoiseTex, float4(movement_noise_uv.x + _MovementNoiseTex_TexelSize.x * 5, movement_noise_uv.y, 0, 0)).r;
                float sampleY = tex2Dlod(_MovementNoiseTex, float4(movement_noise_uv.x, movement_noise_uv.y + _MovementNoiseTex_TexelSize.y * 5, 0, 0)).r;
                float4 vertex_pos = v.vertex + float4(v.normal * wave_distortion * _WaveHeight, 0);
                
                //calculate vertex normal for lighting
                o.normal_dynamic = normalize(v.normal + float3(sampleX - wave_distortion, 0, sampleY - wave_distortion) * 5);
                o.normal_static = v.normal;

                //transform vertex and uv to clip space
                o.vertex = UnityObjectToClipPos(vertex_pos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv_reflection = TRANSFORM_TEX(v.uv_reflection, _ReflectionNoiseTex);

                UNITY_TRANSFER_FOG(o,o.vertex);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 main_tex_col = tex2D(_MainTex, i.uv);

                // calculate the uv; parallel movement of double uv; distortion 
                fixed4 distortion = (tex2D(_ReflectionNoiseTex, i.uv_reflection) - 0.5) * 0.01 * _DistortAmount;
                float2 reflective_uv = float2(i.uv_reflection.x + _Time.y * (_ScrollSpeed.x + distortion.x), i.uv_reflection.y + _Time.y * (_ScrollSpeed.y+ distortion.y));
                float2 hl_uv = float2(i.uv_reflection.x + _Time.z * (_ScrollSpeed.x + distortion.x), i.uv_reflection.y + _Time.z * (_ScrollSpeed.y+ distortion.y));

                // sample the texture
                float reflective = tex2D(_ReflectionNoiseTex, reflective_uv).r;
                float highlight = tex2D(_ReflectionNoiseTex, hl_uv).r;

                // simulate lighting
                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                float light_static = smoothstep(0, 1, dot(lightDirection, normalize(i.normal_static)));
                float light_dynamic = smoothstep(0, 1, dot(lightDirection, normalize(i.normal_dynamic)));

                // final color

                float4 final_base_color = main_tex_col * ( _BaseColor + (light_static - 0.5) / 1.5 );
                float final_reflective_col = _ReflectionNoiseOpacity * light_dynamic * reflective;

                //final highlight is the overlap of highlight texture and reflective texture
                float final_highlight_col = _HighlightOpacity * light_dynamic * step(_HighlightThreshold, highlight) * step(_HighlightThreshold, reflective);

                //natural mapping for the noise overlay; also make the cartoon effect possible
                float natural_noise = smoothstep(_NoiseMin, _NoiseMax, final_reflective_col + final_highlight_col) * light_static;
                float4 final_col = final_base_color + natural_noise;

                // apply fog 
                UNITY_APPLY_FOG(i.fogCoord, final_col);
                
                return final_col;
            }
            ENDCG
        }
    }
}
