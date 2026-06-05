#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 mouse;
    float time;
    vec4 themeColor;
    float aspect;
    float shaderSpeed;
    float meteorFrequency;
};

// Pseudo-random coordinate generator
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void main() {
    vec2 uv = qt_TexCoord0;
    
    // Deep dark space ambient background
    vec3 finalColor = vec3(0.005, 0.005, 0.01);
    
    // 1. Render tiny, crisp, drifting background stars (particles)
    float stars = 0.0;
    for (float i = 0.0; i < 25.0; i++) {
        float r = hash(vec2(i, 1.15));
        float r2 = hash(vec2(i, 2.73));
        float r3 = hash(vec2(i, 4.31));
        float r4 = hash(vec2(i, 5.89));
        
        // Stars fly slowly from right to left, top to bottom (diagonal drift scaled by shaderSpeed)
        vec2 vel = (vec2(-1.0, -0.66) + vec2(r - 0.5, r2 - 0.5) * 0.53) * shaderSpeed;
        vec2 start_pos = vec2(r3, r4);
        vec2 pos = fract(start_pos + vel * time);
        
        // Add subtle organic waving
        pos.x += sin(time * 0.25 + r * 6.28) * 0.015;
        pos.y += cos(time * 0.2 + r2 * 6.28) * 0.015;
        pos = fract(pos);
        
        // Aspect ratio correction for circular particles
        vec2 aspect_uv = vec2(uv.x * aspect, uv.y);
        vec2 aspect_pos = vec2(pos.x * aspect, pos.y);
        float d = distance(aspect_uv, aspect_pos);
        
        // Microscopic, extremely sharp circular particles
        float size = 0.0012 + 0.001 * r; 
        float star = smoothstep(size, size * 0.5, d);
        
        // Slow pulsation / twinkling
        float twinkle = 0.4 + 0.6 * sin(time * (1.2 + r2 * 2.5) + r * 6.28);
        
        stars += star * twinkle * (0.3 + 0.7 * r);
    }
    
    // Crisp white cores with subtle theme tinting
    finalColor += mix(vec3(1.0), themeColor.rgb, 0.2) * stars;
    
    // 2. Render small, needle-thin shooting stars (meteors) that appear occasionally
    float meteors = 0.0;
    for (float m = 0.0; m < 2.0; m++) {
        float period = 4.0; // Cycle duration (4 seconds)
        float streak_duration = 0.6; // Shooting star active streak duration
        float streak_time = time + hash(vec2(m, 17.51)) * 150.0;
        float cycle = fract(streak_time / period);
        float cycle_id = floor(streak_time / period);
        
        // Spawn a shooting star dynamically based on the meteorFrequency setting
        float spawn_chance = hash(vec2(cycle_id, m * 9.37));
        if (cycle < (streak_duration / period) && spawn_chance < meteorFrequency) {
            float cycle_progress = cycle / (streak_duration / period);
            
            // Random diagonal trajectories starting from top/right drifting left/down
            float startX = 0.3 + 0.8 * hash(vec2(cycle_id, 12.31));
            float startY = -0.1;
            
            float endX = startX - 0.4 - 0.2 * hash(vec2(cycle_id, 45.62));
            float endY = 1.1;
            
            vec2 headPos = mix(vec2(startX, startY), vec2(endX, endY), cycle_progress);
            
            // Aspect ratio corrected calculations for the trail drawing
            vec2 aspect_uv = vec2(uv.x * aspect, uv.y);
            vec2 aspect_start = vec2(startX * aspect, startY);
            vec2 aspect_head = vec2(headPos.x * aspect, headPos.y);
            
            vec2 pathDir = aspect_head - aspect_start;
            float pathLen = length(pathDir);
            vec2 pathDirN = pathLen > 0.0 ? pathDir / pathLen : vec2(0.0);
            
            float proj = dot(aspect_uv - aspect_start, pathDirN);
            proj = clamp(proj, 0.0, pathLen);
            vec2 closest = aspect_start + pathDirN * proj;
            
            float distToPath = distance(aspect_uv, closest);
            float distBehindHead = distance(closest, aspect_head);
            
            // Needle-thin, sharp trail line with rapid tail decay
            float trailThickness = 0.0012;
            float trail = exp(-distBehindHead * 14.0) * smoothstep(trailThickness, 0.0, distToPath);
            
            // Tiny crisp circular spark at the front head
            float spark = smoothstep(trailThickness, 0.0, distance(aspect_uv, aspect_head)) * 0.7;
            
            meteors += (trail * 0.35 + spark) * (0.3 + 0.7 * hash(vec2(cycle_id, 5.69)));
        }
    }
    
    // Add meteors (white core with subtle accent glow)
    vec3 meteorColor = mix(themeColor.rgb, vec3(1.0), 0.4 + 0.6 * exp(-uv.y * 0.4));
    finalColor += meteorColor * meteors;
    
    // 3. Interactive mouse aura glow (subtle nebula glow)
    vec2 aspect_uv = vec2(uv.x * aspect, uv.y);
    vec2 aspect_mouse = vec2(mouse.x * aspect, mouse.y);
    float distToMouse = distance(aspect_uv, aspect_mouse);
    float mouseGlow = exp(-distToMouse * 6.0);
    vec3 nebula = themeColor.rgb * mouseGlow * 0.07;
    
    finalColor += nebula;
    
    // Soft dark vignette borders
    float vignette = uv.x * (1.0 - uv.x) * uv.y * (1.0 - uv.y) * 16.0;
    vignette = pow(vignette, 0.25);
    
    fragColor = vec4(finalColor * vignette * qt_Opacity, qt_Opacity);
}
