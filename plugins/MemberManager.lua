local function is_user_whitelisted(id)
  local hash = 'whitelist:user#id'..id
  local white = redis:get(hash) or false
  return white
end

local function is_chat_whitelisted(id)
  local hash = 'whitelist:chat#id'..id
  local white = redis:get(hash) or false
  return white
end

local function kick_user(user_id, chat_id)
  local chat = 'chat#id'..chat_id
  local user = 'user#id'..user_id
  chat_del_user(chat, user, ok_cb, true)
end

local function ban_user(user_id, chat_id)
  -- Save to redis
  local hash =  'banned:'..chat_id..':'..user_id
  redis:set(hash, true)
  -- Kick from chat
  kick_user(user_id, chat_id)
end

local function superban_user(user_id, chat_id)
  -- Save to redis
  local hash =  'superbanned:'..user_id
  redis:set(hash, true)
  -- Kick from chat
  kick_user(user_id, chat_id)
end

local function is_banned(user_id, chat_id)
  local hash =  'banned:'..chat_id..':'..user_id
  local banned = redis:get(hash)
  return banned or false
end

local function is_super_banned(user_id)
    local hash = 'superbanned:'..user_id
    local superbanned = redis:get(hash)
    return superbanned or false
end

local function pre_process(msg)

  -- SERVICE MESSAGE
  if msg.action and msg.action.type then
    local action = msg.action.type
    -- Check if banned user joins chat
    if action == 'chat_add_user' or action == 'chat_add_user_link' then
      local user_id
      if msg.action.link_issuer then
          user_id = msg.from.id
      else
	      user_id = msg.action.user.id
      end
      print('Checking invited user '..user_id)
      local superbanned = is_super_banned(user_id)
      local banned = is_banned(user_id, msg.to.id)
      if superbanned or banned then
        print('User is banned!')
        kick_user(user_id, msg.to.id)
      end
    end
    -- No further checks
    return msg
  end

  -- BANNED USER TALKING
  if msg.to.type == 'chat' then
    local user_id = msg.from.id
    local chat_id = msg.to.id
    local superbanned = is_super_banned(user_id)
    local banned = is_banned(user_id, chat_id)
    if superbanned then
      print('SuperBanned user talking!')
      superban_user(user_id, chat_id)
      msg.text = ''
    end
    if banned then
      print('Banned user talking!')
      ban_user(user_id, chat_id)
      msg.text = ''
    end
  end
  
  -- WHITELIST
  local hash = 'whitelist:enabled'
  local whitelist = redis:get(hash)
  local issudo = is_sudo(msg)

  -- Allow all sudo users even if whitelist is allowed
  if whitelist and not issudo then
    print('Whitelist enabled and not sudo')
    -- Check if user or chat is whitelisted
    local allowed = is_user_whitelisted(msg.from.id)

    if not allowed then
      print('User '..msg.from.id..' not whitelisted')
      if msg.to.type == 'chat' then
        allowed = is_chat_whitelisted(msg.to.id)
        if not allowed then
          print ('Chat '..msg.to.id..' not whitelisted')
        else
          print ('Chat '..msg.to.id..' whitelisted :)')
        end
      end
    else
      print('User '..msg.from.id..' allowed :)')
    end

    if not allowed then
      msg.text = ''
    end

  else 
    print('Whitelist not enabled or is sudo')
  end

  return msg
end

local function username_id(cb_extra, success, result)
   local get_cmd = cb_extra.get_cmd
   local receiver = cb_extra.receiver
   local chat_id = cb_extra.chat_id
   local member = cb_extra.member
   local text = 'No @'..member..' in group'
   for k,v in pairs(result.members) do
      vusername = v.username
      if vusername == member then
      	member_username = member
      	member_id = v.id
      	if get_cmd == 'kick' then
      	    return kick_user(member_id, chat_id)
      	elseif get_cmd == 'ban' then
      	    send_large_msg(receiver, 'User @'..member..' ('..member_id..') BANNED!')
      	    return ban_user(member_id, chat_id)
      	elseif get_cmd == 'globalban' then
      	    send_large_msg(receiver, 'User @'..member..' ('..member_id..') GLOBALLY BANNED!!')
      	    return superban_user(member_id, chat_id)
      	elseif get_cmd == 'wlist user' then
      	    local hash = 'whitelist:user#id'..member_id
      	    redis:set(hash, true)
      	    return send_large_msg(receiver, 'User @'..member..' ['..member_id..'] whitelisted')
      	elseif get_cmd == 'wlist delete user' then
      	    local hash = 'whitelist:user#id'..member_id
      	    redis:del(hash)
      	    return send_large_msg(receiver, 'User @'..member..' ['..member_id..'] removed from whitelist')
      	end
      end
   end
   return send_large_msg(receiver, text)
end

