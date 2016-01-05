//  This is based on Jeff LaMarche's GLProgram OpenGL shader wrapper class from his OpenGL ES 2.0 book.
//  A description of this can be found at his page on the topic:
//  http://iphonedevelopment.blogspot.com/2010/11/opengl-es-20-for-ios-chapter-4.html


#import "JotGLProgram.h"

#pragma mark Function Pointer Definitions
typedef void (*GLInfoFunction)(GLuint program, GLenum pname, GLint* params);
typedef void (*GLLogFunction) (GLuint program, GLsizei bufsize, GLsizei* length, GLchar* infolog);

#pragma mark -
#pragma mark Private Extension Method Declaration

@interface JotGLProgram()

- (BOOL)compileShader:(GLuint *)shader
                 type:(GLenum)type
               string:(NSString *)shaderString;
@end

#pragma mark -

@implementation GLProgram


- (id)initWithVertexShaderFilename:(NSString *)vShaderFilename
            fragmentShaderFilename:(NSString *)fShaderFilename
                    withAttributes:(NSArray<NSString*>*)attributes
                       andUniforms:(NSArray<NSString*>*)uniforms
{
    NSString *vertShaderPathname = [[NSBundle mainBundle] pathForResource:vShaderFilename ofType:@"vsh"];
    NSString *vShaderString = [NSString stringWithContentsOfFile:vertShaderPathname encoding:NSUTF8StringEncoding error:nil];

    NSString *fragShaderPathname = [[NSBundle mainBundle] pathForResource:fShaderFilename ofType:@"fsh"];
    NSString *fShaderString = [NSString stringWithContentsOfFile:fragShaderPathname encoding:NSUTF8StringEncoding error:nil];

    if ((self = [super init]))
    {
        _programId = glCreateProgram();

        if (![self compileShader:&_vertShader
                            type:GL_VERTEX_SHADER
                          string:vShaderString])
        {
            NSLog(@"Failed to compile vertex shader");
            return nil;
        }

        // Create and compile fragment shader
        if (![self compileShader:&_fragShader
                            type:GL_FRAGMENT_SHADER
                          string:fShaderString])
        {
            NSLog(@"Failed to compile fragment shader");
            return nil;
        }

        glAttachShader(_programId, _vertShader);
        glAttachShader(_programId, _fragShader);

        for (NSString* attr in attributes) {
            [self addAttribute:attr];
        }

        [_uniforms addObjectsFromArray:uniforms];

        if(![self link]){
            return nil;
        }

        [self validate];
    }

    return self;
}

#pragma mark - Step 1: Compile

- (BOOL)compileShader:(GLuint *)shader
                 type:(GLenum)type
               string:(NSString *)shaderString
{
    GLint status;
    const GLchar *source;

    source =
    (GLchar *)[shaderString UTF8String];
    if (!source)
    {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }

    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);

    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);

    if (status != GL_TRUE)
    {
        GLint logLength;
        glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0)
        {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(*shader, logLength, &logLength, log);
            if (shader == &_vertShader)
            {
                _vertexShaderLog = [NSString stringWithFormat:@"%s", log];
            }
            else
            {
                _fragmentShaderLog = [NSString stringWithFormat:@"%s", log];
            }

            free(log);
        }
    }

    return status == GL_TRUE;
}

#pragma mark - Attributes and Uniforms

- (GLuint)attributeIndex:(NSString *)attributeName
{
    return (GLuint)[_attributes indexOfObject:attributeName];
}

- (GLuint)uniformIndex:(NSString *)uniformName
{
    if([_uniforms containsObject:uniformName]){
        return glGetUniformLocation(_programId, [uniformName UTF8String]);
    }else{
        @throw [NSException exceptionWithName:@"GLProgramException" reason:[NSString stringWithFormat:@"Program does not contain a uniform named '%@'", uniformName] userInfo:nil];
    }
}

#pragma mark - Public

- (void)use
{
    glUseProgram(_programId);
}

#pragma mark - Private

- (BOOL)link
{
    GLint status;

    glLinkProgram(_programId);

    glGetProgramiv(_programId, GL_LINK_STATUS, &status);
    if (status == GL_FALSE)
        return NO;

    if (_vertShader)
    {
        glDeleteShader(_vertShader);
        _vertShader = 0;
    }
    if (_fragShader)
    {
        glDeleteShader(_fragShader);
        _fragShader = 0;
    }

    return YES;
}

- (void)validate;
{
    GLint logLength;

    glValidateProgram(_programId);
    glGetProgramiv(_programId, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(_programId, logLength, &logLength, log);
        _programLog = [NSString stringWithFormat:@"%s", log];
        free(log);
    }
}

- (void)addAttribute:(NSString *)attributeName
{
    if (![_attributes containsObject:attributeName])
    {
        [_attributes addObject:attributeName];
        glBindAttribLocation(_programId,
                             (GLuint)[_attributes indexOfObject:attributeName],
                             [attributeName UTF8String]);
    }
}

#pragma mark -

- (void)dealloc
{
    if (_vertShader){
        glDeleteShader(_vertShader);
    }

    if (_fragShader){
        glDeleteShader(_fragShader);
    }

    if (_programId){
        glDeleteProgram(_programId);
    }

}

@end