do

local function run(msg, matches)
  if matches[1]:lower() == 'telemanager' or 'telemanagerplus' then --change this with anything you want
    send_document(get_receiver(msg), "./data/me/telemanager.webp", ok_cb, false) --put here sticker location(if you want)
      return [[ 
  
TeleManagerPlus (Open Source) V 3.0.0
    Advanced ManagerBot Based On TeleSeed
    
    Edited By : @holyscrolls
    
    Our Telegram Channel ID :
    @antispam_king_team
  
    Speacial Thanks To My friends :
    @soroushtaj
    @mahsa
    @sud0
    @evil_danger
    and other that help me for this Bot
     GitHub :
     Https://github.com/holyscroll/holyscroll


 ]]
  end
end

return {
  patterns = {
    "^[!/]([Tt]elemanager)$",
    "^([Tt]elemanager)$",
    "^[!/]([Tt]elemanagerplus)$",
    "^([Tt]elemanagerplus)$",
    "^(@telemanagerplus)$",
    
    },
  run = run
}
end
