#include <GL/glew.h>
#include <GLFW/glfw3.h>

#include <iostream>
#include <sstream>
#include <string>
#include <fstream>
#include <vector>

#include "glm/glm.hpp"
#include "glm/gtx/string_cast.hpp"
#include "SOIL.h"

int current_key = 0;
int old_key = 0;
int global_width = 0;
int global_height = 0;

struct ShaderSource {
    std::string VertexSource;
    std::string FragmentSource;
};

// Allows the vertex and fragment shader to live in a single file
static ShaderSource parse_shader(const std::string& file_path) {
    std::ifstream stream(file_path);

    enum class ShaderType {
        NONE = -1, VERTEX = 0, FRAGMENT = 1
    };

    std::string line;
    std::stringstream ss[2];
    ShaderType type = ShaderType::NONE;
    while (getline(stream, line)) {
        if (line.find("#shader") != std::string::npos) {
            if (line.find("vertex") != std::string::npos) {
                type = ShaderType::VERTEX;
            }
            else if (line.find("fragment") != std::string::npos) {
                type = ShaderType::FRAGMENT;
            }
        }
        else {
            ss[(int)type] << line << '\n';
        }
    }
    return { ss[0].str(), ss[1].str() };
}

static unsigned int compile_shader(unsigned int type, const std::string& source) {
    unsigned int id = glCreateShader(type);
    const char* src = source.c_str();
    glShaderSource(id, 1, &src, nullptr);
    glCompileShader(id);

    // Error Handling (if shader has syntax errors)
    int result;
    glGetShaderiv(id, GL_COMPILE_STATUS, &result);
    if (result == GL_FALSE) {
        int length;
        glGetShaderiv(id, GL_INFO_LOG_LENGTH, &length);
        char* message = (char*)_malloca(length * sizeof(char));
        glGetShaderInfoLog(id, length, &length, message);
        std::cout << "===== Failed to compile =====" << std::endl;
        std::cout << message << std::endl;
        glDeleteShader(id);
        return 0;
    }

    return id;
}

static unsigned int create_shader(const std::string& vertex_shader, const std::string& fragment_shader) {
    unsigned int program = glCreateProgram();
    unsigned int vs = compile_shader(GL_VERTEX_SHADER, vertex_shader);
    unsigned int fs = compile_shader(GL_FRAGMENT_SHADER, fragment_shader);

    glAttachShader(program, vs);
    glAttachShader(program, fs);
    glBindFragDataLocation(program, 0, "outColor");
    glLinkProgram(program);         // TODO: detach shader after linking?
    glValidateProgram(program);

    glDeleteShader(vs);
    glDeleteShader(fs);

    return program;
}

void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods)
{
    if (key == GLFW_KEY_1 && action == GLFW_PRESS) {
        old_key = current_key;
        current_key = 1;
    }
    else if (key == GLFW_KEY_2 && action == GLFW_PRESS) {
        old_key = current_key;
        current_key = 2;
    }
    else if (key == GLFW_KEY_3 && action == GLFW_PRESS) {
        old_key = current_key;
        current_key = 3;
    }
    else if (key == GLFW_KEY_4 && action == GLFW_PRESS) {
        old_key = current_key;
        current_key = 4;
    }
    else if (key == GLFW_KEY_5 && action == GLFW_PRESS) {
        old_key = current_key;
        current_key = 5;
    }
    else if (key == GLFW_KEY_6 && action == GLFW_PRESS) {
        old_key = current_key;
        current_key = 6;
    }
    else if (key == GLFW_KEY_J && action == GLFW_PRESS) {
        std::vector< unsigned char > buf(global_width * global_height * 3);
        glPixelStorei(GL_PACK_ALIGNMENT, 1);
        glReadPixels(0, 0, global_width, global_height, GL_RGB, GL_UNSIGNED_BYTE, &buf[0]);
        std::vector< unsigned char > flip_buf(global_width * global_height * 3);

        for (int i = 0; i < global_width; ++i) {
            for (int j = 0; j < global_height; ++j) {
                for (int k = 0; k < 3; ++k) {
                    flip_buf[(i + j * global_width) * 3 + k] 
                        = buf[(i + (global_height - 1 - j) * global_width) * 3 + k];


                }
            }
        }
        
        int err = SOIL_save_image("images/out.bmp", SOIL_SAVE_TYPE_BMP, global_width, 
            global_height, 3, &flip_buf[0]);
    }
}

