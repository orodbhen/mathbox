Primitive = require '../../primitive'
Util      = require '../../../util'

class Compose extends Primitive
  @traits: ['node', 'bind', 'object', 'operator', 'style', 'compose']

  constructor: (node, context, helpers) ->
    super node, context, helpers

    @compose = null

  resize: () ->
    return unless @compose and @bind.source

    dims = @bind.source.getActive()
    width  = dims.width
    height = dims.height
    depth  = dims.depth
    layers = dims.items

    @remap2DScale.set width, height

  make: () ->
    # Bind to attached data sources
    @_helpers.bind.make
      'operator.source': 'source'

    return unless @bind.source?

    # Prepare uniforms for remapping to absolute coords on the fly
    resampleUniforms =
      remap2DScale: @_attributes.make @_types.vec2()
    @remap2DScale = resampleUniforms.remap2DScale.value

    # Build fragment shader
    fragment = @_shaders.shader()
    alpha    = @_get 'compose.alpha'

    if @bind.source.is 'image'
      # Sample image directly in 2D
      @bind.source.imageShader fragment
    else
      # Sample data source in 4D
      fragment.pipe 'screen.remap.2d.xyzw', resampleUniforms
      @bind.source.sourceShader fragment

    # Force pixels to solid if requested
    fragment.pipe 'color.opaque' if !alpha

    # Make screen renderable
    composeUniforms = @_helpers.style.uniforms()
    @compose = @_renderables.make 'screen',
                 fragment: fragment
                 uniforms: composeUniforms

    @resize()

    @_helpers.object.make [@compose], true

  unmake: () ->
    @_helpers.bind.unmake()
    @_helpers.object.unmake()

  change: (changed, touched, init) ->
    return @rebuild() if changed['operator.source'] or
                         changed['compose.alpha']

    if changed['compose.depth'] or init
      @compose.depth false, @_get 'compose.depth'


module.exports = Compose
