PI = Math.PI
Vector2 = THREE.Vector2
Vector3 = THREE.Vector3
Matrix4 = THREE.Matrix4
ORIGIN = new Vector3(0, 0, 0)

class @Graphics
  constructor: (parentElement, enableStats) ->
    @parentElement = parentElement
    @renderer = new THREE.WebGLRenderer()
    @dimensions = new THREE.Vector2(
      parentElement.clientWidth, parentElement.clientHeight)
    @renderer.setSize @dimensions.x, @dimensions.y

    if enableStats
      @stats = new Stats()

  loadAssets: (onFinished) ->
    callbacks = new Callbacks(onFinished)
    @boardTexture = THREE.ImageUtils.loadTexture('assets/board-diffuse.png', {},
      callbacks.add ->
    )

    # @material = new THREE.ShaderMaterial(
    #   vertexShader: """
    #     varying vec2 vUv;
    #     void main() {
    #       vUv = uv;
    #       gl_Position = projectionMatrix * modelViewMatrix * vec4(position,1.0);
    #     }
    #     """
    #   fragmentShader: """
    #     uniform sampler2D diffuseMap;
    #     varying vec2 vUv;

    #     void main() {
    #       //gl_FragColor = texture2D(diffuseMap, vUv);
    #       gl_FragColor = vec4(.5, .5, .5, .8);
    #     }
    #     """
    #   uniforms:
    #     diffuseMap:
    #       type: 't'
    #       value: 0
    #       texture: @texture
    # )

    @material = new THREE.MeshLambertMaterial {
      color: 0xffffff
      ambient: 0x333333
      shading: THREE.SmoothShading
      #map: @texture
    }

    @geometry = {}
    loader = new THREE.JSONLoader()

    meshes =
      pawn: { scale: .5 * .8 }
      bishop: { scale: .5 * .8 }
      rook: { scale: .5 * .8 }
      board: { scale: 1 }

    for name of meshes
      console.log "Loading #{name}"
      loader.load(
        "assets/#{name}.js",
        (
          (name) => callbacks.add (geometry) =>
            console.log "Loaded #{name}", geometry
            scale = meshes[name].scale
            geometry.applyMatrix(new THREE.Matrix4().makeScale(scale, scale, scale))
            @geometry[name] = geometry
        )(name)
      )

  createScene: ->
    @renderer.setClearColorHex(0x111122, 1.0)
    @scene = new THREE.Scene()

    @camera = new THREE.PerspectiveCamera(
      35,         # Field of view
      @dimensions.x / @dimensions.y,  # Aspect ratio
      .1,         # Near
      10000       # Far
    )
    @camera.up = new Vector3(0, 0, 1)
    @setCamera 2 * Math.PI * .1
    @scene.add @camera

    @light = new THREE.PointLight 0xFFFFFF
    @light.position.set(-100, 0, 100)
    @scene.add @light

    ############################ Board

    @boardMesh = new THREE.Mesh(
      @geometry.board,
      new THREE.MeshLambertMaterial {
        color: 0xffffff
        ambient: 0x113377
        shading: THREE.FlatShading
        map: @boardTexture
      }
    )
    @scene.add @boardMesh

  addPiece: (piece) ->
    mesh = new THREE.Mesh @geometry[piece.type], @material
    pos = piece.getLocation()
    mesh.position = new Vector3(pos.x, pos.y, 0)
    @scene.add mesh
    return mesh

  #removeMesh: (mesh) ->
  #  @scene.remove mesh

  start: ->
    @parentElement.appendChild @renderer.domElement

    if @stats
      @stats.domElement.style.position = 'absolute';
      @stats.domElement.style.top = '0px';
      @stats.domElement.style.right = '0px';
      @parentElement.appendChild @stats.domElement

  render: ->
    @renderer.render @scene, @camera
    if @stats
      @stats.update()

  setCamera: (angle, distance) ->
    @camera.position.set(
      Math.sin(angle) * distance,
      -Math.cos(angle) * distance,
      10
    )
    @camera.lookAt @scene.position
