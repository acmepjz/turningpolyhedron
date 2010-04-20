// Action script...

// [onClipEvent of sprite 780 in frame 50]
onClipEvent (load)
{
    this.swapDepths(_parent.i + 4);
    _parent.landmask.swapDepths(_parent.i + 7);
    this.setMask(_parent.landmask);
}

// [onClipEvent of sprite 905 in frame 50]
onClipEvent (load)
{
    setProperty("", _visible, false);
    gotoAndPlay("land");
    this.swapDepths(_parent.i + 11);
    dir = "none";
    launchspeed = {up: [-3, 3], down: [3, 8], left: [-6, 5], right: [6, 0]};
    currently = "alive";
    xp = _parent.levels[level][10][0];
    yp = _parent.levels[level][10][1];
    reposition = function ()
    {
        setProperty("", _x, xStart + xp * xGap + yp * xShift);
        setProperty("", _y, yStart - xp * yShift + yp * yGap);
    };
    cancelselecta = function ()
    {
        if (selecta._currentframe < 30)
        {
            selecta.gotoAndPlay(30);
        } // end if
    };
    rejoinblocks = function (type, slip)
    {
        _global.selectedness = "block";
        setProperty("", _visible, false);
        _parent.block3._visible = false;
        _parent.shadowsandglow.blockshadow2._visible = false;
        _parent.shadowsandglow.blockshadow3._visible = false;
        _parent.block.xp = xp;
        _parent.block.yp = yp;
        if (type == "long")
        {
            if (!slip)
            {
                --_parent.block.xp;
            } // end if
            _parent.block.gotoAndPlay("longjoin");
        } // end if
        if (type == "far")
        {
            if (!slip)
            {
                ++_parent.block.yp;
            } // end if
            _parent.block.gotoAndPlay("farjoin");
        } // end if
    };
    overair2 = function (type, buttoncheck)
    {
        upsquare = _parent.levels[level][yp].charCodeAt(xp) > 47;
        doors = "lkrq";
        fremes = [40, 40, 130, 130];
        for (i = 0; i < 4; i++)
        {
            if (_parent.levels[level][yp].charAt(xp) == doors.charAt(i) && _parent["stone" + xp + "," + yp]._currentframe != fremes[i])
            {
                upsquare = false;
            } // end if
        } // end of for
        above = _parent.levels[level][yp].charAt(xp);
        changebackdir = false;
        if (dir == "none")
        {
            changebackdir = true;
            if (above == "l" || above == "k")
            {
                dir = "right";
            }
            else if (above == "r" || above == "q")
            {
                dir = "left";
            } // end if
        } // end else if
        if (!upsquare)
        {
            uptype = "none";
        }
        else
        {
            switch (above)
            {
                case "b":
                case "s":
                case "v":
                case "e":
                case "h":
                {
                    uptype = "stone";
                    break;
                } 
                case "f":
                {
                    uptype = "hollow";
                    break;
                } 
                case "l":
                case "r":
                case "k":
                case "q":
                {
                    uptype = "metal";
                    break;
                } 
            } // End of switch
        } // end else if
        if (upsquare)
        {
            gotoAndStop(type);
        }
        else
        {
            deptherised = false;
            currently = "falling";
            xs = launchspeed[dir][0];
            ys = launchspeed[dir][1];
            gotoAndPlay("fall" + dir);
        } // end else if
        if (_parent.levels[level][yp].charAt(xp) == "s" && buttoncheck)
        {
            _parent.clonk.gotoAndPlay("smallswitch");
            for (g = 0; g < _parent.levels[level][11]["swatch" + xp + "" + yp].length; g++)
            {
                tempathing = _parent.levels[level][11]["swatch" + xp + "" + yp][g];
                currentdoor = _parent["stone" + tempathing[0] + "," + tempathing[1]]._currentframe;
                if (tempathing[2] == "off" || tempathing[2] == "onoff" && (currentdoor == 40 || currentdoor == 130))
                {
                    _parent["stone" + tempathing[0] + "," + tempathing[1]].flasher.gotoAndPlay(2);
                } // end if
                if (tempathing[2] == "on" || tempathing[2] == "onoff" && (currentdoor == 33 || currentdoor == 123))
                {
                    _parent["stone" + tempathing[0] + "," + tempathing[1]].flasher.gotoAndPlay(22);
                } // end if
                if ((currentdoor == 33 || currentdoor == 123) && tempathing[2] != "off")
                {
                    _parent["stone" + tempathing[0] + "," + tempathing[1]].play();
                    continue;
                } // end if
                if ((currentdoor == 40 || currentdoor == 130) && tempathing[2] != "on")
                {
                    _parent["stone" + tempathing[0] + "," + tempathing[1]].play();
                } // end if
            } // end of for
        } // end if
        if (changebackdir)
        {
            dir = "none";
        } // end if
        if (yp == _parent.block3.yp && xp + 1 == _parent.block3.xp)
        {
            rejoinblocks("long", true);
        } // end if
        if (yp == _parent.block3.yp && xp - 1 == _parent.block3.xp)
        {
            rejoinblocks("long", false);
        } // end if
        if (yp - 1 == _parent.block3.yp && xp == _parent.block3.xp)
        {
            rejoinblocks("far", true);
        } // end if
        if (yp + 1 == _parent.block3.yp && xp == _parent.block3.xp)
        {
            rejoinblocks("far", false);
        } // end if
        if (uptype == "stone")
        {
            _parent.clonk2.gotoAndPlay("clonk");
        }
        else if (uptype == "metal")
        {
            _parent.clonk2.gotoAndPlay("metal");
        }
        else if (uptype == "hollow")
        {
            _parent.clonk2.gotoAndPlay("hollow");
        } // end else if
    };
    deptheriser = function ()
    {
        for (ypp = 0; ypp < 10; ypp++)
        {
            for (xpp = 14; xpp > -1; xpp--)
            {
                xp2 = xp;
                yp2 = yp;
                if (dir == "up")
                {
                    --yp2;
                }
                else if (dir == "down")
                {
                    yp2 = yp2 + 2;
                } // end else if
                if (ypp > yp2 || xpp < xp2)
                {
                    _parent["stone" + xpp + "," + ypp].swapDepths(_parent["stone" + xpp + "," + ypp].getDepth() + 200);
                    if (_parent.block3.xp == xpp && _parent.block3.yp == ypp)
                    {
                        _parent.block3.swapDepths(_parent.block3.getDepth() + 200);
                        _parent.landmask.swapDepths(_parent.landmask.getDepth() + 200);
                        _parent.shadowsandglow.swapDepths(_parent.shadowsandglow.getDepth() + 200);
                    } // end if
                } // end if
            } // end of for
        } // end of for
    };
    reposition();
}

