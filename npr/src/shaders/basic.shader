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
    mat3 I;
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            vec3 sample = vec3(texelFetch(tex, ivec2(gl_FragCoord.x, height - gl_FragCoord.y) + ivec2(i - 1, j - 1), 0).rgb);
            I[i][j] = length(sample);
        }
    }

    float gx = dot(sx[0], I[0]) + dot(sx[1], I[1]) + dot(sx[2], I[2]);
    float gy = dot(sy[0], I[0]) + dot(sy[1], I[1]) + dot(sy[2], I[2]);

    float g = sqrt(pow(gx, 2.0) + pow(gy, 2.0));
    g = smoothstep(0.1, 1.0, g);

    if (type == 0) {
        outColor = vec4(diffuse, 1.0);
    }
    else if (type == 1) {
        outColor = vec4(vec3(g), 1.0);
    }
    else if (type == 2) {
        outColor = texture(tex, Texcoord) * vec4(Color, 1.0);
    }
    else if (type == 3) {
        vec2 ctr = vec2(gl_FragCoord.x / width, ((height - gl_FragCoord.y) / height));
        vec2 off = vec2((1.0 / width) * 2 / 3, (1.0 / height) * 2 / 3);
        // Access in direction A
        vec4 retTex = vec4(diffuse, 1.0) * vec4(ctr.x - off.x, ctr.y + off.y, 1.0, 1.0);
        vec4 A = texture2D(tex, retTex.xy);
        // Access in direction C
        retTex = vec4(diffuse, 1.0) * vec4(ctr.x + off.x, ctr.y + off.y, 1.0, 1.0);
        vec4 B = texture2D(tex, retTex.xy);

        retTex = vec4(diffuse, 1.0) * vec4(ctr.x + off.x, ctr.y - off.y, 1.0, 1.0);
        vec4 C = texture2D(tex, retTex.xy);
        // Access in direction H
        retTex = vec4(diffuse, 1.0) * vec4(ctr.x + off.x, ctr.y - off.y, 1.0, 1.0);
        vec4 D = texture2D(tex, retTex.xy);
        // Output blurred destination image pixels
        outColor = vec4(0.25 * (A + B + C + D));
    }
    // default
    else {
        outColor = vec4(diffuse, 1.0);
    }
};