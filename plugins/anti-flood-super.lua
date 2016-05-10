
--An empty table for solving multiple kicking problem(thanks to sniper )
kicktable = {}

do

local TIME_CHECK = 2 
-- Save stats, ban user
local function pre_process(msg)
  -- Ignore service msg
  if msg.service then
    return msg
  end
  if msg.from.id == our_id then
    return msg
  end
  
    -- Save user on Redis
  if msg.from.type == 'user' then
    local hash = 'user:'..msg.from.id
    print('Saving user', hash)
    if msg.from.print_name then
      redis:hset(hash, 'print_name', msg.from.print_name)
    end
    if msg.from.first_name then
      redis:hset(hash, 'first_name', msg.from.first_name)
    end
    if msg.from.last_name then
      redis:hset(hash, 'last_name', msg.from.last_name)
    end
  end

  -- Save stats on Redis
  if msg.to.type == 'channel' then
    -- User is on chat
    local hash = 'chat:'..msg.to.id..':users'
    redis:sadd(hash, msg.from.id)
  end



  -- Total user msgs
  local hash = 'msgs:'..msg.from.id..':'..msg.to.id
  redis:incr(hash)

  --Load moderation data

  -- Check flood
  if msg.from.type == 'user' then
    local hash = 'user:'..msg.from.id..':msgs'
    local msgs = tonumber(redis:get(hash) or 0)
    local NUM_MSG_MAX = 8
    local max_msg = NUM_MSG_MAX * 1
    if msgs > max_msg then
      local user = msg.from.id
      local chat = msg.to.id
      -- Return end if user was kicked before
      if kicktable[user] == true then
        return
      end
      --kick_user(user, chat)
      local bhash = 'banned:'..msg.to.id..':'..msg.from.id
      redis:set(bhash, true)
      channel_kick_user("channel#id"..chat, 'user#id'..user, ok_cb, false)
      kicktable[user] = true
      msg = nil
    end
    redis:setex(hash, TIME_CHECK, msgs+1)
  end
  return msg
end

local function cron()
  --clear that table on the top of the plugins
	kicktable = {}
end

return {
  patterns = {},
  cron = cron,
  pre_process = pre_process
}

end