// [onClipEvent of sprite 905 in frame 50]
onClipEvent (enterFrame)
{
    if (currently == "falling")
    {
        if (!deptherised)
        {
            deptherised = true;
            deptheriser();
        } // end if
        setProperty("", _x, _x + xs);
        setProperty("", _y, _y + ys);
        ys = ys + gravity;
    } // end if
    if (_y > 1000)
    {
        _parent.play();
        if (_parent._currentframe == 50)
        {
            _parent.block3.gotoAndPlay(105);
        } // end if
    } // end if
    if (selectedness == "block2")
    {
        if (Key.isDown(37) && !_parent.pauseness)
        {
            if (_currentframe == 1)
            {
                cancelselecta();
                ++_parent.moves;
                gotoAndPlay(2);
            } // end if
        } // end if
        if (Key.isDown(38) && !_parent.pauseness)
        {
            if (_currentframe == 1)
            {
                cancelselecta();
                ++_parent.moves;
                gotoAndPlay(12);
            } // end if
        } // end if
        if (Key.isDown(39) && !_parent.pauseness)
        {
            if (_currentframe == 1)
            {
                cancelselecta();
                ++_parent.moves;
                gotoAndPlay(22);
            } // end if
        } // end if
        if (Key.isDown(40) && !_parent.pauseness)
        {
            if (_currentframe == 1)
            {
                cancelselecta();
                ++_parent.moves;
                gotoAndPlay(32);
            } // end if
        } // end if
    } // end if
}

