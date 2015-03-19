Mesh node (`<mesh>`) describes the mesh type and arguments.

Currently the mesh node supports following attributes:

  * `type` Specifies the type of mesh. Possible types:
    * `cube` The only supported type so far :(
  * `p` Specifies the position that the center of mesh should put at. The default value is `0,0,0`.
  * `p1` and `p2` and `p3` Specifies the x,y,z axis vector. The default value is `1,0,0` and `0,1,0` and `0,0,1`, respectively.
  * `r` Specifies the rotation. The default value is `0,0,0`. This parameter will pass to [D3DXMatrixRotationYawPitchRoll](http://msdn.microsoft.com/en-us/library/bb205361(v=VS.85).aspx). The default unit of the angle is radian, but you can append a `d` after number to indicate that the unit should be degree, for example `45d,45d,45d`.
  * `s` Specifies the scaling factor. The default value is `1,1,1`.
  * `c` Specifies the center of mesh, in relative size. For example, if `type="cube"` and `c="0.5,0.5,0.5"` and `p="0,0,0"` then the center of cube will put on the origin. If `c="0.5,0.5,0"` then the center of bottom face will put on the origin. The default value is `0,0,0`.
  * `bevel` Specifies the bevel type and amount. Currently more than 3 edges meet together is unsupported. The value format is `0|((1|2);(<num>[%]|<x>[%],<y>[%],<z>[%]))`.
    * If the value is `0`, no bevel is perform.
    * If the first character of value is `1` or `2` then BLAH BLAH BLAH
    * `<num>[%]|<x>[%],<y>[%],<z>[%]` means bevel amount. If using `%` then relative size is used, otherwise it's absolute size. If `<num>` is used, then the bevel amount is same for all direction, otherwise the specified value will be used.
  * `normalSmoothness` Specifies the normal smoothness of ordinal face. `0` means use face normal, `1` means the average normal of adjacent faces. Other values means linear interpolating using these two normals.
  * `bevelNormalSmoothness` Specifies the normal smoothness of bevel face.
  * (`color``[`**`<`number`>`**`]`|`texcoord``[`**`<`number`>`**`]`)`[`.(x|y|z|w|r|g|b|a)+`]`
> Specifies (some components of) the color or texture coordinate of mesh data.
> `(x|y|z|w|r|g|b|a)+` specifies which components need to set value. If this is not specified, the default value is `xyzw`.
    * `x` or `r` means the first component.
    * `y` or `g` means the second component.
    * `z` or `b` means the third component.
    * `w` or `a` means the fourth component.
> The possible values of this attribute are:
    * **`<`Constant`>`**: Use a constant scalar/vector contains 1~4 elements for the value.
    * `unwrap``[`:**`<`Constant`>`**`]` Depends on which type this mesh is. For example, if `type="cube"` then `unwrap` means `rect_unwrap`.
    * `rect_unwrap``[`:**`<`Constant`>`**`]` Assume the mesh is a cube and unwrap it using the size specified in **`<`Constant`>`**. If **`<`Constant`>`** is not set, then the program will use `s` for the size. See picture below.
> > ![http://turningpolyhedron.googlecode.com/svn/trunk/turningpolyhedron/doc/rect-unwrap.png](http://turningpolyhedron.googlecode.com/svn/trunk/turningpolyhedron/doc/rect-unwrap.png)
    * `rect``[`:**`<`Constant`>`**`]` Assume the mesh is a cube and set texture coordinate of each face to (0,0) to (x,y) or (x,z) or (y,z), depending for the orientation of face. The **`<`Constant`>`** specifies the size of cube. If **`<`Constant`>`** is not set, then the program will use `s` for the size.