local function run(msg, matches)
    if is_owner(msg) then
        return
    end
    local data = load_data(_config.moderation.data)
    if data[tostring(msg.to.id)] then
        if data[tostring(msg.to.id)]['settings'] then
            if data[tostring(msg.to.id)]['settings']['lock_farsi'] then
                lock_gif = data[tostring(msg.to.id)]['settings']['lock_farsi']
            end
        end
    end
    local chat = get_receiver(msg)
    local user = "user#id"..msg.from.id
    if lock_gif == "yes" then
        send_large_msg(chat, 'farsi is not allowed in this chat!')
		      savelog(msg.to.id," ["..msg.from.id.."] kicked user [farsi was locked] !")-- Save to logs
        chat_del_user(chat, user, ok_cb, true)
    end
end
 
return {
  patterns = {
"ض",
"ص",
"ث",
"ق",
"ف",
"غ",
"ع",
"ه",
"خ",
"ح",
"ج",
"چ",
"پ",
"ش",
"س",
"ی",
"ب",
"ل",
"ا",
"ت",
"ن",
"م",
"ک",
"گ",
"ظ",
"ط",
"ز",
"ر",
"ذ",
"د",
"ئ",
"و"
  },
  run = run
}