local function run(msg, matches)
  if matches[1] == 'kickme' then
  	kick_user(msg.from.id, msg.to.id)
  end
  if not is_momod(msg) then
    return nil
  end
  local receiver = get_receiver(msg)
  if matches[4] then
      get_cmd = matches[1]..' '..matches[2]..' '..matches[3]
  elseif matches[3] then
      get_cmd = matches[1]..' '..matches[2]
  else
      get_cmd = matches[1]
  end

  if matches[1] == 'ban' then
    local user_id = matches[3]
    local chat_id = msg.to.id
    if msg.to.type == 'chat' then
      if matches[2] == '+' then
        if string.match(matches[3], '^%d+$') then
            ban_user(user_id, chat_id)
            send_large_msg(receiver, 'User '..user_id..' BANNED!')
        else
            local member = string.gsub(matches[3], '@', '')
            chat_info(receiver, username_id, {get_cmd=get_cmd, receiver=receiver, chat_id=chat_id, member=member})
        end
      end
      if matches[2] == '-' then
        local hash =  'banned:'..chat_id..':'..user_id
        redis:del(hash)
        return 'User '..user_id..' UNbanned'
      end
    else
      return 'Only work in group'
    end
  end

  if matches[1] == 'globalban' and is_admin(msg) then
    local user_id = matches[3]
    local chat_id = msg.to.id
    if matches[2] == '+' then
        if string.match(matches[3], '^%d+$') then
            superban_user(user_id, chat_id)
            send_large_msg(receiver, 'User '..user_id..' GLOBALLY BANNED!')
        else
            local member = string.gsub(matches[3], '@', '')
            chat_info(receiver, username_id, {get_cmd=get_cmd, receiver=receiver, chat_id=chat_id, member=member})
        end
    end
    if matches[2] == '-' then
        local hash =  'superbanned:'..user_id
        redis:del(hash)
        return 'User '..user_id..' GLOBALLY UNbanned'
    end
  end

  if matches[1] == 'kick' then
    if msg.to.type == 'chat' then
      if string.match(matches[2], '^%d+$') then
          kick_user(matches[2], msg.to.id)
      else
          local member = string.gsub(matches[2], '@', '')
          chat_info(receiver, username_id, {get_cmd=get_cmd, receiver=receiver, chat_id=msg.to.id, member=member})
      end
    else
      return 'Only work in group'
    end
  end

  if matches[1] == 'wlist' then
    if matches[2] == 'enable' and is_sudo(msg) then
      local hash = 'whitelist:enabled'
      redis:set(hash, true)
      return 'Enabled whitelist'
    end

    if matches[2] == 'disable' and is_sudo(msg) then
      local hash = 'whitelist:enabled'
      redis:del(hash)
      return 'Disabled whitelist'
    end

    if matches[2] == 'user' then
      if string.match(matches[3], '^%d+$') then
          local hash = 'whitelist:user#id'..matches[3]
          redis:set(hash, true)
          return 'User '..matches[3]..' whitelisted'
      else
          local member = string.gsub(matches[3], '@', '')
          chat_info(receiver, username_id, {get_cmd=get_cmd, receiver=receiver, chat_id=msg.to.id, member=member})
      end
    end

    if matches[2] == 'chat' then
      if msg.to.type ~= 'chat' then
        return 'This isn\'t a chat group'
      end
      local hash = 'whitelist:chat#id'..msg.to.id
      redis:set(hash, true)
      return 'Chat '..msg.to.print_name..' ['..msg.to.id..'] whitelisted'
    end

    if matches[2] == 'delete' and matches[3] == 'user' then
      if string.match(matches[4], '^%d+$') then
          local hash = 'whitelist:user#id'..matches[4]
          redis:del(hash)
          return 'User '..matches[4]..' removed from whitelist'
      else
          local member = string.gsub(matches[4], '@', '')
          chat_info(receiver, username_id, {get_cmd=get_cmd, receiver=receiver, chat_id=msg.to.id, member=member})
      end
    end

    if matches[2] == 'delete' and matches[3] == 'chat' then
      if msg.to.type ~= 'chat' then
        return 'This isn\'t a chat group'
      end
      local hash = 'whitelist:chat#id'..msg.to.id
      redis:del(hash)
      return 'Chat '..msg.to.print_name..' ['..msg.to.id..'] removed from whitelist'
    end

  end
end

return {
  description = "Group Members Manager System", 
  usage = {
      user = "/kickme : leave group",
      moderator = {
          "/kick (@user) : kick user",
          "/kick (id) : kick user",
          "/ban + (@user) : kick user for ever",
          "/ban + (id) : kick user for ever",
          "/ban - (id) : unban user"
          },
      admin = {
          "/globalban + (@user) : ban user from all groups",
          "/globalban + (id) : ban user from all groups",
          "/globalban - (id) : globally unban user"
          },
      },
  patterns = {
    "^[!/](wlist) (enable)$",
    "^[!/](wlist) (disable)$",
    "^[!/](wlist) (user) (.*)$",
    "^[!/](wlist) (chat)$",
    "^[!/](wlist) (delete) (user) (.*)$",
    "^[!/](wlist) (delete) (chat)$",
    "^[!/](ban) (+) (.*)$",
    "^[!/](ban) (-) (.*)$",
    "^[!/](globalban) (+) (.*)$",
    "^[!/](globalban) (-) (.*)$",
    "^[!/](kick) (.*)$",
    "^[!/](kickme)$",
    "^!!tgservice (.+)$",
  }, 
  run = run,
  pre_process = pre_process
}
