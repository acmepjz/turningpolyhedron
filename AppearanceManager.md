Currently the game using `<appearance>` XML node to save the appearance data of block and tile.

Possible subnodes are:

  * `<shader>` subnode. See AppearanceManager\_Shader.
  * `<mesh>` subnode. See AppearanceManager\_Mesh.

For example:

```
<appearance>
  <!-- will draw mesh 1 with shader 1 and mesh 2 with shader 1 -->
  <shader ... >  <!-- shader 1 -->
    <mesh ... /> <!-- mesh 1 -->
    <mesh ... /> <!-- mesh 2 -->
  </shader>
  <!-- currently unsupported -->
  <mesh ... > <!-- mesh 3 -->
    <shader ... /> <!-- shader 2 -->
    <shader ... /> <!-- shader 3 -->
  </mesh>
  <!-- then draw mesh 4 with shader 4 and mesh 5 with shader 4 -->
  <shader ... >  <!-- shader 4 -->
    <mesh ... /> <!-- mesh 4 -->
    <mesh ... /> <!-- mesh 5 -->
  </shader>
</appearance>
```

Additionally, you can put some `<shader>` or `<shaderTemplate>` in default shader file such as `DefaultShaders.xml`.