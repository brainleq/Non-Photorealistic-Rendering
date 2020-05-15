#shader vertex
#version 330 core

// .vert and .frag are combined here rather than separating them like we do in class
// location is first index of glVertexAttribArray
in vec2 position;
in vec3 color;
in vec2 texcoord;
out vec3 Color;
out vec2 Texcoord;
void main() {
    Color = color;
    Texcoord = texcoord;
    gl_Position = vec4(position, 0.0, 1.0);
};


#shader fragment
#version 330 core

//in vec3 Color;
in vec2 Texcoord;
in vec3 Color;
out vec4 outColor;
uniform sampler2D tex;
uniform float height;
uniform float type;
uniform float width;
uniform float daze;

void main()
{
    mat3 sx = mat3(
        1.0, 2.0, 1.0,
        0.0, 0.0, 0.0,
        -1.0, -2.0, -1.0
    );
    mat3 sy = mat3(
        1.0, 0.0, -1.0,
        2.0, 0.0, -2.0,
        1.0, 0.0, -1.0
    );
    //vec3 diffuse = vec3(texture(tex, Texcoord.xy));
    vec3 diffuse = texelFetch(tex, ivec2(gl_FragCoord.x, height - gl_FragCoord.y), 0).xyz;
    const int big_kernel = 4;
    const int kernel = big_kernel / 2;
    vec3 flow_field[big_kernel * big_kernel];
    float gradients[big_kernel * big_kernel];
    int i = 0;
    vec3 orig_g;
    for (int r = -kernel; r < kernel; ++r) {
        for (int c = -kernel; c < kernel; ++c) {
            mat3 I;
            for (int i = 0; i < 3; i++) {
                for (int j = 0; j < 3; j++) {
                    vec3 sample = vec3(texelFetch(tex, ivec2(gl_FragCoord.x, height - gl_FragCoord.y) + ivec2(i + r - 1, j + c - 1), 0).rgb);
                    I[i][j] = length(sample);
                }
            }
            // compute gradient
            float gx = dot(sx[0], I[0]) + dot(sx[1], I[1]) + dot(sx[2], I[2]);
            float gy = dot(sy[0], I[0]) + dot(sy[1], I[1]) + dot(sy[2], I[2]);
            float g = sqrt(pow(gx, 2.0) + pow(gy, 2.0));
            if (r == 0 && c == 0)
                orig_g = vec3(g);
            vec3 flow = normalize(vec3(gy, gx, 0.0001));

            // rotate flow
            float theta = 90.0 / 180.0 * 3.1415926536;
            float r_gx = flow[0] * cos(theta) - flow[1] * sin(theta);
            float r_gy = flow[1] * cos(theta) + flow[0] * sin(theta);
            flow = vec3(r_gx, r_gy, 0.0);

            flow_field[i] = flow;
            gradients[i] = g;
            ++i;
        }
    }

    // compute t_new
    vec3 t_new = vec3(0.0, 0.0, 0.0);
    vec3 cur_x = flow_field[big_kernel * big_kernel / 2 - 1];
    for (int r = -kernel; r < kernel; ++r) {
        for (int c = -kernel; c < kernel; ++c) {
            vec3 cur_y = flow_field[((r + kernel) * big_kernel) + c + kernel];
            float phi = dot(cur_x, cur_y) > 0.0 ? 1.0 : -1.0;
            vec2 a = vec2(gl_FragCoord.x, height - gl_FragCoord.y);
            vec2 b = vec2(gl_FragCoord.x + c, height - gl_FragCoord.y + r);
            float w_s = distance(a, b) < kernel ? 1.0 : 0.0;
            float g1 = gradients[big_kernel * big_kernel / 2 - 1];
            float g2 = gradients[((r + kernel) * big_kernel) + c + kernel];
            float w_m = (1 + tanh(g2 - g1)) / 2;
            float w_d = abs(dot(cur_x, cur_y));

            t_new += phi * cur_y * w_s * w_m * w_d;
        }
    }
    t_new = normalize(t_new);

    float g = sqrt(pow(flow_field[big_kernel * big_kernel / 2 - 1].x, 2.0) + pow(flow_field[big_kernel * big_kernel / 2 - 1].y, 2.0));
    g = smoothstep(.7, 1.0, g);
    vec3 edgeColor = vec3(0, 0, 0);

    if (type == 1) {
        // Bilateral Blur

        vec2 ctr = vec2(gl_FragCoord.x / width, ((height - gl_FragCoord.y) / height));
        vec2 off = vec2((2.0 / width) * 2 / 3, (2.0 / height) * 2 / 3);
        // Access in direction A
        vec4 retTex = vec4(ctr.x - off.x, ctr.y + off.y, 1.0, 1.0);
        vec4 A = texture2D(tex, retTex.xy);
        // Access in direction C
        retTex = vec4(ctr.x + off.x, ctr.y + off.y, 1.0, 1.0);
        vec4 B = texture2D(tex, retTex.xy);

        retTex = vec4(ctr.x + off.x, ctr.y - off.y, 1.0, 1.0);
        vec4 C = texture2D(tex, retTex.xy);
        // Access in direction H
        retTex = vec4(ctr.x + off.x, ctr.y - off.y, 1.0, 1.0);
        vec4 D = texture2D(tex, retTex.xy);
        // Output blurred destination image pixels
        outColor = vec4(0.25 * (A + B + C + D));
    }
    else if (type == 2) {
        // Sobel Operator Edge Detection

        outColor = vec4(vec3(orig_g), 1.0);
    }
    else if (type == 3) {
        // Edge Tangent Flow

        float m = max(max(t_new.x, t_new.y), t_new.z);
        outColor = vec4(vec3(m), 1.0);
    }
    else if (type == 4) {
        // ETF + Bilateral Blur

        vec2 ctr = vec2(gl_FragCoord.x / width, ((height - gl_FragCoord.y) / height));
        vec2 off = vec2((2.0 / width) * 2 / 3, (2.0 / height) * 2 / 3);
        // Access in direction A
        vec4 retTex = vec4(ctr.x - off.x, ctr.y + off.y, 1.0, 1.0);
        vec4 A = texture2D(tex, retTex.xy);
        // Access in direction C
        retTex = vec4(ctr.x + off.x, ctr.y + off.y, 1.0, 1.0);
        vec4 B = texture2D(tex, retTex.xy);

        retTex = vec4(ctr.x + off.x, ctr.y - off.y, 1.0, 1.0);
        vec4 C = texture2D(tex, retTex.xy);
        // Access in direction H
        retTex = vec4(ctr.x + off.x, ctr.y - off.y, 1.0, 1.0);
        vec4 D = texture2D(tex, retTex.xy);

        float m = max(max(t_new.x, t_new.y), t_new.z);
        outColor = vec4(vec3(m), 1.0);

        // Output blurred destination image pixels
        outColor = vec4(vec3(m), 1.0) * (A + B + C + D);
    }
    else if (type == 5) {
        // ETF Water Color

        float m = max(max(t_new.x, t_new.y), t_new.z);
        if (m == 0.0)
            outColor = vec4(diffuse, 1.0);
        else {
            vec3 total = vec3(0.0, 0.0, 0.0);
            for (int r = -kernel; r < kernel; ++r) {
                for (int c = -kernel; c < kernel; ++c) {
                    vec3 sample = vec3(texelFetch(tex, ivec2(gl_FragCoord.x, height - gl_FragCoord.y) + ivec2(r,
                        c), 0).rgb);
                    if (!isnan(sample.x) && !isnan(sample.y) && !isnan(sample.z))
                        total += sample;
                }
            }

            outColor = normalize(vec4(total, 1.0));
        }
    }
    else {
        // Original Image

        outColor = vec4(diffuse, 1.0);
    }
};