// [onClipEvent of sprite 1228 in frame 50]
onClipEvent (load)
{
    gotoAndPlay("land");
    this.swapDepths(_parent.i + 10);
    dir = "none";
    launchspeedroll = {up: [-3, 3], down: [3, 8], left: [-6, 5], right: [6, 0]};
    launchspeedhalf = {up: [-3, 3], down: [3, 8], left: [-6, 5], right: [6, 0]};
    launchspeedfull = {up: [-3, 3], down: [3, 8], left: [0, 5], right: [1, 0]};
    launchspeedtall = {up: [-3, 3], down: [3, 8], left: [-3, 5], right: [3, 0]};
    currently = "alive";
    _parent.detractor = true;
    xp = _parent.levels[level][10][0];
    yp = _parent.levels[level][10][1];
    reposition = function ()
    {
        setProperty("", _x, xStart + xp * xGap + yp * xShift);
        setProperty("", _y, yStart - xp * yShift + yp * yGap);
    };
    overair2 = function (type, buttoncheck)
    {
        upsquare = _parent.levels[level][yp].charCodeAt(xp) > 47;
        longsquare = _parent.levels[level][yp].charCodeAt(xp + 1) > 47;
        farsquare = _parent.levels[level][yp - 1].charCodeAt(xp) > 47;
        uptypetemp = _parent.levels[level][yp].charAt(xp);
        longtypetemp = _parent.levels[level][yp].charAt(xp + 1);
        fartypetemp = _parent.levels[level][yp - 1].charAt(xp);
        doors = "lkrq";
        fremes = [40, 40, 130, 130];
        for (i = 0; i < 4; i++)
        {
            if (_parent.levels[level][yp].charAt(xp) == doors.charAt(i) && _parent["stone" + xp + "," + yp]._currentframe != fremes[i])
            {
                upsquare = false;
            } // end if
            if (_parent.levels[level][yp].charAt(xp + 1) == doors.charAt(i) && _parent["stone" + Number(xp + 1) + "," + yp]._currentframe != fremes[i])
            {
                longsquare = false;
            } // end if
            if (_parent.levels[level][yp - 1].charAt(xp) == doors.charAt(i) && _parent["stone" + xp + "," + Number(yp - 1)]._currentframe != fremes[i])
            {
                farsquare = false;
            } // end if
        } // end of for
        if (!upsquare)
        {
            uptype = "none";
        }
        else
        {
            switch (uptypetemp)
            {
                case "b":
                case "s":
                case "v":
                case "h":
                {
                    uptype = "stone";
                    break;
                } 
                case "f":
                {
                    uptype = "hollow";
                    break;
                } 
                case "e":
                {
                    uptype = "none";
                    break;
                } 
                case "l":
                case "r":
                case "k":
                case "q":
                {
                    uptype = "metal";
                    break;
                } 
            } // End of switch
        } // end else if
        if (!farsquare)
        {
            fartype = "none";
        }
        else
        {
            switch (fartypetemp)
            {
                case "b":
                case "s":
                case "v":
                case "h":
                {
                    fartype = "stone";
                    break;
                } 
                case "f":
                {
                    fartype = "hollow";
                    break;
                } 
                case "e":
                {
                    fartype = "none";
                    break;
                } 
                case "l":
                case "r":
                case "k":
                case "q":
                {
                    fartype = "metal";
                    break;
                } 
            } // End of switch
        } // end else if
        if (!longsquare)
        {
            longtype = "none";
        }
        else
        {
            switch (longtypetemp)
            {
                case "b":
                case "s":
                case "v":
                case "h":
                {
                    longtype = "stone";
                    break;
                } 
                case "f":
                {
                    longtype = "hollow";
                    break;
                } 
                case "e":
                {
                    longtype = "none";
                    break;
                } 
                case "l":
                case "r":
                case "k":
                case "q":
                {
                    longtype = "metal";
                    break;
                } 
            } // End of switch
        } // end else if
        if (type == "long")
        {
            if (dir == "left" || dir == "right")
            {
                if (upsquare && longsquare)
                {
                    _parent.clonk.gotoAndPlay("clonk");
                    gotoAndStop(type);
                }
                else if (!upsquare && !longsquare)
                {
                    deptherised = false;
                    currently = "falling";
                    xs = launchspeedfull[dir][0];
                    ys = launchspeedfull[dir][1];
                    _parent.detractor = false;
                    gotoAndPlay("fall" + type + dir);
                }
                else
                {
                    deptherised = false;
                    currently = "falling";
                    xs = launchspeedhalf[dir][0];
                    ys = launchspeedhalf[dir][1];
                    gotoAndPlay("fall" + type + dir);
                } // end else if
            }
            else if (upsquare && longsquare)
            {
                gotoAndStop(type);
                _parent.clonk.gotoAndPlay("clonk");
            }
            else if (!upsquare && !longsquare)
            {
                deptherised = false;
                currently = "falling";
                xs = launchspeedroll[dir][0];
                ys = launchspeedroll[dir][1];
                gotoAndPlay("fall" + type + dir);
            }
            else if (!upsquare && longsquare)
            {
                deptherised = false;
                currently = "falling";
                xs = launchspeedhalf.left[0];
                ys = launchspeedhalf.left[1];
                dir = "left";
                gotoAndPlay("falllongleft");
            }
            else if (upsquare && !longsquare)
            {
                deptherised = false;
                currently = "falling";
                xs = launchspeedhalf.right[0];
                ys = launchspeedhalf.right[1];
                dir = "right";
                gotoAndPlay("falllongright");
            } // end else if
        } // end else if
        if (type == "far")
        {
            if (dir == "up" || dir == "down")
            {
                if (upsquare && farsquare)
                {
                    gotoAndStop(type);
                }
                else if (!upsquare && !farsquare)
                {
                    deptherised = false;
                    currently = "falling";
                    xs = launchspeedfull[dir][0];
                    ys = launchspeedfull[dir][1];
                    _parent.detractor = false;
                    gotoAndPlay("fall" + type + dir);
                }
                else
                {
                    deptherised = false;
                    currently = "falling";
                    xs = launchspeedhalf[dir][0];
                    ys = launchspeedhalf[dir][1];
                    gotoAndPlay("fall" + type + dir);
                } // end else if
            }
            else if (upsquare && farsquare)
            {
                gotoAndStop(type);
            }
            else if (!upsquare && !farsquare)
            {
                deptherised = false;
                currently = "falling";
                xs = launchspeedroll[dir][0];
                ys = launchspeedroll[dir][1];
                gotoAndPlay("fall" + type + dir);
            }
            else if (!upsquare && farsquare)
            {
                deptherised = false;
                currently = "falling";
                xs = launchspeedhalf.down[0];
                ys = launchspeedhalf.down[1];
                dir = "down";
                gotoAndPlay("fallfardown");
            }
            else if (upsquare && !farsquare)
            {
                deptherised = false;
                currently = "falling";
                xs = launchspeedhalf.up[0];
                ys = launchspeedhalf.up[1];
                dir = "up";
                gotoAndPlay("fallfarup");
            } // end else if
        } // end else if
        if (type == "up")
        {
            if (upsquare)
            {
                gotoAndStop(type);
            }
            else
            {
                deptherised = false;
                currently = "falling";
                _parent.detractor = false;
                xs = launchspeedtall[dir][0];
                ys = launchspeedtall[dir][1];
                gotoAndPlay("fall" + type + dir);
            } // end if
        } // end else if
        if (_parent.levels[level][yp].charAt(xp) == "e" && type == "up")
        {
            gotoAndPlay("end");
        }
        else if (_parent.levels[level][yp].charAt(xp) == "v" && type == "up")
        {
            gotoAndPlay("split");
        }
        else if (_parent.levels[level][yp].charAt(xp) == "f" && type == "up")
        {
            gotoAndPlay("fallsquare");
            _parent["stone" + xp + "," + yp].play();
            deptherised = false;
            currently = "falling";
            _parent.detractor = false;
            xs = 0;
            ys = 0;
        } // end else if
        if (buttoncheck)
        {
            for (h = 0; h < 2; h++)
            {
                xp3 = xp;
                yp3 = yp;
                if (type == "far" && h == 1)
                {
                    --yp3;
                }
                else if (type == "long" && h == 1)
                {
                    ++xp3;
                }
                else if (type == "up" && h == 1)
                {
                    break;
                } // end else if
                if (_parent.levels[level][yp3].charAt(xp3) == "s")
                {
                    _parent.clonk.gotoAndPlay("smallswitch");
                } // end if
                if (_parent.levels[level][yp3].charAt(xp3) == "h" && type == "up")
                {
                    _parent.clonk.gotoAndPlay("bigswitch");
                } // end if
                if (_parent.levels[level][yp3].charAt(xp3) == "s" || _parent.levels[level][yp3].charAt(xp3) == "h" && type == "up")
                {
                    for (g = 0; g < _parent.levels[level][11]["swatch" + xp3 + "" + yp3].length; g++)
                    {
                        tempathing = _parent.levels[level][11]["swatch" + xp3 + "" + yp3][g];
                        currentdoor = _parent["stone" + tempathing[0] + "," + tempathing[1]]._currentframe;
                        if (tempathing[2] == "off" || tempathing[2] == "onoff" && (currentdoor == 40 || currentdoor == 130))
                        {
                            _parent["stone" + tempathing[0] + "," + tempathing[1]].flasher.gotoAndPlay(2);
                        } // end if
                        if (tempathing[2] == "on" || tempathing[2] == "onoff" && (currentdoor == 33 || currentdoor == 123))
                        {
                            _parent["stone" + tempathing[0] + "," + tempathing[1]].flasher.gotoAndPlay(22);
                        } // end if
                        if ((currentdoor == 33 || currentdoor == 123) && tempathing[2] != "off")
                        {
                            _parent["stone" + tempathing[0] + "," + tempathing[1]].play();
                            continue;
                        } // end if
                        if ((currentdoor == 40 || currentdoor == 130) && tempathing[2] != "on")
                        {
                            _parent["stone" + tempathing[0] + "," + tempathing[1]].play();
                        } // end if
                    } // end of for
                } // end if
            } // end of for
            if (type == "up")
            {
                if (uptype == "stone")
                {
                    _parent.clonk.gotoAndPlay("clonk");
                }
                else if (uptype == "metal")
                {
                    _parent.clonk.gotoAndPlay("metal");
                }
                else if (uptype == "hollow")
                {
                    _parent.clonk.gotoAndPlay("hollow");
                } // end else if
            }
            else if (type == "long")
            {
                if (uptype == "stone" && longtype == "stone")
                {
                    _parent.clonk.gotoAndPlay("clonk");
                }
                else if (uptype == "metal" && longtype == "metal")
                {
                    _parent.clonk.gotoAndPlay("metal");
                }
                else if (uptype == "hollow" && longtype == "hollow")
                {
                    _parent.clonk.gotoAndPlay("hollow");
                }
                else
                {
                    if (uptype == "stone")
                    {
                        _parent.clonk.gotoAndPlay("half");
                    }
                    else if (uptype == "metal")
                    {
                        _parent.clonk.gotoAndPlay("halfmetal");
                    }
                    else if (uptype == "hollow")
                    {
                        _parent.clonk.gotoAndPlay("hollow");
                    } // end else if
                    if (longtype == "stone")
                    {
                        _parent.clonk2.gotoAndPlay("half");
                    }
                    else if (longtype == "metal")
                    {
                        _parent.clonk2.gotoAndPlay("halfmetal");
                    }
                    else if (longtype == "hollow")
                    {
                        _parent.clonk2.gotoAndPlay("hollow");
                    } // end else if
                } // end else if
            }
            else if (type == "far")
            {
                if (uptype == "stone" && fartype == "stone")
                {
                    _parent.clonk.gotoAndPlay("clonk");
                }
                else if (uptype == "metal" && fartype == "metal")
                {
                    _parent.clonk.gotoAndPlay("metal");
                }
                else if (uptype == "hollow" && fartype == "hollow")
                {
                    _parent.clonk.gotoAndPlay("hollow");
                }
                else
                {
                    if (uptype == "stone")
                    {
                        _parent.clonk.gotoAndPlay("half");
                    }
                    else if (uptype == "metal")
                    {
                        _parent.clonk.gotoAndPlay("halfmetal");
                    }
                    else if (uptype == "hollow")
                    {
                        _parent.clonk.gotoAndPlay("hollow");
                    } // end else if
                    if (fartype == "stone")
                    {
                        _parent.clonk2.gotoAndPlay("half");
                    }
                    else if (fartype == "metal")
                    {
                        _parent.clonk2.gotoAndPlay("halfmetal");
                    }
                    else if (fartype == "hollow")
                    {
                        _parent.clonk2.gotoAndPlay("hollow");
                    } // end else if
                } // end else if
            } // end else if
        } // end else if
    };
    deptheriser = function ()
    {
        for (ypp = 0; ypp < 10; ypp++)
        {
            for (xpp = 14; xpp > -1; xpp--)
            {
                xp2 = xp;
                yp2 = yp;
                if (dir == "up" && _parent.detractor)
                {
                    --yp2;
                }
                else if (dir == "down" && _parent.detractor)
                {
                    ++yp2;
                }
                else if (dir == "left" && _parent.detractor)
                {
                    --xp2;
                } // end else if
                if (ypp > yp2 || xpp < xp2)
                {
                    _parent["stone" + xpp + "," + ypp].swapDepths(_parent["stone" + xpp + "," + ypp].getDepth() + 200);
                } // end if
            } // end of for
        } // end of for
    };
    _parent.detractor = true;
    reposition();
}

