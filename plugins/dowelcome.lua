local function run(msg, matches, callback, extra)

local data = load_data(_config.moderation.data)

local group_welcome = data[tostring(msg.to.id)]['group_welcome']

if matches[1] == 'chat_add_user' or 'chat_add_user_link' then --For Normal Group
    if not msg.service then 
        return nil 
    else
if string.match(group_welcome, '{gpname}') then group_welcome = string.gsub(group_welcome, '{gpname}', ""..string.gsub(msg.to.print_name, "_", " ").."")
 end
if string.match(group_welcome, '{firstname}') then group_welcome = string.gsub(group_welcome, '{firstname}', ""..(msg.action.user.first_name or '').."")
 end
if string.match(group_welcome, '{lastname}') then group_welcome = string.gsub(group_welcome, '{lastname}', ""..(msg.action.user.last_name or '').."")
 end
if string.match(group_welcome, '{username}') then group_welcome = string.gsub(group_welcome, '{username}', "@"..(msg.action.user.username or '').."")
 end
return group_welcome
end
end
end
return {
  patterns = {
  "^!!tgservice (chat_add_user)$",
  "^!!tgservice (chat_add_user_link)$",
  },
  run = run,
  pre_process = pre_process
}
