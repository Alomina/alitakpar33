local function run(msg, matches)
    if is_owner(msg) then
        return
    end
    local data = load_data(_config.moderation.data)
    if data[tostring(msg.to.id)] then
        if data[tostring(msg.to.id)]['settings'] then
            if data[tostring(msg.to.id)]['settings']['lock_chat'] then
                lock_gif = data[tostring(msg.to.id)]['settings']['lock_chat']
            end
        end
    end
    local chat = get_receiver(msg)
    local user = "user#id"..msg.from.id
    if lock_gif == "yes" then
        send_large_msg(chat, 'Gif is not allowed in this chat!')
		      savelog(msg.to.id,"@teleking_spam ["..msg.from.id.."] kicked user [gif was locked] !")-- Save to logs
        chat_del_user(chat, user, ok_cb, true)
    end
end
 
return {
  patterns = {
     "(.+)"
  },
  run = run
}