// [onClipEvent of sprite 1228 in frame 50]
onClipEvent (keyDown)
{
    if (Key.isDown(32) && !_parent.pauseness)
    {
        if (_global.selectedness == "block3")
        {
            _parent.block2.selecta.gotoAndPlay(2);
            if (_parent.block3.selecta._currentframe < 30)
            {
                _parent.block3.selecta.gotoAndPlay(30);
            } // end if
            _global.selectedness = "block2";
        }
        else if (_global.selectedness == "block2")
        {
            _parent.block3.selecta.gotoAndPlay(2);
            if (_parent.block2.selecta._currentframe < 30)
            {
                _parent.block2.selecta.gotoAndPlay(30);
            } // end if
            _global.selectedness = "block3";
        } // end if
    } // end else if
}

// [onClipEvent of sprite 1228 in frame 50]
onClipEvent (enterFrame)
{
    if (selectedness == "block")
    {
        if (currently == "falling")
        {
            if (!deptherised)
            {
                deptherised = true;
                deptheriser();
            } // end if
            setProperty("", _x, _x + xs);
            setProperty("", _y, _y + ys);
            ys = ys + gravity;
        } // end if
    } // end if
    pb2x = _parent.block2.xp;
    pb2y = _parent.block2.yp;
    pb3x = _parent.block3.xp;
    pb3y = _parent.block3.yp;
    if (_parent.block2._currentframe > 11 && _parent.block2._currentframe < 21)
    {
        --pb2y;
    } // end if
    if (_parent.block3._currentframe > 11 && _parent.block3._currentframe < 21)
    {
        --pb3y;
    } // end if
    if (_parent.block2._currentframe > 31 && _parent.block2._currentframe < 41)
    {
        ++pb2y;
    } // end if
    if (_parent.block3._currentframe > 31 && _parent.block3._currentframe < 41)
    {
        ++pb3y;
    } // end if
    if (pb2y != pb3y)
    {
        if (pb2y < pb3y == _parent.block2.getDepth() > _parent.block3.getDepth())
        {
            _parent.block2.swapDepths(_parent.block3);
        } // end if
    }
    else if (pb2x > pb3x == _parent.block2.getDepth() > _parent.block3.getDepth())
    {
        _parent.block2.swapDepths(_parent.block3);
    } // end else if
    if (Key.isDown(37) && !_parent.pauseness)
    {
        if (_currentframe == 1)
        {
            gotoAndPlay(2);
            ++_parent.moves;
        } // end if
        if (_currentframe == 41)
        {
            gotoAndPlay(42);
            ++_parent.moves;
        } // end if
        if (_currentframe == 81)
        {
            gotoAndPlay(82);
            ++_parent.moves;
        } // end if
    } // end if
    if (Key.isDown(38) && !_parent.pauseness)
    {
        if (_currentframe == 1)
        {
            gotoAndPlay(12);
            ++_parent.moves;
        } // end if
        if (_currentframe == 41)
        {
            gotoAndPlay(52);
            ++_parent.moves;
        } // end if
        if (_currentframe == 81)
        {
            gotoAndPlay(92);
            ++_parent.moves;
        } // end if
    } // end if
    if (Key.isDown(39) && !_parent.pauseness)
    {
        if (_currentframe == 1)
        {
            gotoAndPlay(22);
            ++_parent.moves;
        } // end if
        if (_currentframe == 41)
        {
            gotoAndPlay(62);
            ++_parent.moves;
        } // end if
        if (_currentframe == 81)
        {
            gotoAndPlay(102);
            ++_parent.moves;
        } // end if
    } // end if
    if (Key.isDown(40) && !_parent.pauseness)
    {
        if (_currentframe == 1)
        {
            gotoAndPlay(32);
            ++_parent.moves;
        } // end if
        if (_currentframe == 41)
        {
            gotoAndPlay(72);
            ++_parent.moves;
        } // end if
        if (_currentframe == 81)
        {
            gotoAndPlay(112);
            ++_parent.moves;
        } // end if
    } // end if
    if (_y > 1000)
    {
        _parent.play();
    } // end if
}

