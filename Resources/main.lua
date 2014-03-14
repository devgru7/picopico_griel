img="griel.png" --default texture 
pptex:default(pptex:load(img)) -- load texture  

-- 라이브러리 숏컷 
g=ppgraph
z=ppscreen:size()
sp=ppsprite
rand=math.random

r=pprect(0,0,30,30) -- collision box size  
scr=pprect(0,0,640,480)


mt="griel.png"  -- texture for map 
sp=ppsprite.new(mt) -- load texture  
mw=20   -- screen size 
mh=15
gw=16   -- map veiwing size 
gh=11

--init map obj 
m=ppmap.new()   
m:addLayer("layer1",mw,mh)  
m:addLayer("layer2",gw,gh)
m:texture(sp:texture())     
m:clip(0,0,gw,gh)           -- clipping 
m:tileSize(32,32)         -- 

m:layer("layer1")       

-- flooring 
function floor(i)
  for y=0,11,1 do
  for x=0,16,1 do
    m:tile(x,y,i)
  end
  end
end

-- load level data 
tst=require("level")

current=1 --current stage  

lvType=lvT[current] -- load level type  

floor(lvType+11)   -- draw map 

ofs=16 

-- count obj for level without floor  
obj=0
for i,v in ipairs(level[current]) do
  if v > 0 then
    obj=obj+1
  -- else if v>13 and v<17 then
    -- mst=mst+1
  end
end

-- sprite obj
wall=ppsprite.new(obj)


for k,v in pairs(wall) do
  v:tileSize(32)
end

-- spr obj for player character  
o=ppsprite.new() 

-- UI pillar 
pilla=ppsprite.new(2)
for k,v in pairs(pilla) do
  v.x = 416+(96*k)
  v.y = 64
  v:tile(25)
  g:append(v)
end


nof={0,0,0}
-- foe={}
ogre={}
slime={}
ghost={}
foes={ogre,slime,ghost}

-- init wall and enemy  

wi=1  --wall index 
for i,p in ipairs(level[current]) do
  if p>0 then 
    -- compute x,y from table  
    a=(i%16)
    b=(i-a)/16
    
    -- positioning and set collision  
    wall[wi].x= (a-1)*32   
    wall[wi].y= b*32
    wall[wi].hitmask=1
    wall[wi].hitrect=r

    -- indexing  
    if p==2 then            -- player 
      o.x=wall[wi].x
      o.y=wall[wi].y
      p=0
      dmy=wall[wi]      -- obj for player moving  
    elseif p==1 then    -- wall 
      p=lvType+19
    elseif p==4 then     -- closed door 
      door=wall[wi]
    elseif p>=6 and p<=11 then   -- monsters  
      if p==6 then 
        nof[1]=nof[1]+1 
        ogre[nof[1]]=wall[wi]
      end
      if p==8 then 
        nof[2]=nof[2]+1 
        slime[nof[2]]=wall[wi]
      end
      if p==10 then 
        nof[3]=nof[3]+1 
        ghost[nof[3]]=wall[wi]
      end
    end 

    -- set sprite  
    wall[wi]:tile(p)      
    
    -- sighn up collision obj  
    g:append(wall[wi])

    wi=wi+1
  end
end

-- player obj setting  
o.hitmask=1
o.hitrect=r
o:tile(2)
g:append(o)

-- effect setting 
efx=ppsprite:new()
efx.x=0
efx.y=0
efx:tile(26)
efx:disable()
g:append(efx)
 
-- game status machine 
status={} 
status.key=false 
status.item=0
status.inven=nil
status.stuck=false
status.tgt=nil 
status.kill=false 
status.count=0
status.freeze=false 

--virtual button
function button (t,x,y)
  local r
  r=pprect(x,y,62,62)  
  r.t=t              
  r.c=0
  r.pretouch=false     
  r.draw=function(s)   
    g:box(s)
    local t
    t=ppfont:size(s.t)
    t=g:layout(t,true,true,s)
    g:pos(t)
    g:print(s.t)
    t=pptouch()
    s:hitCheck(t)
    local ret=false
    if s.touch then
      s.c=s.c+1
      g:fill(s,g.red)
      if s.c>20 then
        s.c=1
        s.pretouch=false
      end
      if not s.pretouch
      then
        ret=true
      end
    else
      s.c=0
    end
    s.pretouch=s.touch
    return ret
  end
  return r
end

