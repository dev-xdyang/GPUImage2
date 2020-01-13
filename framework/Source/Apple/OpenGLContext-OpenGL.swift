#if canImport(OpenGL)

    import Cocoa
    import OpenGL.GL

    // TODO: Figure out way to allow for multiple contexts for different GPUs

    public class OpenGLContext: SerialDispatch {
        public lazy var framebufferCache: FramebufferCache = {
            FramebufferCache(context: self)
        }()

        var shaderCache: [String: ShaderProgram] = [:]
        public let standardImageVBO: GLuint
        var textureVBOs: [Rotation: GLuint] = [:]

        let context: NSOpenGLContext

        lazy var passthroughShader: ShaderProgram = {
            crashOnShaderCompileFailure("OpenGLContext") { try self.programForVertexShader(OneInputVertexShader, fragmentShader: PassthroughFragmentShader) }
        }()

        public let serialDispatchQueue: DispatchQueue = DispatchQueue(label: "com.sunsetlakesoftware.GPUImage.processingQueue", attributes: [])
        public let dispatchQueueKey = DispatchSpecificKey<Int>()

        // MARK: -

        // MARK: Initialization and teardown

        init() {
            serialDispatchQueue.setSpecific(key: dispatchQueueKey, value: 81)

            let pixelFormatAttributes: [NSOpenGLPixelFormatAttribute] = [
                NSOpenGLPixelFormatAttribute(NSOpenGLPFADoubleBuffer),
                NSOpenGLPixelFormatAttribute(NSOpenGLPFAAccelerated), 0,
                0,
            ]

            guard let pixelFormat = NSOpenGLPixelFormat(attributes: pixelFormatAttributes) else {
                fatalError("No appropriate pixel format found when creating OpenGL context.")
            }
            // TODO: Take into account the sharegroup
            guard let generatedContext = NSOpenGLContext(format: pixelFormat, share: nil) else {
                fatalError("Unable to create an OpenGL context. The GPUImage framework requires OpenGL support to work.")
            }

            context = generatedContext
            generatedContext.makeCurrentContext()

            standardImageVBO = generateVBO(for: standardImageVertices)
            generateTextureVBOs()

            glDisable(GLenum(GL_DEPTH_TEST))
            glEnable(GLenum(GL_TEXTURE_2D))
        }

        // MARK: -

        // MARK: Rendering

        public func makeCurrentContext() {
            context.makeCurrentContext()
        }

        func presentBufferForDisplay() {
            context.flushBuffer()
        }

        // MARK: -

        // MARK: Device capabilities

        func supportsTextureCaches() -> Bool {
            return false
        }

        public var maximumTextureSizeForThisDevice: GLint { return _maximumTextureSizeForThisDevice }
        private lazy var _maximumTextureSizeForThisDevice: GLint = {
            self.openGLDeviceSettingForOption(GL_MAX_TEXTURE_SIZE)
        }()

        public var maximumTextureUnitsForThisDevice: GLint { return _maximumTextureUnitsForThisDevice }
        private lazy var _maximumTextureUnitsForThisDevice: GLint = {
            self.openGLDeviceSettingForOption(GL_MAX_TEXTURE_IMAGE_UNITS)
        }()

        public var maximumVaryingVectorsForThisDevice: GLint { return _maximumVaryingVectorsForThisDevice }
        private lazy var _maximumVaryingVectorsForThisDevice: GLint = {
            self.openGLDeviceSettingForOption(GL_MAX_VARYING_VECTORS)
        }()

        lazy var extensionString: String = {
            self.runOperationSynchronously {
                self.makeCurrentContext()
                return String(cString: unsafeBitCast(glGetString(GLenum(GL_EXTENSIONS)), to: UnsafePointer<CChar>.self))
            }
        }()
    }
#endif