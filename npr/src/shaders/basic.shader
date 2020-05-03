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

in vec3 Color;
in vec2 Texcoord;
out vec4 outColor;
uniform sampler2D tex;

void main() {
    outColor = vec4(texture(tex, Texcoord).r);
    //outColor = texture(tex, Texcoord) * vec4(Color, 1.0);
};
