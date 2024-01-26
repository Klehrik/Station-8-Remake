pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- bigmap v1.2
--  BY PANCELOR

-- for editing maps in 0.2.4+

printh"====="

-- helper.lua

function arr0(zero,arr)
 arr[0]=zero
 return arr
end

dirx=arr0(-1,split"1,0,0,1,1,-1,-1")
diry=arr0(0,split"0,-1,1,-1,1,1,-1")

shadow=split"0,5,1,2,1,13,6,2,4,9,3,13,5,13,6"

function approach(x,target,delta)
 delta=delta or 1
 return x<target and min(x+delta,target) or max(x-delta,target)
end
function lerp(a,b,t) return a+(b-a)*t end
function remap(x,a,b,u,v) return u+(v-u)*(x-a)/(b-a) end

function cycle(period)
 return time()%period/period
end
function pulse(v0,dur0,v1,dur1)
 return time()%(dur0+dur1)<dur0 and v0 or v1
end

function qq(...)
 local args=pack(...)
 local s=""
 for i=1,args.n do
  s..=quote(args[i]).." "
 end
 return s
end
function pq(...) printh(qq(...)) end

function quote(t,sep)
 if type(t)~="table" then return tostr(t) end

 local s="{"
 for k,v in pairs(t) do
  s..=(type(k)=="table" and k.base and "<"..k.base.name..">") or tostr(k)
  if k=="base" then
   s..="=<"..tostr(v and v.name)..">"
  else
   s..="="..quote(v)
  end
  s..=sep or ","
 end
 return s.."}"
end

hex=arr0("0",split("123456789abcdef","",false))

function strwidth(str)
 return print(str,0,0x4000)
end

function ospr(s,x,y, c, n)
 local paldata=pack(peek(0x5f00,16))
 for i=0,15 do
  pal(i,c or 0)
 end
 for i=0,(n or 8)-1 do
  spr(s,x+dirx[i],y+diry[i])
 end
 poke(0x5f00,unpack(paldata))
 spr(s,x,y)
end

function tohex(x)
 return tostr(x,1)
end

function tobin(x, h,l)
 h=h or 8
 l=l or -8
 local s="0b"
 for i=h-1,l,-1 do
  if(i==-1)s..="."
  s..=(x>>i)&1
 end
 return s
end

_last_ust_time=-1
function upd_screenshot_title(name)
 if time()-_last_ust_time>=1 then
  _last_ust_time=time()
  extcmd("set_filename",(name or "pico8")..datestamp())
 end
end

function datestamp()
 local function f(s,n) return leftpadnum(stat(s),n) end
 return f(90,4).."_"..f(91,2).."_"..f(92,2).."t"..f(93,2).."_"..f(94,2).."_"..f(95,2)
end

f_id=function(x) return x end

function merge_into(obj,...)
 for t in all{...} do
  for k,v in pairs(t) do
   obj[k]=v
  end
 end
 return obj
end
function merge(...)
 return merge_into({},...)
end

clone=merge

function parse_into(obj,str, mapper)
 for str2 in all(split(str)) do
  local parts=split(str2,"=")
  if #parts==2 then
   local k,v=unpack(parts)
   obj[k]=mapper and mapper(k,v) or v
  else
   add(obj,str2)
  end
 end
 return obj
end
function parse(...)
 return parse_into({},...)
end

function argmax(arr, f)
 f=f or f_id
 local besti,best=1,arr[1]
 for i=2,#arr do
  local now=f(arr[i])
  if now>best then
   best=now
   besti=i
  end
 end
 return besti,best
end



-- toast.lua

_toast={t=0,t0=180}
function toast(msg, fg,bg,t)
 _toast.msg=msg
 _toast.fg=fg or 10
 _toast.bg=bg or col_menu
 t=t or 180
 _toast.t0=t
 _toast.t=t
end
function do_toast()
 if _toast.t>0 then _toast.t-=1 end
 local t=remap(_toast.t,
  _toast.t0,0,
  0,14)
 t=mid(0,1,7-abs(t-7)) --plateau
 local y=lerp(128,121,t)
 rectfill(0,y,127,y+6,_toast.bg)
 print(_toast.msg,1,y+1,_toast.fg)
end



--imp.lua

