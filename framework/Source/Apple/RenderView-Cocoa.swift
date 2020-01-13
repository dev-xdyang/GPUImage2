#if canImport(Cocoa)

    import Cocoa

    public class RenderView: NSOpenGLView, ImageConsumer {
        public var backgroundColor = Color.black
        public var fillMode = FillMode.preserveAspectRatio
        public var sizeInPixels: Size { return Size(width: Float(frame.size.width), height: Float(frame.size.width)) }

        public let sources = SourceContainer()
        public let maximumInputs: UInt = 1
        private lazy var displayShader: ShaderProgram = {
            sharedImageProcessingContext.makeCurrentContext()
            self.openGLContext = sharedImageProcessingContext.context
            return sharedImageProcessingContext.passthroughShader
        }()

        // TODO: Need to set viewport to appropriate size, resize viewport on view reshape

        public func newFramebufferAvailable(_ framebuffer: Framebuffer, fromSourceIndex _: UInt) {
            glBindFramebuffer(GLenum(GL_FRAMEBUFFER), 0)
            glBindRenderbuffer(GLenum(GL_RENDERBUFFER), 0)

            let viewSize = GLSize(width: GLint(round(bounds.size.width)), height: GLint(round(bounds.size.height)))
            glViewport(0, 0, viewSize.width, viewSize.height)

            clearFramebufferWithColor(backgroundColor)

            // TODO: Cache these scaled vertices
            let scaledVertices = fillMode.transformVertices(verticallyInvertedImageVertices, fromInputSize: framebuffer.sizeForTargetOrientation(.portrait), toFitSize: viewSize)
            renderQuadWithShader(displayShader, vertices: scaledVertices, inputTextures: [framebuffer.texturePropertiesForTargetOrientation(.portrait)])
            sharedImageProcessingContext.presentBufferForDisplay()

            framebuffer.unlock()
        }
    }

#endif