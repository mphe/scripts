#!/bin/bash
#
# antergos-notify.sh
#
# Copyright © 2016-2017 Antergos
#
# antergos-notify is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# antergos-notify is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with antergos-notify; if not, see <http://www.gnu.org/licenses/>.

# Used to print reboot message when upgrading a system package.
# Add a file /etc/pacman.d/hooks/reboot-notif.hook with the following content:
#
# [Trigger]
# Operation = Upgrade
# Operation = Install
# Operation = Remove
# Type = Package
# Target = linux*
# Target = systemd*
# Target = xorg-*
# Target = xf86-*
# Target = nvidia*
# Target = mesa
# Target = *wayland*
# Target = intel-ucode
#
# [Action]
# Description = Checking core system packages
# When = PostTransaction
# Depends = libnotify
# Exec = /bin/bash -c '/home/marvin/scripts/antergos-alerts.sh "Reboot required" "System packages were modified"'

maybe_display_desktop_alert() {
	if [[ -e '/usr/bin/pacman-boot' ]]; then
		# We're running on antergos-iso
		return
	fi

	_command="/usr/bin/notify-send -u critical -t 0 \"$1\" \"$2\""
	_addr='DBUS_SESSION_BUS_ADDRESS'

	_processes=($(ps aux | grep '[d]bus-daemon --session' | awk '{print $2}' | xargs))

	for _i in $(seq 1 ${#_processes[@]}); do
		_pid="${_processes[(_i - 1)]}"
		_user=$(ps axo user:32,pid | grep "${_processes[(_i - 1)]}" | awk '{print $1}' | xargs)
		_dbus="$(grep -z ${_addr} /proc/${_pid}/environ 2>/dev/null | tr '\0' '\n' | sed -e s/${_addr}=//)"

		[[ -z "${_dbus}" ]] && continue

		DBUS_SESSION_BUS_ADDRESS="${_dbus}" DISPLAY=":0" su "${_user}" -c "${_command}"
	done
}

maybe_display_desktop_alert "$@"

exit 0
