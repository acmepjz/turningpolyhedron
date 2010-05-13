function main()
{
    levelmoves = 0;
    var _loc3 = new String();
    _loc3 = _loc3 + level * 3;
    _loc3 = Math.floor(Math.random() * 90 + 10) + _loc3 + Math.floor(Math.random() * 900 + 100);
    _root.pass.text = _loc3;
    _root.lvl.text = "Level " + level;
    matrice = Level(level);
    id = 0;
    jd = W + 1;
    this.onEnterFrame = DeseneazaLume;
} // End of the function
function Level(nr)
{
    var _loc1 = new Array();
    if (nr == 1)
    {
        startx = 100;
        starty = 250;
        _loc1[0] = new Array(1, 1, 1, 1, 1, 1, 1, 1, 1, 0);
        _loc1[1] = new Array(0, 0, 1, 1, 0, 0, 0, 0, 1, 0);
        _loc1[2] = new Array(0, 0, 1, 1, 0, 0, 0, 0, 1, 0);
        _loc1[3] = new Array(0, 0, 0, 0, 0, 0, 1, 1, 1, 0);
        _loc1[4] = new Array(0, 0, 0, 0, 0, 0, 1, 1, -1, 1);
        _loc1[5] = new Array(0, 0, 0, 0, 0, 0, 0, 1, 1, 1);
        _loc1[6] = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[7] = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[8] = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[9] = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        return (_loc1);
    } // end if
    if (nr == 2)
    {
        startx = 150;
        starty = 200;
        _loc1[0] = new Array(0, 0, 0, 1, 1, 1, 0, 0, 0, 0);
        _loc1[1] = new Array(0, 0, 0, 1, 1, 1, 0, 0, 0, 0);
        _loc1[2] = new Array(1, 1, 1, 1, 0, 0, 0, 0, 0, 0);
        _loc1[3] = new Array(1, 1, 0, 1, 0, 0, 0, 0, 0, 0);
        _loc1[4] = new Array(1, 1, 0, 1, 1, 1, 1, 0, 0, 0);
        _loc1[5] = new Array(0, 1, 0, 1, 0, 0, 1, 0, 0, 0);
        _loc1[6] = new Array(0, 1, 0, 1, 0, 0, 1, 0, 0, 0);
        _loc1[7] = new Array(1, 1, 0, 2, 1, 1, 1, 0, 0, 0);
        _loc1[8] = new Array(1, -1, 1, 1, 1, 1, 0, 0, 0, 0);
        _loc1[9] = new Array(1, 1, 0, 0, 0, 0, 0, 0, 0, 0);
        return (_loc1);
    } // end if
    if (nr == 3)
    {
        startx = 20;
        starty = 250;
        _loc1[0] = new Array(0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0);
        _loc1[1] = new Array(1, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 0);
        _loc1[2] = new Array(1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1);
        _loc1[3] = new Array(1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, -1, 1);
        _loc1[4] = new Array(1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1);
        _loc1[5] = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1);
        _loc1[6] = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[7] = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[8] = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[9] = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        return (_loc1);
    } // end if
    if (nr == 4)
    {
        startx = 20;
        starty = 110;
        _loc1[0] = new Array(1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[1] = new Array(1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[2] = new Array(1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[3] = new Array(1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[4] = new Array(1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 0);
        _loc1[5] = new Array(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2);
        _loc1[6] = new Array(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, -1, 2);
        _loc1[7] = new Array(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2);
        _loc1[8] = new Array(1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 0);
        _loc1[9] = new Array(1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[10] = new Array(1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[11] = new Array(1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[12] = new Array(1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        return (_loc1);
    } // end if
    if (nr == 5)
    {
        startx = 100;
        starty = 150;
        _loc1[0] = new Array(2, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[1] = new Array(2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[2] = new Array(1, 2, 2, 2, 1, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0);
        _loc1[3] = new Array(2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 0, 0, 0, 0, 0);
        _loc1[4] = new Array(2, 2, 2, 2, 1, 2, 3.080300E+000, 2, 2, 2, 0, 0, 0, 0, 0);
        _loc1[5] = new Array(2, 2, 1, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0);
        _loc1[6] = new Array(2, 2, 2, 2, 2, 2, -1, 2, 2, 2, 0, 0, 0, 0, 0);
        _loc1[7] = new Array(0, 0, 0, 0, 0, 2, 1, 2, 0, 0, 0, 0, 0, 0, 0);
        return (_loc1);
    } // end if
    if (nr == 6)
    {
        startx = 110;
        starty = 150;
        _loc1[0] = new Array(1, 1, 1, 0, 0, 4.020390E+000, 0, 1, 2, 2, 0, 0, 0, 0, 0);
        _loc1[1] = new Array(1, 1, 4.020300E+000, 0, 0, 1, 0, 1, 2, -1, 2, 0, 0, 0, 0);
        _loc1[2] = new Array(0, 0, 1, 2, 2, 1, 0, 1, 2, 1, 0, 0, 0, 0, 0);
        _loc1[3] = new Array(0, 0, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0);
        _loc1[4] = new Array(0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0);
        _loc1[5] = new Array(0, 0, 3.030800E+000, 4.050700E+000, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[6] = new Array(0, 0, 0, 2, 2, 2, 4.060700E+000, 1, 2, 0, 0, 0, 0, 0, 0);
        _loc1[7] = new Array(0, 0, 0, 2, 2, 0, 0, 4.070500E+000, 2, 0, 0, 0, 0, 0, 0);
        _loc1[8] = new Array(0, 0, 0, 1, 0, 2, 1, 1, 2, 0, 0, 0, 0, 0, 0);
        _loc1[9] = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[10] = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[11] = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        return (_loc1);
    } // end if
    if (nr == 7)
    {
        startx = 60;
        starty = 200;
        _loc1[0] = new Array(1, 1, 1, 0, 0, 2, 2, 2, 2, 2, 2, 2, 2);
        _loc1[1] = new Array(1, 1, 1, 0, 0, 2, 2, 2, 2, 2, 2, 2, 2);
        _loc1[2] = new Array(1, 4.050200E+000, 1, 1, 1, 0, 2, 2, 2, 2, 2, 4.060600E+000, 2);
        _loc1[3] = new Array(0, 0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0);
        _loc1[4] = new Array(0, 0, 0, 4.040400E+000, 0, 2, 2, 2, 2, 2, 2, 4.070600E+000, 0);
        _loc1[5] = new Array(0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 0, 0);
        _loc1[6] = new Array(0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0);
        _loc1[7] = new Array(0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, -1, 1, 0);
        _loc1[8] = new Array(0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 0);
        _loc1[9] = new Array(0, 0, 0, 0, 0, 1, 1, 4.110500E+000, 1, 0, 0, 0, 0, 0);
        _loc1[10] = new Array(0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0);
        return (_loc1);
    } // end if
    if (nr == 8)
    {
        startx = -80;
        starty = 130;
        _loc1[0] = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[1] = new Array(0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 0, 0, 0, 2, 2, 1);
        _loc1[2] = new Array(0, 0, 1, 2, 2, 0, 4.070300E+000, 2, 2, 4.070500E+000, 0, 0, 1, 2, 2, 1);
        _loc1[3] = new Array(0, 0, 2, 2, 2, 2, 2, 0, 2, 2, 0, 0, 0, 0, 2, 2, 0, 0, 4.120990E+000);
        _loc1[4] = new Array(0, 0, 0, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 2, 2, 2, 0, 2, 2);
        _loc1[5] = new Array(0, 0, 0, 2, 2, 1, 2, 0, 1, 2, 0, 0, 0, 2, 2, 1, 2, 2, 2);
        _loc1[6] = new Array(0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 0, 2, 2, 2, 0, 2, 2, 1);
        _loc1[7] = new Array(0, 0, 0, 2, 0, 2, 2, 1, 2, 2, 2, 0, 1, 2, 2, 4.120800E+000);
        _loc1[8] = new Array(0, 2, 2, 2, 0, 0, 4.070500E+000, 2, 2, 2, 1, 0, 0, 2);
        _loc1[9] = new Array(0, 2, 2, 1, 0, 0, 0, 2, 2, 2, 4.021000E+000, 0, 2, 2);
        _loc1[10] = new Array(0, 1, 0, 1, 1, 2, 2, 1, 0, 0, 0, 0, 0, 2, 2);
        _loc1[11] = new Array(3.150100E+000, 2, 2, 2, 0, 0, 0, 0, 0, 1, 2, 2, 2, -1, 2);
        _loc1[12] = new Array(0, 2, 2, 2, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2);
        _loc1[13] = new Array(0, 2, 2, 1, 2, 0, 0, 0, 0, 2, 2, 2, 1, 2, 2);
        return (_loc1);
    } // end if
    if (nr == 9)
    {
        startx = 60;
        starty = 100;
        _loc1[0] = new Array(0, 2, 0, 0, 0, 0, 0, 0, 0);
        _loc1[1] = new Array(1, 1, 1, 0, 0, 0, 1, 1, 1);
        _loc1[2] = new Array(1, 1, 1, 1, 1, 1, 1, 4, 1);
        _loc1[3] = new Array(1, 1, 1, 0, 0, 0, 3.030800E+000, 1, 1);
        _loc1[4] = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[5] = new Array(0, 0, 0, 3, 0, 0, 0, 0, 0);
        _loc1[6] = new Array(0, 0, 0, 2, 0, 0, 0, 0, 0);
        _loc1[7] = new Array(0, 0, 0, 2, 0, 0, 0, 0, 0, 1, 1, 0);
        _loc1[8] = new Array(4.110700E+000, 2, 2, 1, 2, 2, 4.090890E+000, 0, 0, 4.091000E+000, 1, 1);
        _loc1[9] = new Array(0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[10] = new Array(0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[11] = new Array(0, 0, 0, 3.090700E+000, 0, 0, 0, 0, 2, -1, 2);
        _loc1[12] = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0);
        return (_loc1);
    } // end if
    if (nr == 10)
    {
        startx = 0;
        starty = 110;
        _loc1[1] = new Array(1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[2] = new Array(1, 1, 1, 0, 0, 0, 0, 0, 2, 2, 2, 2, 0, 0, 0, 0);
        _loc1[3] = new Array(1, 1, 1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 0);
        _loc1[4] = new Array(1, 1, 0, 0, 0, 0, 2, 0, 2, 2, 0, 0, 2, 2);
        _loc1[5] = new Array(1, 1, 1, 1, 1, 2, 1, 2, 2, 2, 2, 0, 2, 2);
        _loc1[6] = new Array(1, 1, 1, 1, 1, 2, 1, 2, 3.130600E+000, 1, 2, 0, -1, 1);
        _loc1[7] = new Array(1, 1, 1, 1, 1, 2, 1, 2, 2, 2, 2, 0, 2, 2);
        _loc1[8] = new Array(1, 1, 0, 0, 0, 0, 2, 0, 2, 2, 0, 0, 2, 2);
        _loc1[9] = new Array(1, 1, 1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 0);
        _loc1[10] = new Array(1, 1, 1, 0, 0, 0, 0, 0, 2, 2, 2, 2, 0, 0, 0, 0);
        _loc1[11] = new Array(1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        return (_loc1);
    } // end if
    if (nr == 11)
    {
        startx = 10;
        starty = 150;
        _loc1[0] = new Array(0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0);
        _loc1[1] = new Array(2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4.000800E+000, 2, 2, 2);
        _loc1[2] = new Array(2, 2, 2, 2, 2, 4.010490E+000, 2, 2, 2, 2, 2, 2, 2, 2, 2);
        _loc1[3] = new Array(2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2);
        _loc1[4] = new Array(0, 2, 2, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2);
        _loc1[5] = new Array(0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 2, 2, 2);
        _loc1[6] = new Array(2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2);
        _loc1[7] = new Array(2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2);
        _loc1[8] = new Array(0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2);
        _loc1[9] = new Array(-1, 2, 2, 2, 2, 2, 2, 2, 4.110490E+000, 2, 2, 2, 2, 2, 2);
        _loc1[10] = new Array(2, 2, 2, 2, 0, 2, 2, 2, 2, 0, 2, 2, 2, 2, 2);
        return (_loc1);
    } // end if
    if (nr == 12)
    {
        startx = 10;
        starty = 150;
        _loc1[0] = new Array(0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1);
        _loc1[1] = new Array(0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1);
        _loc1[2] = new Array(1, 1, 1, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1);
        _loc1[3] = new Array(1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0);
        _loc1[4] = new Array(0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 1, 1, 1);
        _loc1[5] = new Array(0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1);
        _loc1[6] = new Array(1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1);
        _loc1[7] = new Array(1, -1, 1, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 0, 4.110100E+000);
        _loc1[8] = new Array(1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1);
        _loc1[9] = new Array(1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1);
        return (_loc1);
    } // end if
    if (nr == 13)
    {
        startx = 10;
        starty = 150;
        _loc1[0] = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[1] = new Array(0, 0, 4.040390E+000, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[2] = new Array(1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1);
        _loc1[3] = new Array(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3.010390E+000, 2);
        _loc1[4] = new Array(0, 4.020390E+000, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2);
        _loc1[5] = new Array(0, 0, 0, 0, 1, 2, 1, 2, 1, 0, 0, 0, 0, 0);
        _loc1[6] = new Array(0, 0, 0, 0, 1, -1, 1, 2, 1, 2, 0, 0, 0, 0);
        _loc1[7] = new Array(0, 0, 0, 0, 1, 2, 1, 2, 1, 0, 0, 0, 0, 0);
        return (_loc1);
    } // end if
    if (nr == 14)
    {
        startx = 10;
        starty = 150;
        _loc1[2] = new Array(1, 1, 1, 0, 0, 2, 1, 2, 1, 2, 1, 2, 1, 2);
        _loc1[3] = new Array(1, 1, 1, 1, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2);
        _loc1[4] = new Array(1, 1, 1, 1, 1, 1, 2, 1, 2, 1, 2, 1, 2, 4.060490E+000);
        _loc1[5] = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[6] = new Array(0, 0, 0, 0, 1, 2, 1, 2, 1, 0, 0, 0, 0, 0);
        _loc1[7] = new Array(0, 0, 0, 0, 1, -1, 1, 2, 1, 0, 0, 0, 0, 0);
        _loc1[8] = new Array(0, 0, 0, 0, 1, 2, 1, 2, 1, 0, 0, 0, 0, 0);
        _loc1[9] = new Array(0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0);
        return (_loc1);
    } // end if
    if (nr == 15)
    {
        startx = 10;
        starty = 150;
        _loc1[2] = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[3] = new Array(0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[4] = new Array(0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0);
        _loc1[5] = new Array(0, 0, 1, 1, 1, 1, 1, 1, 2, 2, 0, 0, 0, 0);
        _loc1[6] = new Array(0, 0, 1, 0, 0, 0, 0, 4.040300E+000, 2, 2, 0, 0, 0, 0);
        _loc1[7] = new Array(0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[8] = new Array(0, 0, 1, 0, 1, 1, 2, 0, 0, 0, 0, 0, 0, 0);
        _loc1[9] = new Array(0, 0, 1, 1, 1, 1, 2, 1, 2, 1, 2, 1, 0, 0);
        _loc1[10] = new Array(0, 0, 1, 1, 1, 1, 2, 1, 2, 1, 2, 1, 2, 0);
        _loc1[11] = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 1, 2);
        _loc1[12] = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 2);
        return (_loc1);
    } // end if
    if (nr == 16)
    {
        startx = 100;
        starty = 150;
        _loc1[0] = new Array(1, 2, 2, 4.020200E+000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _loc1[1] = new Array(2, 0, 2, 2, 0, 0, 2, 2, 0, 0, 0, 0, 0);
        _loc1[2] = new Array(2, 0, 0, 2, 0, 0, 2, 2, 0, 0, 0, 0, 0);
        _loc1[3] = new Array(0, 1, 1, 2, 1, 2, 1, 1, 2, 1, 0, 0, 0, 0);
        _loc1[4] = new Array(2, 0, 2, 0, 2, 2, 0, 0, 0, 2, 0, 0, 0, 0);
        _loc1[5] = new Array(2, 0, 2, 0, 0, 0, 2, 0, 0, 2, 2, -1, 0, 0);
        _loc1[6] = new Array(4.000300E+000, 2, 3.100600E+000, 1, 0, 0, 2, 2, 2, 4.060400E+000, 1, 2, 0, 0);
        _loc1[7] = new Array(0, 0, 0, 2, 2, 2, 1, 0, 0, 0, 2, 2, 0, 0);
        _loc1[8] = new Array(0, 0, 0, 4.030900E+000, 2, 2, 2, 0, 0, 0, 2, 1, 0, 0);
        _loc1[9] = new Array(0, 0, 0, 0, 0, 0, 2, 0, 2, 2, 1, 2, 2, 0);
        _loc1[10] = new Array(0, 0, 0, 2, 0, 0, 1, 1, 2, 2, 0, 2, 2, 4.111090E+000);
        _loc1[11] = new Array(0, 0, 0, 2, 0, 0, 0, 2, 2, 0, 0);
        _loc1[12] = new Array(0, 0, 0, 1, 2, 2, 1, 2, 2, 0, 0, 2);
        _loc1[13] = new Array(0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 2, 2);
        _loc1[14] = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 1);
        return (_loc1);
    } // end if
} // End of the function
function LevelCub(nr)
{
    if (nr == 1)
    {
        cub._x = startx;
        cub._y = starty;
        cubx = 0;
        cuby = 0;
    }
    else if (nr == 2)
    {
        cub._x = startx + 93;
        cub._y = starty - 1.650000E+001;
        cubx = 3;
        cuby = 0;
    }
    else if (nr == 3)
    {
        cub._x = startx + 11;
        cub._y = starty + 17;
        cubx = 0;
        cuby = 1;
    }
    else if (nr == 4)
    {
        cub._x = startx;
        cub._y = starty;
        cubx = 0;
        cuby = 0;
    }
    else if (nr == 5)
    {
        cub._x = startx + 62;
        cub._y = starty - 11;
        cubx = 2;
        cuby = 0;
    }
    else if (nr == 6)
    {
        cub._x = startx + 62;
        cub._y = starty - 11;
        cubx = 2;
        cuby = 0;
    }
    else if (nr == 7)
    {
        cub._x = startx + 31;
        cub._y = starty - 5.500000E+000;
        cubx = 1;
        cuby = 0;
    }
    else if (nr == 8)
    {
        cub._x = startx + 84;
        cub._y = starty + 25;
        cubx = 2;
        cuby = 2;
    }
    else if (nr == 9)
    {
        cub._x = startx + 53;
        cub._y = starty + 2.850000E+001;
        cubx = 1;
        cuby = 2;
    }
    else if (nr == 10)
    {
        cub._x = startx + 11;
        cub._y = starty + 17;
        cubx = 0;
        cuby = 1;
    }
    else if (nr == 11)
    {
        cub._x = startx + 137;
        cub._y = starty + 5.150000E+001;
        cubx = 3;
        cuby = 4;
    }
    else if (nr == 12)
    {
        cub._x = startx + 64;
        cub._y = starty + 4.550000E+001;
        cubx = 1;
        cuby = 3;
    }
    else if (nr == 13)
    {
        cub._x = startx + 64;
        cub._y = starty + 4.550000E+001;
        cubx = 1;
        cuby = 3;
    }
    else if (nr == 14)
    {
        cub._x = startx + 64;
        cub._y = starty + 4.550000E+001;
        cubx = 1;
        cuby = 3;
    }
    else if (nr == 15)
    {
        cub._x = startx + 64;
        cub._y = starty + 4.550000E+001;
        cubx = 1;
        cuby = 3;
    }
    else if (nr == 16)
    {
        cub._x = startx + 64;
        cub._y = starty + 4.550000E+001;
        cubx = 1;
        cuby = 3;
    } // end else if
} // End of the function
function DeseneazaLume()
{
    --jd;
    if (jd == -1)
    {
        ++id;
        jd = W;
    } // end if
    if (id == H)
    {
        this.onEnterFrame = DeseneazaCub;
        return;
    } // end if
    if (matrice[id][jd] >= 0)
    {
        demo_placa.duplicateMovieClip("placa" + id + "_" + jd, this.getNextHighestDepth());
        this["placa" + id + "_" + jd]._x = startx + jd * 31 + id * 11;
        this["placa" + id + "_" + jd]._y = starty + id * 17 - jd * 5.500000E+000;
        this["placa" + id + "_" + jd].tip.gotoAndStop(1 + int(matrice[id][jd]));
        this["placa" + id + "_" + jd].gotoAndPlay("apear");
    }
    else
    {
        demo_placa.duplicateMovieClip("placa" + id + "_" + jd, this.getNextHighestDepth());
        this["placa" + id + "_" + jd]._x = startx + jd * 31 + id * 11;
        this["placa" + id + "_" + jd]._y = starty + id * 17 - jd * 5.500000E+000;
        this["placa" + id + "_" + jd].tip.gotoAndStop(7);
        this["placa" + id + "_" + jd].gotoAndPlay("apear");
    } // end else if
    if (matrice[id][jd] == 0 || matrice[id][jd] == undefined)
    {
        DeseneazaLume();
    } // end if
} // End of the function
function DeseneazaCub()
{
    demo_cub.duplicateMovieClip("cub", this.getNextHighestDepth());
    cub.gotoAndPlay("apear");
    LevelCub(level);
    stage = 1;
    this.onEnterFrame = null;
    leveltime = new Date();
    z = setInterval(GameEngine, 30);
} // End of the function
function GameEngine()
{
    var _loc2 = new Date();
    _parent.timp.text = "Time: " + int((_loc2.getTime() - leveltime.getTime()) / 1000);
    _parent.moves.text = "Moves: " + levelmoves;
    if (cub.Static == false)
    {
        return;
    } // end if
    if (matrice[cuby][cubx] == 0 || matrice[cuby][cubx] == undefined)
    {
        EndLevel(1);
        return;
    } // end if
    if (stage == 1)
    {
        if (matrice[cuby][cubx] == 2)
        {
            efect._x = cub._x;
            efect._y = cub._y;
            cub.gotoAndPlay("end1");
            removeMovieClip ("_root.joc.placa" + cuby + "_" + cubx);
            efect.play();
            EndLevel(3);
            return;
        }
        else if (int(matrice[cuby][cubx]) == 3)
        {
            cubxt = int((matrice[cuby][cubx] - int(matrice[cuby][cubx])) * 100);
            cuby = Math.ceil(matrice[cuby][cubx] * 10000 - cubxt * 100 - 30000);
            cubx = cubxt;
            cub.gotoAndPlay("teleport");
            return;
        }
        else if (int(matrice[cuby][cubx]) == 4 && step == true && cub.Static == true)
        {
            cubxt = int((matrice[cuby][cubx] - int(matrice[cuby][cubx])) * 100);
            cubyt = Math.ceil(matrice[cuby][cubx] * 10000 - cubxt * 100 - 40000);
            if (int(matrice[cubyt][cubxt]) == 0)
            {
                matrice[cubyt][cubxt] = 5;
                _parent.joc["placa" + cubyt + "_" + cubxt].tip.gotoAndStop(6);
                _parent.joc["placa" + cubyt + "_" + cubxt].tip.lift.gotoAndPlay("apear");
            }
            else if (int(matrice[cubyt][cubxt]) == 5)
            {
                matrice[cubyt][cubxt] = 0;
                _parent.joc["placa" + cubyt + "_" + cubxt].tip.lift.gotoAndPlay("leave");
            } // end else if
            step = false;
        } // end else if
    } // end else if
    if (stage == 2)
    {
        if (matrice[cuby][cubx + 1] == 0 || matrice[cuby][cubx + 1] == undefined)
        {
            EndLevel(1);
            return;
        } // end if
    } // end if
    if (stage == 3)
    {
        if (matrice[cuby + 1][cubx] == 0 || matrice[cuby + 1][cubx] == undefined)
        {
            EndLevel(1);
            return;
        } // end if
    } // end if
    if (cub.Static == false)
    {
        return;
    } // end if
    if (Key.isDown(40))
    {
        if (stage == 1)
        {
            cub.gotoAndPlay("dropfront");
        }
        else if (stage == 2)
        {
            cub.gotoAndPlay("evROTS");
        }
        else if (stage == 3)
        {
            cub.gotoAndPlay("getupback");
        } // end else if
        ++levelmoves;
        cub.Static = false;
        step = true;
    } // end if
    if (Key.isDown(38))
    {
        if (stage == 1)
        {
            cub.gotoAndPlay("dropback");
        }
        else if (stage == 2)
        {
            cub.gotoAndPlay("evROTN");
        }
        else if (stage == 3)
        {
            cub.gotoAndPlay("getupfront");
        } // end else if
        ++levelmoves;
        cub.Static = false;
        step = true;
    } // end if
    if (Key.isDown(37))
    {
        if (stage == 1)
        {
            cub.gotoAndPlay("dropleft");
        }
        else if (stage == 2)
        {
            cub.gotoAndPlay("getupleft");
        }
        else if (stage == 3)
        {
            cub.gotoAndPlay("nsROTV");
        } // end else if
        ++levelmoves;
        cub.Static = false;
        step = true;
    } // end if
    if (Key.isDown(39))
    {
        if (stage == 1)
        {
            cub.gotoAndPlay("dropright");
        }
        else if (stage == 2)
        {
            cub.gotoAndPlay("getupright");
        }
        else if (stage == 3)
        {
            cub.gotoAndPlay("nsROTE");
        } // end else if
        ++levelmoves;
        cub.Static = false;
        step = true;
    } // end if
    if (matrice[cuby][cubx] == -1 && stage == 1)
    {
        efect._x = cub._x;
        efect._y = cub._y;
        cub.gotoAndPlay("end1");
        removeMovieClip ("_root.joc.placa" + cuby + "_" + cubx);
        efect.play();
        EndLevel(2);
    } // end if
} // End of the function
function EndLevel(rez)
{
    if (rez == 1)
    {
        exp.duplicateMovieClip("exp2", this.getNextHighestDepth());
        exp2._x = cub._x + 30;
        exp2._y = cub._y - 40;
        cub._alpha = 50;
        exp2.gotoAndPlay(2);
    }
    else if (rez == 2)
    {
        var _loc4 = new Date();
        _root.totaltime = _root.totaltime + int((_loc4.getTime() - leveltime.getTime()) / 1000);
        _root.totalmoves = _root.totalmoves + levelmoves;
        ++level;
    }
    else if (rez == 3)
    {
    } // end else if
    clearInterval(z);
    _parent.perdea.gotoAndPlay(1);
} // End of the function
maxlevel = _root.maxlevel;
step = true;
W = 18;
H = 15;
exp.stop();
stop ();