-- ppvkey:fixed(false)

-- set up buttons   
bx=512
by=352
bOff=64
bUp=button("UP",bx,by-bOff)
bLeft=button("LEFT",bx-bOff,by)
bDown=button("DOWN",bx,by)
bRight=button("RIGHT",bx+bOff,by)

-- game clear string 
btn=ppbutton("GAME CLEAR")
btn:layout(true,true,true)
btn.bgcolor=g.blue


function start()

  -- ppscreen:viewport(ppscreen:layout(scr))
  m:draw()

 
if pptouch() then   

  ppfont:set("mini")

-- o is real position, dmy is virtual position 
-- calc next position by key input 

  if bUp:draw() or ppkey.up(true) then
    dmy.x=o.x+0
    dmy.y=o.y+(-32)
  end
  if bLeft:draw() or ppkey.left(true) then
    dmy.x=o.x+(-32)
    dmy.y=o.y+0
  end
  if bDown:draw() or ppkey.down(true) then
    dmy.x=o.x+0
    dmy.y=o.y+32
  end
  if bRight:draw() or ppkey.right(true) then
    dmy.x=o.x+32
    dmy.y=o.y+0
  end

-- UI strings 

 ppfont:set("default")

  g:pos(512,16)
  g:print("Round "..current)
  g:pos(512,32)
  -- g:print(dmy.x..":"..dmy.y)
  g:pos(512,48)
  g:print("ITEM")

  g:pos(0,464)
  g:print("Copyright Compile/もものきはうす")

-- always check inside of map 
if (dmy.x >=0 and dmy.x <=512-32) and (dmy.y >=0 and dmy.y <=352-32) then

-- collision check and 

 pphitcheck (wall,{dmy},  
    function(a,b)

      local t=a:tile()  --what tile?  
      
      if t>=20 and t<=24 then   -- wall is stop   
        status.stuck=true 

      elseif t==27 then         -- get a key and doors open . 
        status.key=true
        a:disable()
        door:tile(5)

      elseif t>=17 and t<=19 then    -- items? 
        if status.item>0 then  -- already have? stop  
          status.stuck=true
        else
          status.item=t        -- nothing have? get an item  
          status.inven=a        -- show inventory  
          a:disable()
          a:pos(560,64)
          a:enable()
        end
      elseif (t>=6 and t<=11) then -- monsters? and have a matching item? 

        if (t==6 or t==7) and status.item==19 then  
          status.tgt=a
          status.kill=true
        elseif (t==8 or t==9) and status.item==17 then
          status.tgt=a
          status.kill=true
        elseif (t==10 or t==11) and status.item==18 then
          status.tgt=a
          status.kill=true
        else                     -- no item or didnt match 
          status.stuck=true
        end

      elseif t==4 then -- closed door 
        status.stuck=true

      elseif t==5 then -- opened door 
        g:append(btn)
        o:disable()         -- stage clear 
        status.freeze=true
      end  
      -- collision end. 

      -- kill monster 
      if status.kill then
        status.item=0           -- using item  

        status.inven:disable()  -- clear inven  
        status.inven=nil 

        efx.x=status.tgt.x       -- setting effect
        efx.y=status.tgt.y
        efx:enable()             -- effect flag on  
        status.count=10          -- effect showing time  
        
        status.tgt:disable()     -- target monster 
        status.tgt.x=512
        status.tgt.y=0
        status.tgt=nil

        status.stuck=true         -- 
        status.kill=false         --  
      end 

      --길에 막힘 
      if status.stuck then  
        dmy.x=o.x              -- previous position
        dmy.y=o.y
        status.stuck=false    
      end 

      if status.freeze then  
        dmy.x=o.x             -- fixed position
        dmy.y=o.y
      end 

    end
  )
 o.x=dmy.x   -- moving next position 
 o.y=dmy.y
end

end

  o:loopAnime(0.2,{2,3})  -- player animation  

  -- enemy animation 
  for i,v in ipairs(ogre) do
    v:loopAnime(0.2,{6,7})
  end  
  for i,v in ipairs(slime) do
    v:loopAnime(0.2,{8,9})
  end
  for i,v in ipairs(ghost) do
    v:loopAnime(0.2,{10,11})
  end  

  -- effect animation  
  if status.count>0 then
    status.count=status.count-1
    status.stuck=true
    efx:loopAnime(1,{26})
  else
    efx:disable()
    status.stuck=false
  end

end
