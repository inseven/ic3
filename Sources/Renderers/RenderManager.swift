// MIT License
//
// Copyright (c) 2023 Jason Barrie Morley
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

class RenderManager {

    private let templateCache: TemplateCache
    private let renderers: [TemplateLanguage: Renderer]

    init(templateCache: TemplateCache) {
        self.templateCache = templateCache
        self.renderers = [
            .identity: IdentityRenderer(templateCache: templateCache),
            .stencil: StencilRenderer(templateCache: templateCache),
            .tilt: TiltRenderer(templateCache: templateCache),
        ]
    }

    func renderer(for language: TemplateLanguage) throws -> Renderer {
        guard let renderer = renderers[language] else {
            throw InContextError.internalInconsistency("Failed to get renderer for language '\(language)'.")
        }
        return renderer
    }

    func render(renderTracker: RenderTracker,
                template: TemplateIdentifier,
                context: [String: Any]) async throws -> String {
        let renderer = try renderer(for: template.language)

        // Perform the render.
        let renderResult = try await renderer.render(name: template.name, context: context)

        // Record the renderer instance used.
        // It is sufficient to record this once for the whole render operation even though multiple templates might be
        // used, as we do not allow mixing of template languages within a single top-level render.
        renderTracker.add(RendererInstance(language: template.language, version: renderer.version))

        // Generate language-scoped identifiers for the templates reported as used by the renderer.
        let templatesUsed: [TemplateIdentifier] = renderResult.templatesUsed.map { name in
            return TemplateIdentifier(template.language, name)
        }

        // Look-up the modification date for each template, generate an associated render status, and add this to the
        // tracker.
        for template in templatesUsed {
            guard let modificationDate = templateCache.modificationDate(for: template) else {
                throw InContextError.internalInconsistency("Failed to get content modification date for template '\(template)'.")
            }
            renderTracker.add(TemplateRenderStatus(identifier: template, modificationDate: modificationDate))
        }
        return renderResult.content
    }

}