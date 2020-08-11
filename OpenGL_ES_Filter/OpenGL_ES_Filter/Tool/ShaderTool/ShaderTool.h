//
//  ShaderTool.h
//  FilterOfSplitScreen
//
//  Created by trs on 2020/8/11.
//  Copyright © 2020 China. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ShaderTool : NSObject

/// link Program
/// @param shaderName 着色器名字
+ (GLuint)programWithShaderName:(NSString *)shaderName;


/// 编译着色器
/// @param name 着色器名字
/// @param shaderType 着色器类型
+ (GLuint)compileShaderWithName:(NSString *)name type:(GLenum)shaderType;

/// 从图片中加载纹理
/// @param image 图片
+ (GLuint)creatTextureWithImage:(UIImage *)image;
@end


NS_ASSUME_NONNULL_END
