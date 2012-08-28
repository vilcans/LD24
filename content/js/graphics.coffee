PI = Math.PI
Vector2 = THREE.Vector2
Vector3 = THREE.Vector3
Matrix4 = THREE.Matrix4
ORIGIN = new Vector3(0, 0, 0)

DESTROY_ANIMATION_LENGTH = .7

class @Graphics
  constructor: (parentElement, enableStats) ->
    @parentElement = parentElement
    @renderer = new THREE.WebGLRenderer()
    @dimensions = new THREE.Vector2(
      parentElement.clientWidth, parentElement.clientHeight)
    @renderer.setSize @dimensions.x, @dimensions.y
    @renderer.shadowMapEnabled = true
    @renderer.shadowMapSoft = true
    if enableStats
      @stats = new Stats()

    @dyingPieces = []

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

    @materials = {}
    @materials[Piece.WHITE] = new THREE.MeshPhongMaterial {
      color: 0xbbaa99
      specular: 0xcccccc
      shininess: 10
    }
    @materials[Piece.BLACK] = new THREE.MeshPhongMaterial {
      color: 0x0c0803
      specular: 0xcccccc
      shininess: 30
    }

    @geometry = {}
    loader = new THREE.JSONLoader()

    meshes =
      pawn: { scale: .5 * .8 }
      bishop: { scale: .5 * .8 }
      rook: { scale: .5 * .8 }
      knight: { scale: .5 * .8 }
      king: { scale: .5 * .8 }
      queen: { scale: .5 * .8 }
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
    @renderer.setClearColorHex(0x335566, 1.0)
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

    @light = new THREE.SpotLight(
      0xffeecc,
      1,  # intensity
      100,  # distance,
      #2 / 360 * Math.PI * 2  # angle
    )
    @light.castShadow = true
    @light.shadowDarkness = .5
    #@light.shadowCameraVisible = true
    @light.shadowCameraNear = 20
    @light.shadowCameraFar = 30
    #@light.shadowMapWidth = 2048
    #@light.shadowMapHeight = 2048
    @light.position.set(-10, -10, 20)

    @scene.add @light

    @fillLight = new THREE.PointLight(0xcceeff, .7)
    @fillLight.position.set(10, 10, 1)
    @scene.add @fillLight

    @scene.add new THREE.AmbientLight(0x081018)

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
    @boardMesh.castShadow = false
    @boardMesh.receiveShadow = true
    @scene.add @boardMesh

  addPiece: (piece) ->
    mesh = new THREE.Mesh @geometry[piece.type], @materials[piece.team]
    pos = piece.getLocation()
    mesh.position = new Vector3(pos.x, pos.y, 0)
    mesh.castShadow = true
    mesh.receiveShadow = true
    @scene.add mesh
    return mesh

  destroyPiece: (mesh) ->
    mesh.destruction =
      time: getSystemTime()
      rotationSpeedX: (Math.random() * 4 - 2) * Math.PI * 2
      rotationSpeedY: (Math.random() * 4 - 2) * Math.PI * 2
    @dyingPieces.push mesh

  removePiece: (mesh) ->
    @scene.remove mesh

  start: ->
    console.log 'Graphics start'
    @parentElement.appendChild @renderer.domElement

    if @stats
      @stats.domElement.style.position = 'absolute';
      @stats.domElement.style.top = '0px';
      @stats.domElement.style.right = '0px';
      @parentElement.appendChild @stats.domElement

  animate: (deltaTime) ->
    now = getSystemTime()
    i = 0
    while i < @dyingPieces.length
      piece = @dyingPieces[i]
      age = now - piece.destruction.time
      if age > DESTROY_ANIMATION_LENGTH
        @dyingPieces.splice i, 1
        @scene.remove piece
      else
        piece.position.z = 15 * Math.sin(
          age / DESTROY_ANIMATION_LENGTH * Math.PI / 2)
        piece.rotation.x = age * piece.destruction.rotationSpeedX
        piece.rotation.y = age * piece.destruction.rotationSpeedY
        i++

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