int main(void)
{
    GLFWwindow* window;

    /* Initialize the library */
    if (!glfwInit())
        return -1;

    /* Load image and set width and height */
    int width, height, channels;
    unsigned char* image =
        SOIL_load_image("images/tiger.jpg", &width, &height, &channels, SOIL_LOAD_RGB);
    std::cout << "width: " << width << ", height: " << height << std::endl;

    global_width = width;
    global_height = height;

    /* Create a windowed mode window and its OpenGL context */
    window = glfwCreateWindow(width, height, "Original Image", NULL, NULL);
    if (!window)
    {
        glfwTerminate();
        return -1;
    }

    /* Make the window's context current */
    glfwMakeContextCurrent(window);

    if (glewInit() != GLEW_OK) {
        std::cout << "glewInit failed" << std::endl;
    }

    // Create Vertex Array Object
    GLuint vao;
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);

    // Create a Vertex Buffer Object and copy the vertex data to it
    GLuint vbo;
    glGenBuffers(1, &vbo);

    GLfloat vertices[] = {
        //  Position      Color             Texcoords
            -1.0f,  1.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f, // Top-left
             1.0f,  1.0f, 0.0f, 1.0f, 0.0f, 1.0f, 0.0f, // Top-right
             1.0f, -1.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, // Bottom-right
            -1.0f, -1.0f, 1.0f, 1.0f, 1.0f, 0.0f, 1.0f  // Bottom-left
    };

    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    // Create an element array
    GLuint ebo;
    glGenBuffers(1, &ebo);

    GLuint elements[] = {
        0, 1, 2,
        2, 3, 0
    };

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(elements), elements, GL_STATIC_DRAW);

    //glEnableVertexAttribArray(0);
    //glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 2, 0);

    ShaderSource source = parse_shader("src/shaders/basic.shader");
    unsigned int shader = create_shader(source.VertexSource, source.FragmentSource);

    GLint posAttrib = glGetAttribLocation(shader, "position");
    glEnableVertexAttribArray(posAttrib);
    glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE, 7 * sizeof(GLfloat), 0);

    GLint colAttrib = glGetAttribLocation(shader, "color");
    glEnableVertexAttribArray(colAttrib);
    glVertexAttribPointer(colAttrib, 3, GL_FLOAT, GL_FALSE, 7 * sizeof(GLfloat), (void*)(2 * sizeof(GLfloat)));

    GLint texAttrib = glGetAttribLocation(shader, "texcoord");
    glEnableVertexAttribArray(texAttrib);
    glVertexAttribPointer(texAttrib, 2, GL_FLOAT, GL_FALSE, 7 * sizeof(GLfloat), (void*)(5 * sizeof(GLfloat)));

    glUseProgram(shader);
    GLint loc = glGetUniformLocation(shader, "height");
    glUniform1f(loc, height);

    GLint loc2 = glGetUniformLocation(shader, "type");
    glUniform1f(loc2, current_key);

    GLint loc3 = glGetUniformLocation(shader, "width");
    glUniform1f(loc3, width);
    //texture

    GLuint tex;
    glGenTextures(1, &tex);
    glBindTexture(GL_TEXTURE_2D, tex);
    
    if (0 == image)
    {
        printf("SOIL loading error: '%s'\n", SOIL_last_result());
    }
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, image);
    glGenerateMipmap(GL_TEXTURE_2D);
    SOIL_free_image_data(image);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glfwSetKeyCallback(window, key_callback);

    bool inc = true;

    /* Loop until the user closes the window */
    while (!glfwWindowShouldClose(window))
    {
        /* Render here */
        glClear(GL_COLOR_BUFFER_BIT);

        if (current_key != old_key) {
            glUniform1f(loc2, current_key);
            switch (current_key) {
                case 1 :
                    glfwSetWindowTitle(window, "Bilateral Blur Filter");
                    break;
                case 2:
                    glfwSetWindowTitle(window, "Sobel Edge Filter");
                    break;
                case 3:
                    glfwSetWindowTitle(window, "Edge Tangent Flow Filter");
                    break;
                case 4:
                    glfwSetWindowTitle(window, "BB Filter + SE Filter + ETF Filter");
                    break;
                case 5:
                    glfwSetWindowTitle(window, "Acrylic Painting Generation");
                    break;
                default:
                    glfwSetWindowTitle(window, "Original Image");
                    break;
            }
            old_key = current_key;
        }

        //glDrawArrays(GL_TRIANGLES, 0, 3);
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

        /* Swap front and back buffers */
        glfwSwapBuffers(window);

        /* Poll for and process events */
        glfwPollEvents();
    }
    glDeleteTextures(1, &tex);
    glDeleteBuffers(1, &ebo);
    glDeleteBuffers(1, &vbo);

    glDeleteVertexArrays(1, &vao);
    glDeleteProgram(shader);

    glfwTerminate();
    return 0;
}