-- px9 decompress
-- custom version for bigmap v1.1
-- (based on px9 v7)

-- x0,y0 where to draw to
-- vget  read function (x,y)
-- vset  write function (x,y,v)
-- str   string full of compressed data

function
    px9_sdecomp(x0,y0,vget,vset,str)
  
    local function vlist_val(l, val)
      -- find position and move
      -- to head of the list
      local v,i=l[1],1
      while v!=val do
        i+=1
        v,l[i]=l[i],v
      end
      l[1]=val
    end
  
    -- bit cache is between 16 and
    -- 31 bits long with the next
    -- bit always aligned to the
    -- lsb of the fractional part
    local ptr,cache,cache_bits=1,0,0
    function getval(bits)
      while cache_bits<16 do
        -- cache next 16 bits
        cache+=(ord(str,ptr) or 0)>>>16-cache_bits
        cache_bits+=8
        ptr+=1
      end
      -- clip out the bits we want
      -- and shift to integer bits
      local val=cache<<32-bits>>>16-bits
      -- now shift those bits out
      -- of the cache
      cache=cache>>>bits
      cache_bits-=bits
      return val
    end
  
    -- get number plus n
    function gnp(n)
      local bits=0
      repeat
        bits+=1
        local vv=getval(bits)
        n+=vv
      until vv<(1<<bits)-1
      return n
    end
  
    -- header
  
    local
      w,h_1,      -- w,h-1
      eb,el,pr,
      x,y,
      splen,
      predict
      =
      gnp"1",gnp"0",
      gnp"1",{},{},
      0,0,
      0
      --,nil
  
    for i=1,gnp"1" do
      add(el,getval(eb))
    end
    for y=y0,y0+h_1 do
      for x=x0,x0+w-1 do
        splen-=1
  
        if(splen<1) then
          splen,predict=gnp"1",not predict
        end
  
        local a=y>y0 and vget(x,y-1) or 0
  
        -- create vlist if needed
        local l=pr[a]
        if not l then
            l={unpack(el)}
            pr[a]=l
        end
  
        -- grab index from stream
        -- iff predicted, always 1
  
        local v=l[predict and 1 or gnp"2"]
  
        -- update predictions
        vlist_val(l, v)
        vlist_val(el, v)
  
        -- set
        vset(x,y,v)
      end
    end
  end