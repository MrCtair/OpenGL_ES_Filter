//
//  ShaderTool.m
//  FilterOfSplitScreen
//
//  Created by trs on 2020/8/11.
//  Copyright © 2020 China. All rights reserved.
//

#import "ShaderTool.h"
#import <OpenGLES/ES2/gl.h>

@implementation ShaderTool

+ (GLuint)programWithShaderName:(NSString *)shaderName {
    // 编译顶点着色器，片元着色器
    GLuint vertexShader = [self compileShaderWithName:shaderName type:GL_VERTEX_SHADER];
    GLuint fragShader = [self compileShaderWithName:shaderName type:GL_FRAGMENT_SHADER];
    
    //将顶点/偏远附着到program
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragShader);
    
    //Link
    glLinkProgram(program);
    
    //检查是否link成功
    GLint linkSuccess;
    glGetProgramiv(program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(program, sizeof(messages), 0, &messages[0]);
        NSString *messageStr = [NSString stringWithUTF8String:messages];
        NSAssert(NO, @"program链接失败：%@", messageStr);
        exit(1);
    }
    
    return program;
}

//编译shader代码
+ (GLuint)compileShaderWithName:(NSString *)name type:(GLenum)shaderType {
    // 获取shader路径
    NSString * shaderPath = [[NSBundle mainBundle] pathForResource:name ofType:shaderType == GL_VERTEX_SHADER ? @"vsh" : @"fsh"];
    
    NSError * error;
    
    NSString * shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSAssert(NO, @"读取shader失败");
        exit(1);
    }
    
    //根据类型创建shader
    GLuint shader = glCreateShader(shaderType);
    
    //获取shader source
    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shader, 1, &shaderStringUTF8, &shaderStringLength);
    
    //编译shader
    glCompileShader(shader);
    
    //查看编译是否成功
    GLint complileSuccess;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &complileSuccess);
    if (complileSuccess == GL_FALSE) {
        GLchar message[256];
        glGetShaderInfoLog(shader, sizeof(message), 0, &message[0]);
        NSString * messageStr = [NSString stringWithUTF8String:message];
        NSAssert(NO, @"shader编译失败：%@", messageStr);
        exit(1);
    }
    
    //返回shader
    return shader;
}

/// 从图片中加载纹理
/// @param image 图片
+ (GLuint)creatTextureWithImage:(UIImage *)image{
    //将图片转换成CGImageRef
    CGImageRef imageRef = [image CGImage];
    //判断图片是否获取成功
    if (!imageRef) {
        NSLog(@"Faild to Load Image");
        return 0;
    }
    
    //读取图片属性
    GLuint width = (GLuint)CGImageGetWidth(imageRef);
    GLuint height = (GLuint)CGImageGetHeight(imageRef);
    CGRect imageRect = CGRectMake(0, 0, width, height);
    
    //图片颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    //图片字节数
    void *imageData = malloc(width * height * 4);
    
    //创建上下文
    /*
    参数1：data,指向要渲染的绘制图像的内存地址
    参数2：width,bitmap的宽度，单位为像素
    参数3：height,bitmap的高度，单位为像素
    参数4：bitPerComponent,内存中像素的每个组件的位数，比如32位RGBA，就设置为8
    参数5：bytesPerRow,bitmap的没一行的内存所占的比特数
    参数6：colorSpace,bitmap上使用的颜色空间  kCGImageAlphaPremultipliedLast：RGBA
    */
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    // 将图片翻转过来
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, imageRect);
    
    // 对图片进行重新绘制 得到解压后的位图
    CGContextDrawImage(context, imageRect, imageRef);
    
    //设置图片纹理属性
    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
    
    //载入纹理2D数据
    /*
     参数1：纹理模式，GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
     参数2：加载的层次，一般设置为0
     参数3：纹理的颜色值GL_RGBA
     参数4：宽
     参数5：高
     参数6：border，边界宽度
     参数7：format
     参数8：type
     参数9：纹理数据
     */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    //设置纹理属性
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    //过滤方式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    //绑定纹理
    /*
    参数1：纹理维度
    参数2：纹理ID,因为只有一个纹理，给0就可以了。
    */
    glBindTexture(GL_TEXTURE_2D, 0);
    
    
    //释放空间
    CGContextRelease(context);
    free(imageData);
    
    return textureID;
}

@end