// [onClipEvent of sprite 905 in frame 50]
onClipEvent (load)
{
    setProperty("", _visible, false);
    gotoAndPlay("land");
    this.swapDepths(_parent.i + 12);
    dir = "none";
    launchspeed = {up: [-3, 3], down: [3, 8], left: [-6, 5], right: [6, 0]};
    currently = "alive";
    xp = _parent.levels[level][10][0];
    yp = _parent.levels[level][10][1];
    reposition = function ()
    {
        setProperty("", _x, xStart + xp * xGap + yp * xShift);
        setProperty("", _y, yStart - xp * yShift + yp * yGap);
    };
    cancelselecta = function ()
    {
        if (selecta._currentframe < 30)
        {
            selecta.gotoAndPlay(30);
        } // end if
    };
    rejoinblocks = function (type, slip)
    {
        _global.selectedness = "block";
        setProperty("", _visible, false);
        _parent.block2._visible = false;
        _parent.shadowsandglow.blockshadow2._visible = false;
        _parent.shadowsandglow.blockshadow3._visible = false;
        _parent.block.xp = xp;
        _parent.block.yp = yp;
        if (type == "long")
        {
            if (!slip)
            {
                --_parent.block.xp;
            } // end if
            _parent.block.gotoAndPlay("longjoin");
        } // end if
        if (type == "far")
        {
            if (!slip)
            {
                ++_parent.block.yp;
            } // end if
            _parent.block.gotoAndPlay("farjoin");
        } // end if
    };
    overair2 = function (type, buttoncheck)
    {
        upsquare = _parent.levels[level][yp].charCodeAt(xp) > 47;
        fremes = [40, 40, 130, 130];
        doors = "lkrq";
        for (i = 0; i < 4; i++)
        {
            if (_parent.levels[level][yp].charAt(xp) == doors.charAt(i) && _parent["stone" + xp + "," + yp]._currentframe != fremes[i])
            {
                upsquare = false;
            } // end if
        } // end of for
        above = _parent.levels[level][yp].charAt(xp);
        changebackdir = false;
        if (dir == "none")
        {
            changebackdir = true;
            if (above == "l" || above == "k")
            {
                dir = "right";
            }
            else if (above == "r" || above == "q")
            {
                dir = "left";
            } // end if
        } // end else if
        if (!upsquare)
        {
            uptype = "none";
        }
        else
        {
            switch (above)
            {
                case "b":
                case "s":
                case "v":
                case "e":
                case "h":
                {
                    uptype = "stone";
                    break;
                } 
                case "f":
                {
                    uptype = "hollow";
                    break;
                } 
                case "l":
                case "r":
                case "k":
                case "q":
                {
                    uptype = "metal";
                    break;
                } 
            } // End of switch
        } // end else if
        if (upsquare)
        {
            gotoAndStop(type);
        }
        else
        {
            deptherised = false;
            currently = "falling";
            xs = launchspeed[dir][0];
            ys = launchspeed[dir][1];
            gotoAndPlay("fall" + dir);
        } // end else if
        if (_parent.levels[level][yp].charAt(xp) == "s" && buttoncheck)
        {
            _parent.clonk.gotoAndPlay("smallswitch");
            for (g = 0; g < _parent.levels[level][11]["swatch" + xp + "" + yp].length; g++)
            {
                tempathing = _parent.levels[level][11]["swatch" + xp + "" + yp][g];
                currentdoor = _parent["stone" + tempathing[0] + "," + tempathing[1]]._currentframe;
                if (tempathing[2] == "off" || tempathing[2] == "onoff" && (currentdoor == 40 || currentdoor == 130))
                {
                    _parent["stone" + tempathing[0] + "," + tempathing[1]].flasher.gotoAndPlay(2);
                } // end if
                if (tempathing[2] == "on" || tempathing[2] == "onoff" && (currentdoor == 33 || currentdoor == 123))
                {
                    _parent["stone" + tempathing[0] + "," + tempathing[1]].flasher.gotoAndPlay(22);
                } // end if
                if ((currentdoor == 33 || currentdoor == 123) && tempathing[2] != "off")
                {
                    _parent["stone" + tempathing[0] + "," + tempathing[1]].play();
                    continue;
                } // end if
                if ((currentdoor == 40 || currentdoor == 130) && tempathing[2] != "on")
                {
                    _parent["stone" + tempathing[0] + "," + tempathing[1]].play();
                } // end if
            } // end of for
        } // end if
        if (changebackdir)
        {
            dir = "none";
        } // end if
        if (yp == _parent.block2.yp && xp + 1 == _parent.block2.xp)
        {
            rejoinblocks("long", true);
        } // end if
        if (yp == _parent.block2.yp && xp - 1 == _parent.block2.xp)
        {
            rejoinblocks("long", false);
        } // end if
        if (yp - 1 == _parent.block2.yp && xp == _parent.block2.xp)
        {
            rejoinblocks("far", true);
        } // end if
        if (yp + 1 == _parent.block2.yp && xp == _parent.block2.xp)
        {
            rejoinblocks("far", false);
        } // end if
        if (uptype == "stone")
        {
            _parent.clonk.gotoAndPlay("clonk");
        }
        else if (uptype == "metal")
        {
            _parent.clonk.gotoAndPlay("metal");
        }
        else if (uptype == "hollow")
        {
            _parent.clonk.gotoAndPlay("hollow");
        } // end else if
    };
    deptheriser = function ()
    {
        for (ypp = 0; ypp < 10; ypp++)
        {
            for (xpp = 14; xpp > -1; xpp--)
            {
                xp2 = xp;
                yp2 = yp;
                if (dir == "up")
                {
                    --yp2;
                }
                else if (dir == "down")
                {
                    yp2 = yp2 + 2;
                } // end else if
                if (ypp > yp2 || xpp < xp2)
                {
                    _parent["stone" + xpp + "," + ypp].swapDepths(_parent["stone" + xpp + "," + ypp].getDepth() + 200);
                    if (_parent.block2.xp == xpp && _parent.block2.yp == ypp)
                    {
                        _parent.block2.swapDepths(_parent.block2.getDepth() + 200);
                        _parent.landmask.swapDepths(_parent.landmask.getDepth() + 200);
                        _parent.shadowsandglow.swapDepths(_parent.shadowsandglow.getDepth() + 200);
                    } // end if
                } // end if
            } // end of for
        } // end of for
    };
    reposition();
}

