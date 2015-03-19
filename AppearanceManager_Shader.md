Shader node (`<shader>` and `<shaderTemplate>`) describes the shading method and arguments of meshes, such as shading program, diffuse and specular color, texture coordinates and texture files, etc.

The `<shader>` describes a shader, and `<shaderTemplate>` describes a shader template (see [AppearanceManager\_Shader#About\_Shader\_Template](AppearanceManager_Shader#About_Shader_Template.md)).

Currently the shader node supports following attributes:

  * `templateName` _(optional)_
> If the node is `<shader>`, then it specifies which shader template will used. See [AppearanceManager\_Shader#About\_Shader\_Template](AppearanceManager_Shader#About_Shader_Template.md). If the node is `<shaderTemplate>`, then it specifies the shader template name.
  * `shaderProgram`
> Specifies the shader program. Can be one of following values:
    * `none`: Don't use programmable rendering pipeline. Sorry, currently unsupported :(
    * `standard`: Use a standard shading program, which supports per-pixel lighting (includes ambient, diffuse, specular and emissive), normal mapping, parallax mapping. Some other features are work in progress.
  * `diffuseAlgorithm` _(optional)_
> Specifies the diffuse calculation algorithm. Can be one of following values:
    * `default` or `Lambertian` _(default)_: Use Lambertian diffuse algorithm, i.e. `dot(LightVector,NormalVector)`.
    * `Oren-Nayar`: Use Oren-Nayar diffuse algorithm. For more information, see [Wikipedia](http://en.wikipedia.org/wiki/Oren-Nayar_diffuse_model).
  * `specularAlgorithm` _(optional)_
> Specifies the specular calculation algorithm. Can be one of following values:
    * `default` or `Blinn-Phong` _(default)_: Use Blinn-Phong algorithm, i.e. `dot(LightVector,HalfwayVector)`. For more information, see [Wikipedia](http://en.wikipedia.org/wiki/Blinn%E2%80%93Phong_shading_model).
    * `Phong`: Use Phong algorithm, i.e. `dot(ReflectVector,ViewVector)`. For more information, see [Wikipedia](http://en.wikipedia.org/wiki/Phong_shading).
  * `fogEnabled`
> Currently unsupported.
  * `shadowMapEnabled`
> Currently unsupported.
  * `hardwareInstancing` _(optional)_
> Specifies how this shader program supports hardware instancing. Can be one of following values:
    * `default` or `none` or `disabled` _(default)_: This shader program doesn't support hardware instancing.
    * `translation` or `translationOnly`: This shader program supports hardware instancing, but only if the transform matrix is translation matrix.
    * `transformMatrix` or `worldMatrix` or `matrix`: This shader program has fully hardware instancing support. **NOTE: This option is not compatible with non-hardware-instancing mode.**
  * `effectState`
> Specifies the extra effect state options. For example, `AlphaBlendEnable = TRUE;`. For more information, see [DirectX SDK](http://msdn.microsoft.com/en-us/library/bb173347(v=VS.85).aspx).

Following attributes are currently supported shader parameters. They are all optional.

  * `baseColor`: _(A stupid parameter)_ Specifies the base color. If `baseColor` is not specified, then the shader will not use a base color, and the output color is `Color=Ambient+LightAmount*(Diffuse+Specular)+Emissive`. If `baseColor` is specified, then the output color is `Color=BaseColor*(Ambient+LightAmount*Diffuse)+LightAmount*Specular+Emissive`.
  * `ambient`: Specifies the ambient color. Typical range is 0 to 1.
  * `diffuse`: Specifies the diffuse color.
  * `specular`: Specifies the specular color.
  * `specularHardness`: Specifies the specular hardness. Typical value is 50.
  * `OrenNayarRoughness`: Specifies the roughness parameter in Oren-Nayar diffuse algorithm, if `diffuseAlgorithm="Oren-Nayar"`. Typical range is 0 to 1.
  * `emissive`: Specifies the emissive color.
  * `normalMap`: Specifies the normal map. If this parameter is not set, then normal mapping is disabled. Otherwise normal mapping is enabled.
  * `normalMapScale`: Specifies the normal map scaling. If this parameter is not set, then the shader program will use input normal map data. Otherwise the x,y component of input data will be scaled, and renormalized.
  * `parallaxMap`: Specifies the height map of parallax mapping. If this parameter is not set, then parallax mapping is disabled. Otherwise parallax mapping is enabled. **NOTE: The parameter type should be `textureArgument`, and currently only the input texture coordinate will be affected. So if you want to use parallax mapping, you should set the texture coordinate of `parallaxMap`, `normalMap`, `diffuse` etc. to the same.**
  * `parallaxMapOffset`: Specifies the height map offset of parallax mapping. Typical value is -0.5.
  * `parallaxMapScale`: Specifies the height map scale of parallax mapping. Typical value is 0.02.

## Shader Parameter Format ##

Following are currently supported shader parameter's value type:

  * **`<`Constant`>`**
> The parameter is a constant scalar/vector contains 1~4 elements. For example, `0.5` or `1,2,3,4`. The constant will be hard-coded into the shader program, so it's unchangeable after the creation of shader. One exception is if the shader is inherited from a shader template, and the parameter's type of shader template is `shaderArgument`, then the parameter's type of this shader will automatically convert to `shaderArgument`, instead of hard-coded constant.
  * `shaderArgument``[`:**`<`Constant`>`**`]`
> Will assign a global variable to store this parameter in shader program. If **`<`Constant`>`** is not specified, then the default value of parameter is 0, otherwise the default value is **`<`Constant`>`**.
  * (`color``[`**`<`number`>`**`]`|`texcoord``[`**`<`number`>`**`]`)`[`:(0|1|x|y|z|w|r|g|b|a|C|A)+`[`:**`<`Constant`>`**`]``]`
> Read specified color or texture coordinate from the input vertex data of shader program, using specified order.
> Currently the valid input type is `color0`, `color1`, and `texcoord0` to `texcoord15`. If the **`<`number`>`** is not specified, the default value is 0.
> `(0|1|x|y|z|w|r|g|b|a|C|A)+` specifies the order of component. If this is not specified, the default order is `xyzw`.
    * `0`: This component is always 0.
    * `1`: This component is always 1.
    * `x` or `r`: This component is the first component of input value.
    * `y` or `g`: This component is the second component of input value.
    * `z` or `b`: This component is the third component of input value.
    * `w` or `a`: This component is the fourth component of input value.
    * `C`: This component is a hard-coded constant, reading from **`<`Constant`>`** consecutively.
    * `A`: This component is reading from a global variable, which default value is reading from **`<`Constant`>`** consecutively.
> Some examples:
> `texcoord` means read the value from `texcoord0`.
> `texcoord3:zyx` means read the value from `texcoord3` and change the component's order, more clearly, swap the first and third component.
> `color1:wCbA:0.3,0.6` the value is `float4(color1.w,0.3,color1.b,some_global_variable)` and the default value of `some_global_variable` is 0.6.
  * `textureArgument`**`<`num1`>`**`[`.(x|y|z|w|r|g|b|a)+`]`:texcoord**`<`num2`>`**`[`.(x|y|z|w|r|g|b|a)+`]``[`:`textureFile`:**`<`FileName`>`**`]``[`:**`<`SamplerState`>`**`]`
> Sample the specified texture using specified texture coordinate in the input vertex data, and change the components' order to specified order.
> Blah blah blah ...
> If two or more parameters use the same `textureArgument`, then the `textureFile` and **`<`SamplerState`>`** only need to set once.
> For more information about **`<`SamplerState`>`**, see [DirectX SDK](http://msdn.microsoft.com/en-us/library/bb509644(v=VS.85).aspx).

## An Example ##

```
<shader shaderProgram="standard"
  baseColor="textureArgument0:texcoord0:textureFile:tex1.png:MipFilter=NONE;MinFilter=LINEAR;MagFilter=LINEAR;AddressU=CLAMP;AddressV=CLAMP;"
  ambient="0.5,0.5,0.5" diffuse="0.5,0.5,0.5"
  specular="0.4,0.4,0.3" specularHardness="20"
  normalMap="textureArgument1.zyx:texcoord0:textureFile:normal1.png:MipFilter=NONE;MinFilter=LINEAR;MagFilter=LINEAR;AddressU=CLAMP;AddressV=CLAMP;"
  parallaxMap="textureArgument0.y:texcoord0"
  parallaxMapOffset="-0.5" parallaxMapScale="0.02"
/>
```

## About Shader Template ##

A shader template is a shader whose shader program is fixed, but some parameters can be declared as `shaderArgument` thus can be changed in the inherited shader or when the program is running. Using shader template decreases the loading time, rendering time and memory usage because it prevents the creating of multiple unnecessary shader programs.

For example:

```
<!-- in DefaultShaders.xml -->
<shaderTemplate templateName="simple1_fixed" shaderProgram="standard"
ambient="shaderArgument" diffuse="shaderArgument"
specular="shaderArgument" specularHardness="shaderArgument"
emissive="shaderArgument"/>
...
<!-- in an appearance node -->
<!-- will share shader program with "simple1_fixed" instead of creating a new one -->
<shader templateName="simple1_fixed" ambient="0.4,0.25,0.2"
diffuse="0.4,0.35,0.3" specular="0.5,0.5,0.5" specularHardness="50">
  <mesh type="cube" s="1,1,0.25" c="0,0,1" bevel="1;0.05" bevelNormalSmoothness="1"/>
</shader>
```

NOTE: Currently if you set some shader parameters whose type in the shader template isn't `shaderArgument` or `textureArgument`, then they will be ignored. For example:

```
<shaderTemplate templateName="simple1_fixed" shaderProgram="standard"
diffuse="shaderArgument"/>
...
<!-- "diffuse" will work, but "ambient" will not work -->
<shader templateName="simple1_fixed"
ambient="0.4,0.25,0.2" diffuse="0.4,0.35,0.3">
...
</shader>
```