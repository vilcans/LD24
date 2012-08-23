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
    @texture = THREE.ImageUtils.loadTexture('assets/grid.png', {},
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
    }

    loader = new THREE.JSONLoader()
    loader.load(
      'assets/box.js',
      callbacks.add (geometry) =>
        #scale = 1.0
        #geometry.applyMatrix(new Matrix4().setScale(scale, scale, scale))
        #geometry.applyMatrix(new Matrix4().setTranslation(0, 0, 1))
        @boxGeometry = geometry
    )

  createScene: ->
    @renderer.setClearColorHex(0x448899, 1.0)
    @scene = new THREE.Scene()

    @camera = new THREE.PerspectiveCamera(
      35,         # Field of view
      @dimensions.x / @dimensions.y,  # Aspect ratio
      .1,         # Near
      10000       # Far
    )
    #@setCamera 0, 10, -20
    @camera.position.z = 10
    console.log 'scene pos', @scene.position, 'dimensions', @dimensions
    @camera.lookAt @scene.position
    @scene.add @camera

    @light = new THREE.PointLight 0xFFFFFF
    @light.position.set(-100, 0, 100)
    @scene.add @light

    @planetMesh = new THREE.Mesh(
      new THREE.SphereGeometry(
        3,  # radius
        25, # segmentsWidth
        50,  # segmentsHeight
        -PI / 2,  # phiStart
        2 * PI, # phiLength
      ),
      #new THREE.MeshBasicMaterial {color: 0xFF0000}
      new THREE.MeshLambertMaterial {
        color: 0xffffff
        ambient: 0x333333
        shading: THREE.FlatShading
      }
    )
    @scene.add @planetMesh

    @boxMesh = @addBox()

  # Example object
  addBox: ->
    #material = new THREE.MeshLambertMaterial {color: 0xFF0000}
    mesh = new THREE.Mesh @boxGeometry, @material
    mesh.position = new Vector3(5, 0, 0)
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
    #@planetMesh.translateX .01
    @renderer.render @scene, @camera
    if @stats
      @stats.update()

   setCamera: (x, y, z) ->
     @cameraMatrix = new Matrix4()
     @cameraMatrix.setPosition x, y, z
     @camera.applyMatrix(@cameraMatrix)