// [onClipEvent of sprite 905 in frame 50]
onClipEvent (enterFrame)
{
    if (currently == "falling")
    {
        if (!deptherised)
        {
            deptherised = true;
            deptheriser();
        } // end if
        setProperty("", _x, _x + xs);
        setProperty("", _y, _y + ys);
        ys = ys + gravity;
    } // end if
    if (_y > 1000)
    {
        _parent.play();
        if (_parent._currentframe == 50)
        {
            _parent.block2.gotoAndPlay(105);
        } // end if
    } // end if
    if (selectedness == "block3")
    {
        if (Key.isDown(37) && !_parent.pauseness)
        {
            if (_currentframe == 1)
            {
                gotoAndPlay(2);
                ++_parent.moves;
                cancelselecta();
            } // end if
        } // end if
        if (Key.isDown(38) && !_parent.pauseness)
        {
            if (_currentframe == 1)
            {
                ++_parent.moves;
                gotoAndPlay(12);
                cancelselecta();
            } // end if
        } // end if
        if (Key.isDown(39) && !_parent.pauseness)
        {
            if (_currentframe == 1)
            {
                ++_parent.moves;
                gotoAndPlay(22);
                cancelselecta();
            } // end if
        } // end if
        if (Key.isDown(40) && !_parent.pauseness)
        {
            if (_currentframe == 1)
            {
                cancelselecta();
                ++_parent.moves;
                gotoAndPlay(32);
            } // end if
        } // end if
    } // end if
}

// [onClipEvent of sprite 1255 in frame 50]
onClipEvent (enterFrame)
{
    this.swapDepths(10000);
}

// [Action in Frame 50]
stop ();
