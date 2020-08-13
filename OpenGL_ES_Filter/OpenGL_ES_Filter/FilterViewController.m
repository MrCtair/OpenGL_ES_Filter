//
//  FilterViewController.m
//  OpenGL_ES_Filter
//
//  Created by trs on 2020/8/11.
//  Copyright © 2020 Ctair. All rights reserved.
//

#import "FilterViewController.h"
#import "ShaderTool.h"
#import <Masonry/Masonry.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/gl.h>
#import "FilterBar.h"


typedef struct {
    GLKVector3 positionCoord;//(x,y,z)
    GLKVector2 textureCoord;//(s,t)
} SenceVertex;

#define SCREENWIDTH [[UIScreen mainScreen] bounds].size.width
#define SCREENHEIGHT [[UIScreen mainScreen] bounds].size.height
#define RECTSTATUS [[UIApplication sharedApplication] statusBarFrame]
#define BOTTOM_SAFE_HEIGHT (RECTSTATUS.size.height == 44 ? 34 : 0)
#define FILTERBARHEIGHT 100.0

@interface FilterViewController ()<FilterBarDelegate>
@property (nonatomic, assign) SenceVertex * vertexs;
@property (nonatomic, strong) EAGLContext * context;
//刷新屏幕
@property (nonatomic, strong) CADisplayLink * displayLink;
//开始的时间戳
@property (nonatomic, assign) NSTimeInterval startTimeInterval;
//着色器程序
@property (nonatomic, assign) GLuint program;
//顶点缓冲区
@property (nonatomic, assign) GLuint vertextBuffer;
//纹理ID
@property (nonatomic, assign) GLuint textureID;

@property (nonatomic, strong) NSArray * dataSource;


@end

@implementation FilterViewController

//释放
- (void)dealloc {
    //1.上下文释放
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    //顶点缓存区释放
    if (_vertextBuffer) {
        glDeleteBuffers(1, &_vertextBuffer);
        _vertextBuffer = 0;
    }
    //顶点数组释放
    if (_vertexs) {
        free(_vertexs);
        _vertexs = nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareForData];
    [self prepareForView];
    [self prepareForAction];
}
- (void)prepareForData{
    switch (_fiterType) {
        case 0:
            _dataSource = @[@{@"title":@"原图", @"shaderName":@"Normal"},
                            @{@"title":@"二分屏", @"shaderName":@"SplitScreen_2"},
                            @{@"title":@"三分屏", @"shaderName":@"SplitScreen_3"},
                            @{@"title":@"四分屏", @"shaderName":@"SplitScreen_4"},
                            @{@"title":@"六分屏", @"shaderName":@"SplitScreen_6"},
                            @{@"title":@"九分屏", @"shaderName":@"SplitScreen_9"}];
            break;
        case 1:
            _dataSource = @[@{@"title":@"原图", @"shaderName":@"Normal"},
                            @{@"title":@"灰度", @"shaderName":@"Gray"},
                            @{@"title":@"颠倒", @"shaderName":@"Reversal"},
                            @{@"title":@"矩形马赛克", @"shaderName":@"SquareMosaic"},
                            @{@"title":@"六边形马赛克", @"shaderName":@"HexagonMosaic"},
                            @{@"title":@"三角形马赛克", @"shaderName":@"TriangleMosaic"},];
            break;
            
        default:
            break;
    }
    
    
    
}
- (void)prepareForView{
    switch (_fiterType) {
        case 0:
            self.navigationItem.title = @"分屏滤镜";
            break;
        case 1:
            self.navigationItem.title = @"灰度/马赛克";
            break;
            
        default:
            break;
    }
    self.view.backgroundColor = [UIColor whiteColor];
    [self setUpFilterBar];
    [self filterInit];
    [self startFilerAnimation];
}
- (void)prepareForAction{
    
}
- (void)filterInit{
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
    
    // 开辟顶点数组内存空间
    self.vertexs = malloc(sizeof(SenceVertex) * 4);
    
    //顶点及纹理数据填入
    self.vertexs[0] = (SenceVertex){{-1, 1, 0}, {0, 1}};
    self.vertexs[1] = (SenceVertex){{-1, -1, 0}, {0, 0}};
    self.vertexs[2] = (SenceVertex){{1, 1, 0}, {1, 1}};
    self.vertexs[3] = (SenceVertex){{1, -1, 0}, {1, 0}};
    
    //创建Layer
    CAEAGLLayer * layer = [[CAEAGLLayer alloc] init];
    
    //设置图层Frame
    layer.frame = CGRectMake(0, RECTSTATUS.size.height + 44, SCREENWIDTH, SCREENHEIGHT - BOTTOM_SAFE_HEIGHT - FILTERBARHEIGHT - RECTSTATUS.size.height - 44);
    
    layer.contentsScale = [[UIScreen mainScreen] scale];
    
    [self.view.layer addSublayer:layer];
    
    
    [self bindRenderLayer:layer];
    
    //图片路径
    NSString * imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"liqin.png"];
    
    //读取图片
    UIImage * image = [UIImage imageNamed:@"liqin"];
    // 将图片转换成纹理图片
    GLuint textureID = [ShaderTool creatTextureWithImage:image];
    
    //绑定纹理ID
    self.textureID = textureID;
    
    // 设置视口
    glViewport(0, 0, self.drawableWidth, self.drawableHeight);
    
    // 设置顶点缓冲区
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    GLsizeiptr bufferSizeiptr = sizeof(SenceVertex) * 4;
    glBufferData(GL_ARRAY_BUFFER, bufferSizeiptr, self.vertexs, GL_STATIC_DRAW);
    
    // 设置默认着色器
    [self setupShaderProgramWithName:_dataSource.firstObject[@"shaderName"]];
    
    // 将顶点缓存保存，退出时才释放
    self.vertextBuffer = vertexBuffer;
}