function imp_area(id,x0,y0,x1,y1, col)
  if col then rectfill(x0,y0,x1,y1,col) end

  local widget,is_new=imp_get(id)
  if is_new then
    widget.held=0
    widget.unblurred=0
  end

  widget.pressed=0
  widget.hovering,widget.overlapping=imp_hover(id,x0,y0,x1,y1)
  if widget.hovering then
    widget.pressed=_imp_btn&~_imp_btn_last
    widget.unblurred|=widget.pressed
    widget.held|=widget.pressed
  else
    widget.unblurred=0
  end
  widget.released=widget.held&~_imp_btn
  widget.held^^=widget.released -- clear bits from mbtnr
  return widget,is_new
  --[[
  * widget.overlapping (bool) - if the mouse currently overlaps the widget's bounding box
  * widget.hovering (bool) - if the widget is the first widget the mouse is currently hovering above
  * widget.pressed / held / released - bitfields of mouse buttons pressed/etc
    that *start* in the imp_area's bounding box
  * widget.unblurred - bitfield; normally a subset of .held that has buttons that haven't
    left the hitbox since they were pressed
    (this does NOT get cleared on button release, so that you can mask it
    against .released to see which releases were unblurred.
    so, it's not _always_ a subset of .held)
  * feel free to attach other temporary data to widget;
    it will persist until the widget isn't called for a frame
    (standard imp unloading)
  ]]
end

function imp_textbox(x,y,w,id,on,val)
  local h=7
  local x1,y1=x+w-1,y+h-1
  local widget,is_new=imp_area(id,x,y,x1,y1,0)
  widget.done=false

  if mbtnp()>0 and not widget.overlapping then
    widget.done,widget.typing,widget.selectall=widget.typing
  end
  if widget.hovering then
    _imp_cursor=mbtn(0) and 2 or 1
    if mbtnp(0) then
      widget.typing=true
      widget.selectall=not widget.selectall
    end
  end
  if widget.typing then
    _imp_any_textbox=true
    if kbbksp then
      widget.text=sub(widget.text,1,#widget.text-1)
    end
    if widget.selectall and #kbtext>0 then
      widget.text,widget.selectall=""
    end
    widget.text..=kbtext
    if kbenter then
      widget.done,widget.typing=true
      kbenter_used=true --hacky
    end
  elseif not widget.done then
    widget.text=tostr(val)
  end
  -- draw
  local clipdat=pack(clip(x,y,w,h))
  local toprint,xp,yp=widget.text,x1-strwidth(widget.text)+1,y+1
  if widget.selectall then
    rectfill(xp-1,yp-1,x1,y1,12)
  elseif widget.typing then
    xp-=4
    toprint..=cycle(.5)<.5 and " \f8\-ch\-ci" or ""
  end
  print(toprint,xp,yp,7)
  if widget.hovering then
    rect(x,y,x1,y1,widget.typing and 1 or 6)
  end
  clip(unpack(clipdat))

  return widget
end

--[[
# buttons
seems like imp_btnspr isn't general enough? all these similar things are a bit annoying
--]]

function imp_btnspr_tab(s,x,y,id,on, opts)
  opts=opts or {}
  opts.palpress=parse"8=7,9=6"
  opts.palnormal=parse"7=6,8=13"

  local widget=imp_area(id,x,y,x+8,y+8)
  local held,released=widget.held&widget.unblurred&1>0,widget.released&widget.unblurred&1>0

  if held then
    _imp_cursor=2
  elseif widget.hovering then
    _imp_cursor=1
  end

  -- draw
  clip(x,y-1,8,8)
  if held or released or on then
    if opts.palpress then pal(opts.palpress) end
    y-=1
  else
    pal(opts.palnormal)
  end
  spr(s,x,y)
  pal()
  clip()

  return released
end
function imp_btnspr_red(s,x,y,id,on,st)
  local res=imp_btnspr(s,x,y,id,on,{palhover=parse"2=15", palpress=parse"2=10"})
  if _imp_hover==id then
    status=st --leaky
  end
  return res
end
function imp_btnspr_tool(s,x,y,id,on,st)
  local widget=imp_area(id,x,y,x+7,y+7)
  local held,released=widget.held&widget.unblurred&1>0,widget.released&widget.unblurred&1>0

  if held then
    _imp_cursor=2
  elseif widget.hovering then
    _imp_cursor=1
  end

  if _imp_hover==id then
    status=st --leaky
  end

  -- draw
  if on or held or released then pal(13,7) end
  spr(s,x,y)
  pal()

  return released
end


-- how to have disabled buttons?
-- "on" here doesn't do much; you could just pass a different palette...
function imp_btnspr(s,x,y,id,on, opts)
  opts=opts or {}
  local widget=imp_area(id,x,y,x+7,y+7)
  local held,released=widget.held&widget.unblurred&1>0,widget.released&widget.unblurred&1>0

  if held then
    _imp_cursor=2
  elseif widget.hovering then
    _imp_cursor=1
  end

  -- draw
  if opts.palhover and (on or widget.hovering) then pal(opts.palhover) end
  if held or released then
    if opts.palpress then pal(opts.palpress) end
    if opts.shift then x+=opts.shift[1] y+=opts.shift[2] end
  end
  spr(s,x,y) -- todo margin? eh, just pad your sprite image maybe
  pal()

  return released
end

-- TODO: generalize?
function imp_btntext(text,x,y,id,on)
  local w=strwidth(text)+3
  local widget=imp_area(id,x,y,x+w-1,y+7)
  local held,released=widget.held&widget.unblurred&1>0,widget.released&widget.unblurred&1>0

  if held then
    _imp_cursor=2
  elseif widget.hovering then
    _imp_cursor=1
  end

  -- draw
  local c=6
  if on or widget.hovering then c=14 end
  if held or released then c=15 end
  print(text,x+2,y+1,c)

  return released
end

--[[
# imp core
--]]

_imp_widgets={}
_imp_btn=0 -- TODO use this for real (to prevent softlock bugs when FPS degrades)
-- _imp_cursor (int)
-- _imp_hover,_imp_hover_last
function imp_begin()
  _imp_cursor=0 --0=normal cursor 1=hovering finger 2=click/drag fist
  _imp_any_textbox=nil -- hacky but works for now
  _imp_hover_last,_imp_hover=_imp_hover
  for id,widget in pairs(_imp_widgets) do
    -- release widgets that weren't used last frame
    if widget.dying then
      _imp_widgets[id]=nil
    end

    -- set flag (to check next frame)
    widget.dying=true
  end
  _imp_btn,_imp_btn_last=stat(34),_imp_btn
end
function imp_get(id)
  local is_new=not _imp_widgets[id]
  if is_new then
    _imp_widgets[id]={id=id}
  elseif dev then
    -- todo: remove this; it's nice for dev but not for players
    assert(_imp_widgets[id].dying,"imp detected non-unique id: "..id)
  end
  _imp_widgets[id].dying=nil
  return _imp_widgets[id],is_new
end
function imp_hover(id,x0,y0,x1,y1)
  -- simple aabb bounds check (inclusive)
  -- also respects clip() rectangle.
  local overlapping =
    x0<=mx and mx<=x1 and y0<=my and my<=y1
    and @0x5f20<=mx and mx<0x5f22 and @0x5f21<=my and my<0x5f23

  -- additionally, keeps track of _imp_hover
  -- to test if your widget was the last hovered widget last frame,
  --   (e.g. in a stack of multiple widgets)
  --   test _imp_hover_last==id
  if overlapping then _imp_hover=id end
  return _imp_hover_last==id,overlapping
end
function imp_end()
  -- draw mouse
  ospr(13+_imp_cursor,mx-2,my,1,4)
end



poke(0x5f2d,1)

-- mouse keycodes: (b)
--  lmb=0,rmb=1,mmb=2
function mbtn(b)  return _btn_helper(_mbtn, b) end
function mbtnp(b) return _btn_helper(_mbtnp,b) end
function mbtnr(b) return _btn_helper(_mbtnr,b) end
function _btn_helper(bits,b)
  return not b and bits or bits>>b&1>0
end

--[[
# implementation details
--]]

_mbtn_last,_mbtn,_mbtnp,_mbtnr=unpack(split"0,0,0,0")
mx,my=stat(32),stat(33)
--mpx,mpy

-- call this at the start of _update()
function upd_mouse()
  _mbtn,mpx,mpy,mx,my,mwheel=stat(34),mx,my,stat(32),stat(33),stat(36)
  _mbtnp,_mbtnr,_mbtn_last=_mbtn&~_mbtn_last,_mbtn_last&~_mbtn,_mbtn
end

-- call during _update()
function upd_keyboard()
 kbenter_used=nil -- hacky
 kbtext,kbenter,kbbksp,kbesc,kbshift,kbctrl,kbcopy,kbpaste=""
 while stat(30) do
  local k=stat(31)
  local ordk=ord(k)
  kbshift=kbshift or ordk&0xc0==0x80
  kbctrl=kbctrl or ordk&0xc0==0xc0

  if ordk==27 then
   --escape
   kbesc=true
  elseif ordk==10 or ordk==13 then
   kbenter=true
   poke(0x5f30,1)
  elseif ordk==8 then
   kbbksp=true
  elseif kbctrl then
   if ordk==194 then
    kbcopy=true
   elseif ordk==213 then
    kbpaste=true
   end
  else
   if kbshift then
    -- capital letters
    kbtext..=chr(ordk+65-128)
   else
    kbtext..=k
   end
  end
 end
end



-- basic.lua

col_menu=9
col_bkg=1

--[[
## memory addresses used

* startup:
  * 0x5500..0x5503: signal from parent cart to load sprites / set focusx / set focusy
  * 0x8000..0xa000: sprites from parent
* running:
  * 0x4300..0x5100: store ui sprites / cart sprites
  * 0x8000..<0xa000(?): map draw cache
]]

function _init()
  parentp8=stat(6)
  if #parentp8==0 then parentp8=nil end
  pq("bigmap.p8 args: ",parentp8)

  memcpy(0x4300,0,0x400) -- save ui sprites
  if parentp8 then
    -- pq"loading parent sprites..."
    if @0x5500>0 then
      -- pq"fast loading sprites"
      memcpy(0x0000,0x8000,0x2000)
    else
      -- pq"slow loading sprites"
      reload(0,0,0x2000,parentp8)
    end
  end
  memcpy(0x4700,0,0x400) -- save parent sprites

  brush=make_brush()
  mode_brush="tool_draw"
  last_autosave=0
  btnex_last=0
  ini_map()
  precalc_lods()
  if parentp8 and @0x5500>0 then
    focusx=@0x5501
    focusy=@0x5502
    poke(0x5500,0)
  end
end

function _draw()
  imdrw()
  do_toast()
end

--[[
# game scene
--]]

-- todo: cache instead of precalc? doesn't matter for now
function precalc_lods()
  lodz=8 --size
  poke(0x5f34,1)
  lods={}
  for s=0,255 do
    local sx0,sy0=s%16*8,s\16*8
    local cnt={} for i=1,16 do add(cnt,0) end --needs to be 1-indexed for argmax to work
    for dy=0,7 do
      for dx=0,7 do
        local p=sget(sx0+dx,sy0+dy)
        cnt[p+1]+=1
      end
    end
    local i1=argmax(cnt)
    cnt[i1]=0
    local i2,n=argmax(cnt)
    if n==0 then i2=i1 end
    lods[s]=0x1000|(i1-1)*16|(i2-1)|(▒>><16)
  end
end
function sprlod(s,x,y)
  local ld=lods[s]
  if lodz==8 and ld&0xff>0 then
    spr(s,x,y)
  else
    if ld&0xff==0 then ld|=1 end
    rectfill(x,y,x+lodz-1,y+lodz-1,ld)
  end
end

update_ready=true --imgui degraded fps mode workaround
function _update60()
  if update_ready then
    update_ready=false
    upd_mouse()
    upd_keyboard()
    upd_screenshot_title("bigmap")
  end
end
function imdrw()
  update_ready=true

  -- extra key tracking
  do
    btnex=
      (stat(28,26) and 128 or 0)+ --w
      (stat(28,20) and 64 or 0)+ --q
      (stat(28,44) and 32 or 0)+ --space
      (stat(28,43) and 16 or 0)+ --tab
      (stat(28,81) and 8 or 0)+ --down
      (stat(28,82) and 4 or 0)+ --up
      (stat(28,79) and 2 or 0)+ --right
      (stat(28,80) and 1 or 0)  --left
    btnexp,btnexr=btnex&~btnex_last,~btnex&btnex_last
    btnex_last=btnex

    if btnexp&32>0 then mode_brush,mode_brush_last="tool_pan",mode_brush end
    if btnexr&32>0 then mode_brush=mode_brush_last or "tool_draw" end

    tabp=btnexp&16>0

    -- q/w
    local ds=(btnexp>>7&1)-(btnexp>>6&1)
    if ds~=0 then brush:cycle(ds) end
  end

  --[[
  ## imdrw_game
  --]]

  sprswap(false)
  imp_begin()
  status=""

  --[[
  ### map
  --]]
  do
    local id,sx0,sy0,sx1,sy1="map",0,8,127,mode_fullscreen and 120 or 77
    local sw,sh=sx1-sx0+1,sy1-sy0+1

    camera()
    clip(sx0,sy0,sw,sh) -- clip selection rects, mainly
    -- fillp(0x6c93) -- vanilla
    fillp(0x5010)
    local widget,is_new=imp_area(id,sx0,sy0,sx1,sy1,col_bkg)
    fillp()
    if is_new then
      --camera coords
      widget.cx=0
      widget.cy=0
      if focusx then
        widget.cx=(focusx&-16)*lodz
        widget.cy=(focusy&-16)*lodz
      end
    end

    -- zoom
    if mwheel~=0 and not show_load_dialog then -- hacky
      local oldz=lodz
      lodz=mid(1,8,lodz<<sgn(mwheel))
      local hw,hh=(sx1-sx0+1)/2,(sy1-sy0+1)/2
      -- (widget.cx_old+hw)/lodz_old == (widget.cx_new+hw)/lodz_new
      widget.cx=(widget.cx+hw)*lodz/oldz-hw
      widget.cy=(widget.cy+hh)*lodz/oldz-hh
    end

    local draw_mask=mode_brush=="tool_draw" and 1 or 0
    local picker_mask=mode_brush=="tool_select" and 3 or 2
    local pan_mask=mode_brush=="tool_pan" and 5 or 4

    -- pan
    if widget.held&pan_mask>0 then
      widget.cx-=mx-mpx
      widget.cy-=my-mpy
    end

    -- keyboard pan
    for i=0,3 do
      if _btn_helper(btnexp,i) then
        local amt=(stat(28,224) and 16 or 1)*lodz --ctrl
        -- pq(tohex(widget.cx),tohex(widget.cy))
        if widget.cx&-amt==widget.cx and widget.cy&-amt==widget.cy then
          widget.cx+=dirx[i]*amt
          widget.cy+=diry[i]*amt
        end
        widget.cx&=-amt --snap
        widget.cy&=-amt
      end
    end

    camera(widget.cx-sx0,widget.cy-sy0)

    -- determine focus (used to tell parent cart where to resume playing)
    focusx=mid(mapw-16,(%0x5f28+(sx0+sx1)/2)\lodz)
    focusy=mid(maph-16,(%0x5f2a+(sy0+sy1)/2)\lodz)

    -- tile coords
    local tx=(%0x5f28+mx)\lodz
    local ty=(%0x5f2a+my)\lodz
    if widget.hovering then
      status="x:"..leftpadnum(tx,3).." y:"..leftpadnum(ty,3)
    end

    -- draw/stroke
    if widget.pressed&draw_mask>0 then
      widget.tpx=tx
      widget.tpy=ty
      brush:stroke(tx,ty)
    end
    if widget.held&draw_mask>0 then
      -- factorio mouse interpolation:
      local x=widget.tpx
      local y=widget.tpy
      while x~=tx or y~=ty do
        -- not bresenham, but we don't need that
        x=approach(x,tx)
        y=approach(y,ty)
        brush:stroke(x,y)
      end
      widget.tpx=x
      widget.tpy=y
    end
    -- if widget.released&draw_mask>0 then
    --   autosave()
    -- end

    -- picker
    if widget.pressed&picker_mask>0 then
      widget.picking=true
      widget.tx_pick=tx
      widget.ty_pick=ty
    end
    if widget.released&picker_mask>0 then
      widget.picking=false
      brush:pickmap(tx,ty,widget.tx_pick,widget.ty_pick)
    end

    -- draw black mat underneat map
    rectfill(0,0,mapw*lodz,maph*lodz,0)
    rectb(0,0,mapw*lodz-1,maph*lodz-1,0,6)

    cached_map_draw(widget.cx,widget.cy,sx0,sy0,sw,sh)

    -- draw current room
    if mode_room_outlines then
      local tx0=focusx&-16
      local ty0=focusy&-16
      rectb(tx0*lodz,
            ty0*lodz,
            (tx0+16)*lodz-1,
            (ty0+16)*lodz-1,13)
    end

    -- draw brush source
    local src,tx0,ty0,tw,th=brush:source()
    if src=="map" then
      local tx1,ty1=tx0+tw-1,ty0+th-1
      local a,b,c,d=
        tx0*lodz-1,
        ty0*lodz-1,
        (tx1+1)*lodz,
        (ty1+1)*lodz
      rectb(a+1,b+1,c-1,d-1,0)
      fillp(pulse(▒,1, ▒^^0xffff,1))
      rect(a,b,c,d,7)
      fillp()
    end

    -- draw marquee or hover
    if widget.picking or (widget.hovering and mode_brush=="tool_draw") then
      local tx0=tx
      local ty0=ty
      local tx1=widget.picking and widget.tx_pick or tx+brush.w-1
      local ty1=widget.picking and widget.ty_pick or ty+brush.h-1
      if tx1<tx0 then tx0,tx1=tx1,tx0 end --swap
      if ty1<ty0 then ty0,ty1=ty1,ty0 end --swap
      rectb(tx0*lodz,
            ty0*lodz,
            (tx1+1)*lodz-1,
            (ty1+1)*lodz-1,7)
    end
  end

  --[[
  ### sprites
  note: very similar code to map section (above)
  --]]
  if not mode_fullscreen then
    local id,sx0,sy0,sx1,sy1="spr",0,87,127,120 --including 1px padding
    local sw,sh=sx1-sx0+1,sy1-sy0+1

    camera()
    clip(sx0,sy0,sw,sh) -- clip selection rects, mainly
    local widget,is_new=imp_area(id,sx0,sy0,sx1,sy1,0)
    if is_new then
      --camera coords
      widget.cx=0
      widget.cy=0
    end

    -- pan
    if widget.held&4>0 then
      widget.cy-=my-mpy
      widget.cy=mid(0,128-32,widget.cy)
    end
    if spr_tab_ix then
      widget.cy=spr_tab_ix*32
    end

    camera(widget.cx-sx0,widget.cy-sy0-1) -- 1px to compensate padding

    -- tile coords
    local tx=(%0x5f28+mx)\8
    local ty=(%0x5f2a+my)\8
    if widget.hovering then
      status="s:"..leftpadnum(ty*16+tx,3)
    end

    -- picker
    if widget.pressed&0b11>0 then
      widget.picking=true
      widget.tx_pick=tx
      widget.ty_pick=ty
    end
    if widget.released&0b11>0 then
      widget.picking=false
      brush:pickspr(tx,ty,widget.tx_pick,widget.ty_pick)
    end

    -- draw sprites
    local cx=widget.cx\8
    local cy=widget.cy\8
    for ty=cy,cy+ceil(sh/8) do
      for tx=cx,cx+ceil(sw/8) do
        spr(ty*16+tx,tx*8,ty*8)
      end
    end

    -- draw padding
    local cx,cy=camera()
    rect(sx0-1,sy0,sx1+1,sy1,0)
    camera(cx,cy)

    -- draw brush source
    local src,tx0,ty0,tw,th=brush:source()
    if src=="spr" then
      local tx1,ty1=tx0+tw-1,ty0+th-1
      local a,b,c,d=tx0*8-1,ty0*8-1,tx1*8+8,ty1*8+8
      rectb(a+1,b+1,c-1,d-1,0)
      fillp(pulse(▒,1, ▒^^0xffff,1))
      rect(a,b,c,d,7)
      fillp()
    end

    if widget.picking or widget.hovering then
      -- draw selecting/hover marquee
      local tx0=tx
      local ty0=ty
      local tx1=widget.picking and widget.tx_pick or tx
      local ty1=widget.picking and widget.ty_pick or ty
      if tx1<tx0 then tx0,tx1=tx1,tx0 end --swap
      if ty1<ty0 then ty0,ty1=ty1,ty0 end --swap
      rectb(tx0*8,
            ty0*8,
            tx1*8+7,
            ty1*8+7)
    end

    spr_tab_ix=(widget.cy+16)\32 -- 0..3, for talking to the toolbar
  end

  --[[
  ### tools
  --]]
  camera()
  clip()
  sprswap(true)
  if not mode_fullscreen then
    -- bkg
    rectfill(0,78,127,86,5)

    -- tools
    tool_sprs=tool_sprs or split"1,2,3"
    tool_ids=tool_ids or split"tool_draw,tool_select,tool_pan"
    tool_hints=tool_hints or split"draw,select,pan"
    for i,id in ipairs(tool_ids) do
      local sx0,sy0,sw,sh=-1+i*10,79,7,7
      local sx1,sy1=sx0+sw-1,sy0+sh-1
      if imp_btnspr_tool(tool_sprs[i],sx0,sy0,id,mode_brush==id,tool_hints[i]) then
        mode_brush=id
      end
    end

    -- sprite tabs
    local old_spr_tab_ix=spr_tab_ix
    spr_tab_ix=nil
    for i=0,3 do
      if imp_btnspr_tab(28+i,96+i*8,80,"tab"..i,i==old_spr_tab_ix) then
        spr_tab_ix=i
      end
    end
  end

  --[[
  ### menu
  --]]
  rectfill(0,0,127,7,col_menu)
  for x=0,127 do
    pset(x,8,shadow[pget(x,8)])
    local y=mode_fullscreen and 120 or 77
    pset(x,y,shadow[pget(x,y)])
  end

  --[[
  #### resize
  --]]
  do
    if imp_btnspr_red(8,100,0,"resize",show_resize_menu,"resize map") then
      show_resize_menu=not show_resize_menu
    end
    if show_resize_menu then
      local id="resize_bkg"
      local widget=imp_area(id,82,8,109,27,5) -- TODO recolor
      if mbtnp()>0 and not widget.overlapping then
        show_resize_menu=false
      end

      local sx0,sy0,sx1,sy1=82,9,109,17
      print("w",sx0+3,sy0+2,6)
      local widget=imp_textbox(sx0+9,sy0+1,17,"changew",false,mapw)
      if widget.hovering then status="map width" end
      if widget.done then
        local val=tonum(widget.text)\1
        if tostr(val)~=widget.text then val=mapw end
        local err=dimerr(val,maph)
        if err then
          toast("bad size: "..err)
        else
          mapw=val
        end
      end

      local sx0,sy0,sx1,sy1=82,18,109,26
      print("h",sx0+3,sy0+2,6)
      local widget=imp_textbox(sx0+9,sy0+1,17,"changeh",false,maph)
      if widget.hovering then status="map height" end
      if widget.done then
        local val=tonum(widget.text)\1
        if tostr(val)~=widget.text then val=maph end
        local err=dimerr(mapw,val)
        if err then
          toast("bad size: "..err)
        else
          maph=val
        end
      end
    end
  end

  --[[
  #### red menu buttons
  --]]
  if imp_btnspr_red(11,4,0,"fullscreen",not mode_fullscreen,"fullscreen (tab)")
  or tabp then
    mode_fullscreen=not mode_fullscreen
  end
  if imp_btnspr_red(5,12,0,"ignore_zero",mode_ignore_zero,"ignore 0 when pasting") then
    mode_ignore_zero=not mode_ignore_zero
  end
  if imp_btnspr_red(4,20,0,"room_vis",mode_room_outlines,"show room outlines") then
    mode_room_outlines=not mode_room_outlines
  end

  if imp_btnspr_red(7,92,0,"trash",false,"discard changes") then
    ini_map()
  end
  if imp_btnspr_red(10,108,0,"save",false,"save") then
    toast(map_export() and "saved to map.p8l" or "save failed!")
  end
  if parentp8 and imp_btnspr_red(12,116,0,"play",false,"save and play (p/enter)")
  or (btnp(6) and not kbenter_used) then --enter/p
    map_export()
    extcmd("go_back")
  end

  --[[
  ### status
  --]]
  do
    rectfill(0,121,127,127,col_menu)
    print(status,2,122,2)
  end

  imp_end()
  autosave()
end

--[[
# misc helpers
--]]

function dimerr(w,h)
  if w<1 or h<1 then return "too small" end
  if 256<w then return "width must be <=256" end
  local t=(w>>>8)*(h>>>8)
  if t<0 or 0.5<t then
    -- w*h > 32k (in pure math, not computer math)
    return "total area >32K"
  end
end

function sprswap(ui)
  memcpy(0,ui and 0x4300 or 0x4700,0x400)
end

function rectb(x0,y0,x1,y1, c1,c2)
 rect(x0-1,y0-1,x1+1,y1+1,c1 or 7)
 rect(x0-2,y0-2,x1+2,y1+2,c2 or 0)
end

function leftpadnum(x,n)
  local m=""
  if (x<0) then m="-" n-=1 x*=-1 end
  local s=tostr(x)
  while #s<n do s="0"..s end
  return m..s
end

function make_brush()
  local br={}
  function br:stroke(tx,ty)
    for i=0,self.w*self.h-1 do
      local x,y=tx+i%self.w,ty+i\self.w
      local t=self[i]
      if t>0 or (self.just_spr0 or not mode_ignore_zero) then
        mapset(x,y,t)
      end
    end
    invalidate_map_cache()
  end
  function br:pickmap(x1,y1,x2,y2)
    if x2<x1 then x1,x2=x2,x1 end --swap
    if y2<y1 then y1,y2=y2,y1 end --swap
    if x2<0 or mapw<=x1
    or y2<0 or maph<=y1 then
      return
    end
    x1=mid(0,mapw-1,x1)
    x2=mid(0,mapw-1,x2)
    y1=mid(0,maph-1,y1)
    y2=mid(0,maph-1,y2)
    self.src="map"
    self.sx=x1
    self.sy=y1
    self.w=x2-x1+1
    self.h=y2-y1+1
    self.just_spr0=true
    for i=0,self.w*self.h-1 do
      local x,y=x1+i%self.w,y1+i\self.w
      -- assert(mapisvalid(x,y))
      self[i] = mapget(x,y)
      if self[i]>0 then self.just_spr0=false end
    end

    if self.w==1 and self.h==1 then
      -- change source to spr
      local x,y=self[0]%16,self[0]\16
      self:pickspr(x,y,x,y)
    end
  end
  function br:pickspr(x1,y1,x2,y2)
    if x2<x1 then x1,x2=x2,x1 end --swap
    if y2<y1 then y1,y2=y2,y1 end --swap
    if x2<0 or 16<=x1
    or y2<0 or 16<=y1 then
      return
    end
    x1=mid(0,16-1,x1)
    x2=mid(0,16-1,x2)
    y1=mid(0,16-1,y1)
    y2=mid(0,16-1,y2)
    self.src="spr"
    self.sx=x1
    self.sy=y1
    self.w=x2-x1+1
    self.h=y2-y1+1
    self.just_spr0=true
    for i=0,self.w*self.h-1 do
      local x,y=x1+i%self.w,y1+i\self.w
      self[i] = y*16+x
      if self[i]>0 then self.just_spr0=false end
    end
  end
  function br:cycle(ds)
    if self.src=="spr" then
      local i=self.sy*16+self.sx
      i=mid(0,255,i+ds)
      local x,y=i%16,i\16
      br:pickspr(x,y,x,y)
    end
  end
  function br:movedir(dir, grow)
    local dx,dy=dirx[dir],diry[dir]
    local dw,dh=0,0
    if grow then
      dw=dx
      dh=dy
      dx=0
      dy=0
    end
    local x1=self.sx+dx
    local y1=self.sy+dy
    local x2=self.sx+dx+max(self.w+dw-1)
    local y2=self.sy+dy+max(self.h+dh-1)
    if 0<=x1 and 0<=y1 then
      if self.src=="spr" then
        self:pickspr(x1,y1,x2,y2)
      else
        self:pickmap(x1,y1,x2,y2)
      end
    end
  end
  function br:source()
    return self.src,self.sx,self.sy,self.w,self.h
  end
  br:pickspr(1,0,1,0)
  return br
end

function invalidate_map_cache()
  poke4(0x8000,~$0x8000)
end
function cached_map_draw(cx,cy,sx,sy,sw,sh)
  assert(sx==0 and sw==128)
  local ptr=0x8000
  local function pop() local res=$ptr ptr+=4 return res end
  local valid=cx==pop() and cy==pop()
          and sy==pop() and sh==pop() and lodz==pop()
          and mapw==pop() and maph==pop()
  if valid then
    memcpy(0x6000+64*sy,ptr,sw*sh/2)
  else
    --draw
    -- ptr=0x8000 pq("map cache invalid",pop(),pop(),pop(),pop(),pop(),pop(),pop())
    for ty=cy\lodz,cy\lodz+ceil(sh/lodz) do
      for tx=cx\lodz,cx\lodz+ceil(sw/lodz) do
        local t=mapget(tx,ty)
        if t>0 then
          sprlod(t,tx*lodz,ty*lodz)
        end
      end
    end
    fillp()

    --store
    local ptr=0x8000
    local function push(v) poke4(ptr,v) ptr+=4 end
    push(cx) push(cy)
    push(sy) push(sh)
    push(lodz)
    push(mapw) push(maph)
    memcpy(ptr,0x6000+64*sy,sw*sh/2)
  end
end



function ini_map()
  _16=16 -- chunksize (const)
  clear_map()
  if parentp8 then
    -- we must have done #include map.p8l earlier -- load it
    map_import() -- make mget return proper data (from a string or whereever)
    for y=0,maph-1 do
      for x=0,mapw-1 do
        mapset(x,y,mget(x,y))
      end
    end
  else
    mapw=16
    maph=16
  end
end
function map_import()
  -- this will get overwritten in map.p8l
  -- so, if we're running this, it's because
  --   no map has been saved yet.
  -- so, import that parent's vanilla map data
  focusx=0
  focusy=0
  mapw=128
  maph=64
  reload(0x1000,0x1000,0x2000,parentp8)
end
function clear_map()
  _chunks={}
  invalidate_map_cache()
end

function mapisvalid(x,y)
  return 0<=x and x<mapw and 0<=y and y<maph
end

function mapset(x,y,v)
  if mapisvalid(x,y) then
    local chunk,xx,yy = _mapchunk(x,y)
    chunk[yy*_16+xx] = v
  end
end

function mapget(x,y)
  if mapisvalid(x,y) then
    local chunk,xx,yy = _mapchunk(x,y)
    return chunk[yy*_16+xx] or 0
  else
    return 0
  end
end

--[[
# implementation details
--]]

-- returns the chunk that contains the
--  map coord x,y
function _mapchunk(x,y)
  assert(x>=0 and y>=0)
  local xx,yy=x\_16,y\_16
  local key=xx+(yy>><16)
  if not _chunks[key] then
    _chunks[key]={}
  end
  return _chunks[key],x%_16,y%_16
end

function pc(x,y)
  pchunk(_mapchunk(x,y))
end
function pchunk(ch)
  pq("[[")
  for y=0,_16-1 do
    local line = " "
    for x=0,_16-1 do
      line..=" "..(ch[y*_16+x] or 0)
    end
    pq(line)
  end
  pq("]]")
end

--[[
## import/export
--]]

function autosave()
  if autosave_seconds>0 and time()-last_autosave>autosave_seconds then
    -- called during _draw, so this works
    rectfill(0,121,127,127,col_menu)
    print("autosaving...",1,122,15)
    flip()
    map_export(autosave_prefix..datestamp()..".p8l")
    last_autosave=time()
  end
end

function map_export( fname)
  if not parentp8 then return end

  local clen=px9_comp(0,0,mapw,maph,0x8000,mapget)
  local s=escape_binary_str(chr(peek(0x8000,clen)))
  local s2=
      "-- this file was auto-generated by bigmap.p8"..
    "\nfunction map_import()"..
    "\n focusx="..focusx..
    "\n focusy="..focusy..
    "\n mapw="..mapw..
    "\n maph="..maph..
    "\n poke(0x5f56,0x80,mapw)"..
    "\n local function vget(x,y) return @(0x8000+x+y*mapw) end"..
    "\n local function vset(x,y,v) return poke(0x8000+x+y*mapw,v) end"..
    "\n px9_sdecomp(0,0,vget,vset,\""..s.."\")"..
    "\nend"
  printh(s2,fname or "map.p8l",true)
  return true
end

-- https://www.lexaloffle.com/bbs/?tid=38692
function escape_binary_str(s)
 local out=""
 for i=1,#s do
  local c=sub(s,i,i)
  local nc=ord(s,i+1)
  local v=c
  if(c=="\"") v="\\\""
  if(c=="\\") v="\\\\"
  if(ord(c)==0) v=(nc and nc>=48 and nc<=57) and "\\x00" or "\\0"
  if(ord(c)==10) v="\\n"
  if(ord(c)==13) v="\\r"
  out..=v
 end
 return out
end

-- function map_export( fname)
--   if not parentp8 then return end

--   local s=""..mapget(0,0)
--   for i=1,mapw*maph-1 do
--     local b=mapget(i%mapw,i\mapw)
--     s..=","..b
--   end
--   -- TODO: this dumps the map at 0x8000; does it need to be aligned to end at 0xffff?
--   --   sort of but not really; mget OOB returns 0 anyway.
--   --   hmm, but if they use more upper memory then map() will draw it. ehh.
--   local s2=
--       "-- this file was auto-generated by bigmap.p8"..
--     "\nfunction map_import()"..
--     "\n focusx="..focusx..
--     "\n focusy="..focusy..
--     "\n mapw="..mapw..
--     "\n maph="..maph..
--     "\n local mapdat=split\""..s.."\""..
--     "\n poke(0x5f56,0x80,mapw)"..
--     "\n poke(0x8000,unpack(mapdat))"..
--     "\nend"
--   printh(s2,fname or "map.p8l",true)
-- end



-- px9 compress
-- custom version for bigmap v1.0
-- (based on px9 v7)

-- x0,y0 where to read from
-- w,h   image width,height
-- dest  address to store
-- vget  read function (x,y)

function
  px9_comp(x0,y0,w,h,dest,vget)

  local dest0=dest
  local bit=1
  local byte=0

  local function vlist_val(l, val)
    -- find position and move
    -- to head of the list
    local v,i=l[1],1
    while v!=val do
      i+=1
      v,l[i]=l[i],v
    end
    l[1]=val
    return i
  end

  function putbit(bval)
    if (bval) byte+=bit
    poke(dest, byte) bit<<=1
    if (bit==256) then
      bit=1 byte=0
      dest += 1
    end
  end

  function putval(val, bits)
    for i=0,bits-1 do
      putbit(val&1<<i > 0)
    end
  end

  function putnum(val)
    local bits = 0
    repeat
      bits += 1
      local mx=(1<<bits)-1
      local vv=min(val,mx)
      putval(vv,bits)
      val -= vv
    until vv<mx
  end


  -- first_used

  local el={}
  local found={}
  local highest=0
  for y=y0,y0+h-1 do
    for x=x0,x0+w-1 do
      c=vget(x,y)
      if not found[c] then
        found[c]=true
        add(el,c)
        highest=max(highest,c)
      end
    end
  end

  -- header

  local bits=1
  while highest >= 1<<bits do
    bits+=1
  end

  putnum(w-1)
  putnum(h-1)
  putnum(bits-1)
  putnum(#el-1)
  for i=1,#el do
    putval(el[i],bits)
  end


  -- data

  local pr={} -- predictions

  local dat={}

  for y=y0,y0+h-1 do
    for x=x0,x0+w-1 do
      local v=vget(x,y)

      local a=y>y0 and vget(x,y-1) or 0

      -- create vlist if needed
      local l=pr[a]
      if not l then
          l={unpack(el)}
          pr[a]=l
      end

      -- add to vlist
      add(dat,vlist_val(l,v))

      -- and to running list
      vlist_val(el, v)
    end
  end

  -- write
  -- store bit-0 as runtime len
  -- start of each run

  local nopredict
  local pos=1

  while pos <= #dat do
    -- count length
    local pos0=pos

    if nopredict then
      while dat[pos]!=1 and pos<=#dat do
        pos+=1
      end
    else
      while dat[pos]==1 and pos<=#dat do
        pos+=1
      end
    end

    local splen = pos-pos0
    putnum(splen-1)

    if nopredict then
      -- values will all be >= 2
      while pos0 < pos do
        putnum(dat[pos0]-2)
        pos0+=1
      end
    end

    nopredict=not nopredict
  end

  if (bit!=1) dest+=1 -- flush

  return dest-dest0
end




-->8
-- uncomment these two lines:
#include px9_decomp.lua
#include map.p8l

-- defaults; edit if you like:
autosave_seconds=0 --set to 0 to disable
autosave_prefix="autosave/map_"

mode_room_outlines=true
mode_ignore_zero=false




__gfx__
000000000000d000d0d0d0d000d0d000000000000000000000000000000000000000000000000000000000000000000000000000007000000070000000000000
00000000000ddd000000000000d0d0d0002222000000000000022000022222200020202000000000022222000222222000220000007700000070000000000000
0070070000ddddd0d00000d000d0d0d0020000200020020000000000020202000200000002222000022202200200002000222000007770000070707000707070
000770000ddddd000000000000ddddd0020000200002200002020020002020200000000002022220022222200222222000222200007777000077777000777770
00077000d0ddd000d00000d0d0ddddd0020000200002200002002020000202000200000002200020020000200000000000222200007700007077777070777770
00700700d00d0000000000000dddddd0020000200020020000000000002020000000000002000220020220200202020000222000000070000777777007777770
00000000ddd00000d0d0d0d0000ddd00002222000000000000022000002222000200000002222200020000200020202000220000000000000007770000077700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007770000077700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777700077777000777770007777700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077ddd77077dd777077ddd77077ddd770
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077d7d770777d77707777d770777dd770
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077d7d770777d777077d777707777d770
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077ddd77077ddd77077ddd77077ddd770
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777770777777707777777077777770
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088888880888888808888888088888880
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000099999990999999909999999099999990
000000000000000000000000088888800000000000000000000000000000000000aaaaa0000aaa000000a0000300b0b003300b00000060000000600000060000
000000000888888008888880888888880888888008888800000000000888888000a000a0000a0a000000a000003b3300003bb300000060000000600000060000
000000008888888888888888888ffff888888888888888800888888088f1ff1800a909a0000a0a000000a00009aaaa9009aaaa90000600000000600000060000
00000000888ffff8888ffff888f1ff18888ffff88ffff8808888888888fffff8009aaa900009a9000000a0000a9aaaa00aaa9aa0000600000000600000060000
0000000088f1ff1888f1ff1808fffff088f1ff1881ff1f80888ffff888fffff80000a0000000a0000000a0000aaaa9a00a9aaa90000600000006000000006000
0000000008fffff008fffff00033330008fffff00fffff8088fffff8083333800099a0000009a0000000a0000aa9aaa00aaaa9a0000600000006000000006000
00000000003333000033330007000070073333000033337008f1ff10003333000009a0000000a0000000a00009aaaa9009aaaa90000060000006000000006000
000000000070070000700070000000000000070000007000077333700070070000aaa0000009a0000000a000009aa900009aa900000060000006000000006000
555555550000000000000000000000000000000000000000008888004999999449999994499909940300b0b0666566650300b0b0000000000000000070000000
55555555000000000000000000000000000000000000000008888880911111199111411991140919003b330067656765003b3300007700000770070007000007
550000550000000000000000000000000aaaaaa00000000008788880911111199111911949400419028888206770677002888820007770700777000000000000
55000055007000700499994000000000a998888a1111111108888880911111199494041900000044089888800700070078988887077777700770000000000000
55000055007000700050050000000000a988888a1000000108888880911111199114094994000000088889800700070078888987077777700000700000000000
55000055067706770005500000000000aaaaaaaa1111111108888880911111199111911991400499088988800000000008898880077777700000077000000000
55555555567656760050050000000000a980088a1444444100888800911111199114111991404119028888200000000002888820070777000007077007000070
55555555566656660005500004999940a988888a1444444100000000499999944999999444004994002882000000000000288200000000007000000000000000
5777777557777777777777777777777577cccccccccccccccccccc77577777755555555555555555555555550000000007777770cccccccc0000000000000000
77777777777777777777777777777777777cccccccccccccccccc777777777775555555555555550055555550000000077777777cccccccc0000000000000000
777c77777777ccccc777777ccccc7777777cccccccccccccccccc777777777775555555555555500005555550000000077777777cc77cccc0000000000000000
77cccc77777cccccccc77cccccccc7777777cccccccccccccccc7777777cc7775555555555555000000555550070007077773377cc77c7cc0000000000000000
77cccc7777cccccccccccccccccccc777777cccccccccccccccc777777cccc775555555555550000000055550070007077773377cccccccc0000000000000000
777cc77777cc77ccccccccccccc7cc77777cccccccccccccccccc77777cccc775555555555500000000005550776077673773337ccc7cccc0000000000000000
7777777777cc77cccccccccccccccc77777cccccccccccccccccc77777c7cc77555555555500000000000055567656767333bb37cccccc7c0000000000000000
5777777577cccccccccccccccccccc7777cccccccccccccccccccc7777cccc77555555555000000000000005566656660333bb30cccccccc0000000000000000
77cccc7777cccccccccccccccccccc77577777777777777777777775777ccc775555555550000000000000055555555503333330000000000000000000000000
777ccc7777cccccccccccccccccccc77777777777777777777777777777cc7775055555555000000000000555555555503b333300000000000ee0ee000000000
777ccc7777cc7cccccccccccc77ccc777777ccc7777777777ccc7777777cc77755550055555000000000055555000055033333300000000000eeeee000000030
77ccc77777ccccccccccccccc77ccc77777ccccc7c7777ccccccc77777ccc777555500555555000000005555550000550333b33000000000000e8e00000000b0
77ccc777777cccccccc77cccccccc777777ccccccc7777c7ccccc77777cccc7755555555555550000005555555000055003333000000b00000eeeee000000b30
777cc7777777ccccc777777ccccc77777777ccc7777777777ccc777777cccc775505555555555500005555555500005500044000000b000000ee3ee003000b00
777cc777777777777777777777777777777777777777777777777777777cc7775555555555555550055555555555555500044000030b00300000b00000b0b300
77cccc77577777777777777777777775577777777777777777777775577777755555555555555555555555555555555500999900030330300000b00000303300
__label__
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999ffffff99999999999ffff99999999999999999999999999999999999999999999999999999999999222222999999999992929299222229999ff99999999
99999f9999f9992992999f9999f9999999999999999999999999999999999999999999999999999999999292929999999999929999999222922999fff9999999
99999ffffff9999229999f9999f9999999999999999999999999999999999999999999999999999999999929292999999999999999999222222999ffff999999
999999999999999229999f9999f9999999999999999999999999999999999999999999999999999999999992929999999999929999999299992999ffff999999
99999f9f9f99992992999f9999f9999999999999999999999999999999999999999999999999999999999929299999999999999999999292292999fff1999999
999999f9f9f99999999999ffff99999999999999999999999999999999999999999999999999999999999922229999999999929999999299992999ff17199999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999917119199
6ddddddddddddd6d6d6d6ddddddddddddd6d6d6d6d6d6dd6d6d6d66d6d00000000000000000101d6d66d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6dd6d66d1717171d
c7ccccccccccccc7c7c7c7cccccccccc00000000000000000000000000000000000000000000000000000000000000000000c7c7c7c7c7c7c77c7cc11777771c
7ccccccccccccc7c7c7c7ccccccccccc0dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd07c7c7c7c7c7c7cc7c7171777771c
555555c7c7ccccccccc7c7c7c77c7c500dc7c7c7c77c7cc7c7c7c7c7c7c7c7c7c7c7c7cccccccc0606000000000606c7c7d0c7c7c7ccccc7c7ccccc177777710
5555557c7ccccccccc7c7c7c7cc7c7050d7c7c7c7cc7c77c7c7c7c7c7c7c7c7c7c7c7ccccccccc60600000000060607c7cd07c7c7ccccc7c7ccccc7c11777105
555555c7c7ccccccccc7c7c7c77c7c500dc7c7c7c77c7cc7c7c7c7c7c7c7c7c7c7c7c7cccccccc0606000000000606c7c7d0c7c7c7ccccc7c7ccccc7c1777150
5555557c7ccccccccc7c7c7c7cc7c7050d7c7c7c7cc7c77c7c7c7c7c7c7c7c7c7c7c7ccccccccc60600000000060607c7cd07c7c7ccccc7c7ccccc7c7c111705
5555555050c7c7c7c7c7c77c7c5050550d00000000000000005050555555555555c7c7c7c7cccc0606000000000606c7c7d0555555c7c7c7c7c7c77c7c555550
55555505057c7c7c7c7c7cc7c70505550d000000000000000005055555555555557c7c7c7ccccc60600000000060607c7cd05555557c7c7c7c7c7cc7c7555505
5555555050c7c7c7c7c7c77c7c5050550d00000000000000005050555555555555c7c7c7c7cccc0606000000000606c7c7d0555555c7c7c7c7c7c77c7c555550
55555505057c7c7c7c7c7cc7c70505550d000000000000000005055555555555557c7c7c7ccccc60600000000060607c7cd05555557c7c7c7c7c7cc7c7555505
5055555050505055555555555555557c0d000008080000060606060606000050505050c7c7c7c70606505050500606c7c7d000505050507c7cc7c77c7c505050
055555050505055555555555555555c70d0000808000006060606060600000050505057c7c7c7c60600505050560607c7cd00005050505c7c77c7cc7c7050505
5055555050505055555555555555557c0d000008080000060606060606000050505050c7c7c7c70606505050500606c7c7d000505050507c7cc7c77c7c505050
055555050505055555555555555555c70d0000808000006060606060600000050505057c7c7c7c60600505050560607c7cd00005050505c7c77c7cc7c7050505
065050555555555555505055557c7cc70dc7c7c7c77c7c7c7c7c7c7c7c000000005050c7c7c7c75555555555555050c7c7d00000005050c7c7c7c75050000000
60050555555555555505055555c7c77c0d7c7c7c7cc7c7c7c7c7c7c7c70000000005057c7c7c7c55555555555505057c7cd000000005057c7c7c7c0505000000
065050555555555555505055557c7cc70dc7c7c7c77c7c7c7c7c7c7c7c000000005050c7c7c7c75555555555555050c7c7d00000005050c7c7c7c75050000000
60050555555555555505055555c7c77c0d7c7c7c7cc7c7c7c7c7c7c7c70000000005057c7c7c7c55555555555505057c7cd000000005057c7c7c7c0505000000
7c060655555555555550500000c7c7c70dc7c7c7c70606000000000000000000000000c7c7c7c75050555555555555c7c7d00008085050c7c7c7c75050505050
c76060555555555555050500007c7c7c0d7c7c7c7c60600000000000000000000000007c7c7c7c05055555555555557c7cd000808005057c7c7c7c0505050505
7c060655555555555550500000c7c7c70dc7c7c7c70606000000000000000000000000c7c7c7c75050555555555555c7c7d00008085050c7c7c7c75050505050
c76060555555555555050500007c7c7c0d7c7c7c7c60600000000000000000000000007c7c7c7c05055555555555557c7cd000808005057c7c7c7c0505050505
065050555555555050000000000606060dcccc7c7c0606000000000000000000000000c7c7c7c75555555550505555c7c7d0007c7c5050c7c7c7c75555555550
600505555555550505000000006060600dccccc7c760600000000000000000000000007c7c7c7c55555555050555557c7cd000c7c705057c7c7c7c5555555505
065050555555555050000000000606060dcccc7c7c0606000000000000000000000000c7c7c7c75555555550505555c7c7d0007c7c5050c7c7c7c75555555550
600505555555550505000000006060600dccccc7c760600000000000000000000000007c7c7c7c55555555050555557c7cd000c7c705057c7c7c7c5555555505
505050000050505050000000000000000dc7c706060000000000000000000000000000c7c7c7c75555555550505050c7c7d00000005050c7c77c7c5555505000
050505000005050505000000000000000d7c7c606000000000000000000000000000007c7c7c7c55555555050505057c7cd000000005057c7cc7c75555050500
505050000050505050000000000000000dc7c706060000000000000000000000000000c7c7c7c75555555550505050c7c7d00000005050c7c77c7c5555505000
050505000005050505000000000000000d7c7c606000000000000000000000000000007c7c7c7c55555555050505057c7cd000000005057c7cc7c75555050500
505050000000000000000000000000000dc7c70606000080800000060606060000505055557c7c5555505000000000c7c7d0007c7c7c7cc7c755555555505000
050505000000000000000000000000000d7c7c606000000808000060606060000005055555c7c755550505000000007c7cd000c7c7c7c77c7c55555555050500
505050000000000000000000000000000dc7c70606000080800000060606060000505055557c7c5555505000000000c7c7d0007c7c7c7cc7c755555555505000
050505000000000000000000000000000d7c7c606000000808000060606060000005055555c7c755550505000000007c7cd000c7c7c7c77c7c55555555050500
555050000000000000000000000000000dc7c706060000000006067c7cc7c75050555550507c7c50500000000000000000d0000000c7c7c7c755555555505000
550505000000000000000000000000000d7c7c6060000000006060c7c77c7c050555550505c7c705050000000000000000d00000007c7c7c7c55555555050500
555050000000000000000000000000000dc7c706060000000006067c7cc7c75050555550507c7c50500000000000000000d0000000c7c7c7c755555555505000
550505000000000000000000000000000d7c7c6060000000006060c7c77c7c050555550505c7c705050000000000000000d00000007c7c7c7c55555555050500
555050030300000000030300000000000d7c7c5050050505050606c7c7c7c75555555555557c7c00000000000000000000d0505050c7c7c7c755555050555550
550505303000000000303000000000000dc7c705055050505060607c7c7c7c555555555555c7c700000000000000000000d00505057c7c7c7c55550505555505
555050030300000000030300000000000d7c7c5050050505050606c7c7c7c75555555555557c7c00000000000000000000d0505050c7c7c7c755555050555550
550505303000000000303000000000000dc7c705055050505060607c7c7c7c555555555555c7c700000000000000000000d00505057c7c7c7c55550505555505
7c7c7c7c7c7c7c7c7c7c7c00000000500dc7c75555555550505050c7c7c7c7555555555050000000000000000000000000d0505555c7c77c7c0000505055557c
c7c7c7c7c7c7c7c7c7c7c700000000050d7c7c55555555050505057c7c7c7c555555550505000000000000000000000000d00555557c7cc7c7000005055555c7
7c7c7c7c7c7c7c7c7c7c7c00000000500dc7c75555555550505050c7c7c7c7555555555050000000000000000000000000d0505555c7c77c7c0000505055557c
c7c7c7c7c7c7c7c7c7c7c700000000050d7c7c55555555050505057c7c7c7c555555550505000000000000000000000000d00555557c7cc7c7000005055555c7
0606060606060606060606000000007c0dc7c75555505055555555c7c7c7c7505050500000000080800000000000000000d0505555505000000000000050507c
606060606060606060606000000000c70d7c7c55550505555555557c7c7c7c050505050000000008080000000000000000d005555505050000000000000505c7
0606060606060606060606000000007c0dc7c75555505055555555c7c7c7c7505050500000000080800000000000000000d0505555505000000000000050507c
606060606060606060606000000000c70d7c7c55550505555555557c7c7c7c050505050000000008080000000000000000d005555505050000000000000505c7
000000000000000000000003035050c70dc7c75050505000005050c7c77c7c505000000000000000000000000000000000d00055555555505000000000000050
0000000000000000000000303005057c0d7c7c05050505000005057c7cc7c7050500000000000000000000000000000000d00055555555050500000000000005
000000000000000000000003035050c70dc7c75050505000005050c7c77c7c505000000000000000000000000000000000d00055555555505000000000000050
0000000000000000000000303005057c0d7c7c05050505000005057c7cc7c7050500000000000000000000000000000000d00055555555050500000000000005
0000000000060606067c7cc7c7c7c7c70dc7c7505000000000000050507c7c505000000000000000000000000000000000d00055555050555550500505000000
000000000060606060c7c77c7c7c7c7c0d7c7c05050000000000000505c7c7050500000000000000000000000000000000d00055550505555505055050000000
0000000000060606067c7cc7c7c7c7c70dc7c7505000000000000050507c7c505000000000000000000000000000000000d00055555050555550500505000000
000000000060606060c7c77c7c7c7c7c0d7c7c05050000000000000505c7c7050500000000000000000000000000000000d00055550505555505055050000000
06060606067c7cc7c7ccccc7c7c7c7c70d7c7c000000000000000000005555555550500000000000000000000000000000d00000005050555555555555505003
6060606060c7c77c7ccccc7c7c7c7c7c0dc7c7000000000000000000005555555505050000000000000000000000000000d00000000505555555555555050530
06060606067c7cc7c7ccccc7c7c7c7c70d7c7c000000000000000000005555555550500000000000000000000000000000d00000005050555555555555505003
6060606060c7c77c7ccccc7c7c7c7c7c0dc7c7000000000000000000005555555505050000000000000000000000000000d00000000505555555555555050530
c77c7cc7c7ccccccccc7c7c7c7c7c7c70d0000000000000000000050505555555555550000000000000000000000000000d000000000000000000050507c7cc7
7cc7c77c7ccccccccc7c7c7c7c7c7c7c0d0000000000000000000005055555555555550000000000000000000000000000d00000000000000000000505c7c77c
c77c7cc7c7ccccccccc7c7c7c7c7c7c70d0000000000000000000050505555555555550000000000000000000000000000d000000000000000000050507c7cc7
7cc7c77c7ccccccccc7c7c7c7c7c7c7c0d0000000000000000000005055555555555550000000000000000000000000000d00000000000000000000505c7c77c
555555c7c7ccccccccc7c7c7c77c7c500dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd00000000000000000000000000000
5555557c7ccccccccc7c7c7c7cc7c705000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111111d6d6ddddddddd6d6d6d66d6d10100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5555555555555755555d5d5d5d55555d5d5555555555555555555555555555555555555555555555555555555555555557777755555555555555555555555555
5555555555557775555555555555555d5d5d55555555555555555555555555555555555555555555555555555555555577ddd775566666555666665556666655
5555555555577777555d55555d55555d5d5d55555555555555555555555555555555555555555555555555555555555577d7d77566dd666566ddd66566ddd665
5555555555777775555555555555555ddddd55555555555555555555555555555555555555555555555555555555555577d7d775666d66656666d665666dd665
5555555557577755555d55555d555d5ddddd55555555555555555555555555555555555555555555555555555555555577ddd775666d666566d666656666d665
555555555755755555555555555555dddddd5555555555555555555555555555555555555555555555555555555555557777777566ddd66566ddd66566ddd665
5555555557775555555d5d5d5d555555ddd555555555555555555555555555555555555555555555555555555555555577777775666666656666666566666665
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555566666665ddddddd5ddddddd5ddddddd5
00000000707070707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000070000000000000000088888800000000000000000000000000000000000aaaaa0000aaa000000a0000300b0b003300b00000060000000600000060000
000000000888888070888880888888880888888008888800000000000888888000a000a0000a0a000000a000003b3300003bb300000060000000600000060000
000000078888888800888888888ffff888888888888888800888888088f1ff1800a909a0000a0a000000a00009aaaa9009aaaa90000600000000600000060000
00000000888ffff8708ffff888f1ff18888ffff88ffff8808888888888fffff8009aaa900009a9000000a0000a9aaaa00aaa9aa0000600000000600000060000
0000000788f1ff1800f1ff1808fffff088f1ff1881ff1f80888ffff888fffff80000a0000000a0000000a0000aaaa9a00a9aaa90000600000006000000006000
0000000008fffff070fffff00033330008fffff00fffff8088fffff8083333800099a0000009a0000000a0000aa9aaa00aaaa9a0000600000006000000006000
00000007003333000033330007000070073333000033337008f1ff10003333000009a0000000a0000000a00009aaaa9009aaaa90000060000006000000006000
000000000070070070700070000000000000070000007000077333700070070000aaa0000009a0000000a000009aa900009aa900000060000006000000006000
555555070707070700000000000000000000000000000000008888004999999449999994499909940300b0b0666566650300b0b0000000000000000070000000
55555500000000000000000000000000000000000000000008888880911111199111411991140919003b330067656765003b3300007700000770070007000007
550000550000000000000000000000000aaaaaa00000000008788880911111199111911949400419028888206770677002888820007770700777000000000000
55000055007000700499994000000000a998888a1111111108888880911111199494041900000044089888800700070078988887077777700770000000000000
55000055007000700050050000000000a988888a1000000108888880911111199114094994000000088889800700070078888987077777700000700000000000
55000055067706770005500000000000aaaaaaaa1111111108888880911111199111911991400499088988800000000008898880077777700000077000000000
55555555567656760050050000000000a980088a1444444100888800911111199114111991404119028888200000000002888820070777000007077007000070
55555555566656660005500004999940a988888a1444444100000000499999944999999444004994002882000000000000288200000000007000000000000000
5777777557777777777777777777777577cccccccccccccccccccc77577777755555555555555555555555555500000007777770000000000000000000000000
77777777777777777777777777777777777cccccccccccccccccc777777777775555555555555550055555556670000077777777000777770000000000000000
777c77777777ccccc777777ccccc7777777cccccccccccccccccc777777777775555555555555500005555556777700077777777007766700000000000000000
77cccc77777cccccccc77cccccccc7777777cccccccccccccccc7777777cc7775555555555555000000555556660000077773377076777000000000000000000
77cccc7777cccccccccccccccccccc777777cccccccccccccccc777777cccc775555555555550000000055555500000077773377077660000777770000000000
777cc77777cc77ccccccccccccc7cc77777cccccccccccccccccc77777cccc775555555555500000000005556670000073773337077770000777767007700000
7777777777cc77cccccccccccccccc77777cccccccccccccccccc77777c7cc77555555555500000000000055677770007333bb37000000000000007700777770
5777777577cccccccccccccccccccc7777cccccccccccccccccccc7777cccc77555555555000000000000005666000000333bb30000000000000000000077777
77cccc7777cccccccccccccccccccc77577777777777777777777775777ccc775555555550000000000000050000066603333330000000000000000000000000
777ccc7777cccccccccccccccccccc77777777777777777777777777777cc7775055555555000000000000550007777603b333300000000000ee0ee000000000
777ccc7777cc7cccccccccccc77ccc777777ccc7777777777ccc7777777cc77755550055555000000000055500000766033333300000000000eeeee000000030
77ccc77777ccccccccccccccc77ccc77777ccccc7c7777ccccccc77777ccc777555500555555000000005555000000550333b33000000000000e8e00000000b0
77ccc777777cccccccc77cccccccc777777ccccccc7777c7ccccc77777cccc7755555555555550000005555500000666003333000000b00000eeeee000000b30
777cc7777777ccccc777777ccccc77777777ccc7777777777ccc777777cccc775505555555555500005555550007777600044000000b000000ee3ee003000b00
777cc777777777777777777777777777777777777777777777777777777cc7775555555555555550055555550000076600044000030b00300000b00000b0b300
77cccc77577777777777777777777775577777777777777777777775577777755555555555555555555555550000005500999900030330300000b00000303300
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99922922292929222999992229229922999999222929992229292999999299222999292229229922292229222992999999999999999999999999999999999999
99299929292929299999992929292929299999292929992929292999992999292992992999292992992999292999299999999999999999999999999999999999
99222922292929229999992229292929299999222929992229222999992999222992992299292992992299229999299999999999999999999999999999999999
99992929292229299999992929292929299999299929992929992999992999299992992999292992992999292999299999999999999999999999999999999999
99229929299299222999992929292922299999299922292929222999999299299929992229292992992229292992999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008181818181818181818181810000000081010101014040404000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
004d4e4f5c5d5e5f6c6d6e6f7c7d7e7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000212223242526272800050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000080808080008080000000000313233343536373800050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070000000080808080808080000000000414243444546474805050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070007070000070000008080808000000515253545556575805000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070000000000000000000000000000000616263646566676800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000707000000007000000000000000717273747576777800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070700017000070707070000e0e000000818283848586878800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000900007070707000000e0e00000000919293949596979800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000070707000000000007000000000002a2a2a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000070000000000000000000700b00002a001200001212121212000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000117070700000700000000b00121200000000000012000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000120000120000001212000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000b0000000000000012000000001200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000012000000121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012008000c050000000c050000000c050000000c05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0120080018050000001f0500000018050000001f05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01200800180501f050180501f050180501f050180501f050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012008000c050000000c0500000010050000001005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01200800110500000011050000000e050000000e05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0120080021050000001f050000001c050000001805000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012008001505000000130500000010050000001805000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01200800180500000017050000000c050000001805000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000f15013150181501f0502b050330500020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
010400001305000300333002d350313502c340263401e330133300c3201d300153001530000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000100002965027600226401b64016630116200060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
04 08424344
04 09424344
04 0a424344
04 0b424344
04 0c424344
04 0d424344
04 0e424344
04 0f424344

