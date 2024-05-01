#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

##############
# SET SYSTEM #
##############

echo " "
bashio::log.info "Setting password for the user pi"
echo "pi:$(bashio::log.config "pi_password")" | sudo chpasswd
echo "... done"

echo " "
bashio::log.info "Starting system services"

# Set TZ
if bashio::config.has_value 'TZ'; then
    TIMEZONE=$(bashio::config 'TZ')
    echo "... setting timezone to $TIMEZONE"
    ln -snf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
    echo "$TIMEZONE" >/etc/timezone
fi || (bashio::log.fatal "Error : $TIMEZONE not found. Here is a list of valid timezones : https://manpages.ubuntu.com/manpages/focal/man3/DateTime::TimeZone::Catalog.3pm.html")

# Correcting systemctl
echo "... correcting systemctl"
curl -f -L -s -S https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py -o /bin/systemctl
chmod a+x /bin/systemctl

# Correct language labels
export "$(grep "^DATABASE_LANG" /config/birdnet.conf)"
# Saving default of en
cp "$HOME"/BirdNET-Pi/model/labels.txt "$HOME"/BirdNET-Pi/model/labels.bak
# Adapt to new language
echo "... adapting labels according to birdnet.conf file to $DATABASE_LANG"
/."$HOME"/BirdNET-Pi/scripts/install_language_label_nm.sh -l "$DATABASE_LANG"

# Starting dbus
echo "... starting dbus"
service dbus start

# Starting services
echo ""
bashio::log.info "Starting BirdNET-Pi services"
chmod +x "$HOME"/BirdNET-Pi/scripts/restart_services.sh
sudo -u pi "$HOME"/BirdNET-Pi/scripts/restart_services.sh

bashio::log.info "Starting upstream container"