//绑定渲染缓冲区
- (void)bindRenderLayer:(CALayer <EAGLDrawable> *)layer{
    // 创建渲染缓冲区，帧缓冲对象
    GLuint renderBuffer, frameBuffer;
    
    //获取帧渲染缓存区名称,绑定渲染缓存区以及将渲染缓存区与layer建立连接
    glGenRenderbuffers(1, &renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    
    //获取帧缓存区名称,绑定帧缓存区以及将渲染缓存区附着到帧缓存区上
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBuffer);

}

#pragma mark -- 初始化着色器程序
// 初始化着色器程序
- (void)setupShaderProgramWithName:(NSString *)name {
    //获取着色器program
    GLuint program = [ShaderTool programWithShaderName:name];
    
    //使用program
    glUseProgram(program);
    
    //获取Position,Texture,TextureCoords 的索引位置
    GLuint positionSlot = glGetAttribLocation(program, "Position");
    GLuint textureSlot = glGetUniformLocation(program, "Texture");
    GLuint textureCoordsSlot = glGetAttribLocation(program, "TextureCoords");
    
    //激活纹理 绑定纹理ID
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.textureID);
    
    //纹理sample
    glUniform1i(textureSlot, 0);
    
    //打开positionSlot 属性并且传递数据到positionSlot中(顶点坐标)
    glEnableVertexAttribArray(positionSlot);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, positionCoord));
    
    //打开textureCoordsSlot 属性并传递数据到textureCoordsSlot(纹理坐标)
    glEnableVertexAttribArray(textureCoordsSlot);
    glVertexAttribPointer(textureCoordsSlot, 2, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, textureCoord));
    
    //保存program
    self.program = program;
}

#pragma mark -- 滤镜动画
// 开始一个滤镜动画
- (void)startFilerAnimation {
    //1.判断displayLink 是否为空
    //CADisplayLink 定时器
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
    //2. 设置displayLink 的方法
    self.startTimeInterval = 0;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(timeAction)];
    
    //3.将displayLink 添加到runloop 运行循环
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop]
                           forMode:NSRunLoopCommonModes];
}

//动画
- (void)timeAction {
    //DisplayLink 的当前时间撮
    if (self.startTimeInterval == 0) {
        self.startTimeInterval = self.displayLink.timestamp;
    }
    //使用program
    glUseProgram(self.program);
    //绑定buffer
    glBindBuffer(GL_ARRAY_BUFFER, self.vertextBuffer);
    
    // 传入时间
    CGFloat currentTime = self.displayLink.timestamp - self.startTimeInterval;
    GLuint time = glGetUniformLocation(self.program, "Time");
    glUniform1f(time, currentTime);
    
    // 清除画布
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(1, 1, 1, 1);
    
    // 重绘
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    //渲染到屏幕上
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark — FilterBar
- (void)setUpFilterBar{
    CGFloat filterBarY = SCREENHEIGHT -  FILTERBARHEIGHT - BOTTOM_SAFE_HEIGHT;
    FilterBar *filerBar = [[FilterBar alloc] initWithFrame:CGRectMake(0, filterBarY, SCREENWIDTH, FILTERBARHEIGHT)];
    filerBar.delegate = self;
    [self.view addSubview:filerBar];
    NSMutableArray * itemList = [NSMutableArray array];
    for (NSDictionary * info in _dataSource) {
        [itemList addObject:info[@"title"]];
    }
    filerBar.itemList = itemList;
}

#pragma mark - FilterBarDelegate

- (void)filterBar:(FilterBar *)filterBar didScrollToIndex:(NSUInteger)index {
    
    [self setupShaderProgramWithName:_dataSource[index][@"shaderName"]];
    // 重新开始滤镜动画
    [self startFilerAnimation];
}


//获取渲染缓存区的宽
- (GLint)drawableWidth {
    GLint backingWidth;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    return backingWidth;
}
//获取渲染缓存区的高
- (GLint)drawableHeight {
    GLint backingHeight;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    return backingHeight;
}

@end
