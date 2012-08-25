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
    @texture = THREE.ImageUtils.loadTexture('assets/f-diffuse.png', {},
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
      shading: THREE.FlatShading
      map: @texture
    }

    # loader = new THREE.JSONLoader()
    # loader.load(
    #   'assets/f.js',
    #   callbacks.add (geometry) =>
    #     #geometry.applyMatrix(new THREE.Matrix4().makeScale(1, -1, 1))
    #     #geometry.applyMatrix(new Matrix4().setTranslation(0, 0, 1))
    #     @geometry = geometry
    # )

    @geometry = {
      pawn: new THREE.CubeGeometry(
        .9, # width
        .9, # height
        1, # depth
        1, # segmentsWidth
        1, # segmentsHeight
        1, # segmentsDepth
      )
    }
    @geometry.pawn.applyMatrix(new Matrix4().setPosition(new Vector3(0, 0, .5)))

  createScene: ->
    @renderer.setClearColorHex(0x111122, 1.0)
    @scene = new THREE.Scene()

    @camera = new THREE.PerspectiveCamera(
      35,         # Field of view
      @dimensions.x / @dimensions.y,  # Aspect ratio
      .1,         # Near
      10000       # Far
    )
    #@setCamera 0, 10, -20
    @camera.position.z = 20
    console.log 'scene pos', @scene.position, 'dimensions', @dimensions
    @camera.lookAt @scene.position
    @scene.add @camera

    @light = new THREE.PointLight 0xFFFFFF
    @light.position.set(-100, 0, 100)
    @scene.add @light

    ############################ Board
    BOARD_THICKNESS = .25

    @boardMesh = new THREE.Mesh(
      new THREE.CubeGeometry(
        8, # width
        8, # height
        BOARD_THICKNESS, # depth
        1, # segmentsWidth
        1, # segmentsHeight
        1, # segmentsDepth
        # [
        #   new THREE.MeshLambertMaterial {color: 0x555555, ambient: 0x333333, shading: THREE.FlatShading},
        #   new THREE.MeshLambertMaterial {color: 0x0000ff, ambient: 0x333333, shading: THREE.FlatShading},
        #   new THREE.MeshLambertMaterial {color: 0xff0000, ambient: 0x333333, shading: THREE.FlatShading},
        #   new THREE.MeshLambertMaterial {color: 0xff00ff, ambient: 0x333333, shading: THREE.FlatShading},
        #   new THREE.MeshLambertMaterial {color: 0x00ff00, ambient: 0x333333, shading: THREE.FlatShading},
        #   new THREE.MeshLambertMaterial {color: 0x00ffff, ambient: 0x333333, shading: THREE.FlatShading},
        # ]
      )
      new THREE.MeshLambertMaterial {
        color: 0x88ccff
        ambient: 0x113377
        shading: THREE.FlatShading
      }
    )
    @boardMesh.position = new THREE.Vector3(0, -BOARD_THICKNESS / 2, 0)
    @scene.add @boardMesh

  addPiece: (piece) ->
    mesh = new THREE.Mesh @geometry.pawn, @material
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

   setCamera: (x, y, z) ->
     @cameraMatrix = new Matrix4()
     @cameraMatrix.setPosition x, y, z
     @camera.applyMatrix(@cameraMatrix)
