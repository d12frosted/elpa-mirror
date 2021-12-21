;;; counsel-world-clock.el --- Display world clock using Ivy.

;; Author: Kuang Chen <http://github.com/kchenphy>
;; URL: https://github.com/kchenphy/counsel-world-clock
;; Package-Version: 20190709.2211
;; Package-Commit: 674e4c6b82a92ea765af97cc5f017b357284c7dc
;; Version: 0.2.1
;; Package-Requires: ((ivy "0.9.0") (s "1.12.0"))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; Make it easy to check local time in various time zones.

;;; Code:
(require 's)
(require 'ivy)

(defcustom counsel-world-clock-time-format
  "%b %d, %a, %H:%M (%/h)"
  "Time format for ‘counsel-world-clock’.
It is similiar to the format string passed to `format-time-string', but
in addition introduces \"%/\", which is replaced with the hour difference
between the target time zone and system time zone."
  :type '(string)
  :group 'convenience
  )

(defconst counsel-world-clock--time-zones
  '(
    "Africa/Abidjan"
    "Africa/Accra"
    "Africa/Addis_Ababa"
    "Africa/Algiers"
    "Africa/Asmara"
    "Africa/Bamako"
    "Africa/Bangui"
    "Africa/Banjul"
    "Africa/Bissau"
    "Africa/Blantyre"
    "Africa/Brazzaville"
    "Africa/Bujumbura"
    "Africa/Cairo"
    "Africa/Casablanca"
    "Africa/Ceuta"
    "Africa/Conakry"
    "Africa/Dakar"
    "Africa/Dar_es_Salaam"
    "Africa/Djibouti"
    "Africa/Douala"
    "Africa/El_Aaiun"
    "Africa/Freetown"
    "Africa/Gaborone"
    "Africa/Harare"
    "Africa/Johannesburg"
    "Africa/Juba"
    "Africa/Kampala"
    "Africa/Khartoum"
    "Africa/Kigali"
    "Africa/Kinshasa"
    "Africa/Lagos"
    "Africa/Libreville"
    "Africa/Lome"
    "Africa/Luanda"
    "Africa/Lubumbashi"
    "Africa/Lusaka"
    "Africa/Malabo"
    "Africa/Maputo"
    "Africa/Maseru"
    "Africa/Mbabane"
    "Africa/Mogadishu"
    "Africa/Monrovia"
    "Africa/Nairobi"
    "Africa/Ndjamena"
    "Africa/Niamey"
    "Africa/Nouakchott"
    "Africa/Ouagadougou"
    "Africa/Porto-Novo"
    "Africa/Sao_Tome"
    "Africa/Tripoli"
    "Africa/Tunis"
    "Africa/Windhoek"
    "America/Adak"
    "America/Anchorage"
    "America/Anguilla"
    "America/Antigua"
    "America/Araguaina"
    "America/Argentina/Buenos_Aires"
    "America/Argentina/Catamarca"
    "America/Argentina/Cordoba"
    "America/Argentina/Jujuy"
    "America/Argentina/La_Rioja"
    "America/Argentina/Mendoza"
    "America/Argentina/Rio_Gallegos"
    "America/Argentina/Salta"
    "America/Argentina/San_Juan"
    "America/Argentina/San_Luis"
    "America/Argentina/Tucuman"
    "America/Argentina/Ushuaia"
    "America/Aruba"
    "America/Asuncion"
    "America/Atikokan"
    "America/Bahia"
    "America/Bahia_Banderas"
    "America/Barbados"
    "America/Belem"
    "America/Belize"
    "America/Blanc-Sablon"
    "America/Boa_Vista"
    "America/Bogota"
    "America/Boise"
    "America/Cambridge_Bay"
    "America/Campo_Grande"
    "America/Cancun"
    "America/Caracas"
    "America/Cayenne"
    "America/Cayman"
    "America/Chicago"
    "America/Chihuahua"
    "America/Costa_Rica"
    "America/Creston"
    "America/Cuiaba"
    "America/Curacao"
    "America/Danmarkshavn"
    "America/Dawson"
    "America/Dawson_Creek"
    "America/Denver"
    "America/Detroit"
    "America/Dominica"
    "America/Edmonton"
    "America/Eirunepe"
    "America/El_Salvador"
    "America/Fort_Nelson"
    "America/Fortaleza"
    "America/Glace_Bay"
    "America/Godthab"
    "America/Goose_Bay"
    "America/Grand_Turk"
    "America/Grenada"
    "America/Guadeloupe"
    "America/Guatemala"
    "America/Guayaquil"
    "America/Guyana"
    "America/Halifax"
    "America/Havana"
    "America/Hermosillo"
    "America/Indiana/Indianapolis"
    "America/Indiana/Knox"
    "America/Indiana/Marengo"
    "America/Indiana/Petersburg"
    "America/Indiana/Tell_City"
    "America/Indiana/Vevay"
    "America/Indiana/Vincennes"
    "America/Indiana/Winamac"
    "America/Inuvik"
    "America/Iqaluit"
    "America/Jamaica"
    "America/Juneau"
    "America/Kentucky/Louisville"
    "America/Kentucky/Monticello"
    "America/Kralendijk"
    "America/La_Paz"
    "America/Lima"
    "America/Los_Angeles"
    "America/Lower_Princes"
    "America/Maceio"
    "America/Managua"
    "America/Manaus"
    "America/Marigot"
    "America/Martinique"
    "America/Matamoros"
    "America/Mazatlan"
    "America/Menominee"
    "America/Merida"
    "America/Metlakatla"
    "America/Mexico_City"
    "America/Miquelon"
    "America/Moncton"
    "America/Monterrey"
    "America/Montevideo"
    "America/Montserrat"
    "America/Nassau"
    "America/New_York"
    "America/Nipigon"
    "America/Nome"
    "America/Noronha"
    "America/North_Dakota/Beulah"
    "America/North_Dakota/Center"
    "America/North_Dakota/New_Salem"
    "America/Ojinaga"
    "America/Panama"
    "America/Pangnirtung"
    "America/Paramaribo"
    "America/Phoenix"
    "America/Port-au-Prince"
    "America/Port_of_Spain"
    "America/Porto_Velho"
    "America/Puerto_Rico"
    "America/Punta_Arenas"
    "America/Rainy_River"
    "America/Rankin_Inlet"
    "America/Recife"
    "America/Regina"
    "America/Resolute"
    "America/Rio_Branco"
    "America/Santarem"
    "America/Santiago"
    "America/Santo_Domingo"
    "America/Sao_Paulo"
    "America/Scoresbysund"
    "America/Sitka"
    "America/St_Barthelemy"
    "America/St_Johns"
    "America/St_Kitts"
    "America/St_Lucia"
    "America/St_Thomas"
    "America/St_Vincent"
    "America/Swift_Current"
    "America/Tegucigalpa"
    "America/Thule"
    "America/Thunder_Bay"
    "America/Tijuana"
    "America/Toronto"
    "America/Tortola"
    "America/Vancouver"
    "America/Whitehorse"
    "America/Winnipeg"
    "America/Yakutat"
    "America/Yellowknife"
    "Antarctica/Casey"
    "Antarctica/Davis"
    "Antarctica/DumontDUrville"
    "Antarctica/Macquarie"
    "Antarctica/Mawson"
    "Antarctica/McMurdo"
    "Antarctica/Palmer"
    "Antarctica/Rothera"
    "Antarctica/Syowa"
    "Antarctica/Troll"
    "Antarctica/Vostok"
    "Arctic/Longyearbyen"
    "Asia/Aden"
    "Asia/Almaty"
    "Asia/Amman"
    "Asia/Anadyr"
    "Asia/Aqtau"
    "Asia/Aqtobe"
    "Asia/Ashgabat"
    "Asia/Atyrau"
    "Asia/Baghdad"
    "Asia/Bahrain"
    "Asia/Baku"
    "Asia/Bangkok"
    "Asia/Barnaul"
    "Asia/Beirut"
    "Asia/Bishkek"
    "Asia/Brunei"
    "Asia/Chita"
    "Asia/Choibalsan"
    "Asia/Colombo"
    "Asia/Damascus"
    "Asia/Dhaka"
    "Asia/Dili"
    "Asia/Dubai"
    "Asia/Dushanbe"
    "Asia/Famagusta"
    "Asia/Gaza"
    "Asia/Hebron"
    "Asia/Ho_Chi_Minh"
    "Asia/Hong_Kong"
    "Asia/Hovd"
    "Asia/Irkutsk"
    "Asia/Jakarta"
    "Asia/Jayapura"
    "Asia/Jerusalem"
    "Asia/Kabul"
    "Asia/Kamchatka"
    "Asia/Karachi"
    "Asia/Kathmandu"
    "Asia/Khandyga"
    "Asia/Kolkata"
    "Asia/Krasnoyarsk"
    "Asia/Kuala_Lumpur"
    "Asia/Kuching"
    "Asia/Kuwait"
    "Asia/Macau"
    "Asia/Magadan"
    "Asia/Makassar"
    "Asia/Manila"
    "Asia/Muscat"
    "Asia/Nicosia"
    "Asia/Novokuznetsk"
    "Asia/Novosibirsk"
    "Asia/Omsk"
    "Asia/Oral"
    "Asia/Phnom_Penh"
    "Asia/Pontianak"
    "Asia/Pyongyang"
    "Asia/Qatar"
    "Asia/Qyzylorda"
    "Asia/Riyadh"
    "Asia/Sakhalin"
    "Asia/Samarkand"
    "Asia/Seoul"
    "Asia/Shanghai"
    "Asia/Singapore"
    "Asia/Srednekolymsk"
    "Asia/Taipei"
    "Asia/Tashkent"
    "Asia/Tbilisi"
    "Asia/Tehran"
    "Asia/Thimphu"
    "Asia/Tokyo"
    "Asia/Tomsk"
    "Asia/Ulaanbaatar"
    "Asia/Urumqi"
    "Asia/Ust-Nera"
    "Asia/Vientiane"
    "Asia/Vladivostok"
    "Asia/Yakutsk"
    "Asia/Yangon"
    "Asia/Yekaterinburg"
    "Asia/Yerevan"
    "Atlantic/Azores"
    "Atlantic/Bermuda"
    "Atlantic/Canary"
    "Atlantic/Cape_Verde"
    "Atlantic/Faroe"
    "Atlantic/Madeira"
    "Atlantic/Reykjavik"
    "Atlantic/South_Georgia"
    "Atlantic/St_Helena"
    "Atlantic/Stanley"
    "Australia/Adelaide"
    "Australia/Brisbane"
    "Australia/Broken_Hill"
    "Australia/Currie"
    "Australia/Darwin"
    "Australia/Eucla"
    "Australia/Hobart"
    "Australia/Lindeman"
    "Australia/Lord_Howe"
    "Australia/Melbourne"
    "Australia/Perth"
    "Australia/Sydney"
    "Europe/Amsterdam"
    "Europe/Andorra"
    "Europe/Astrakhan"
    "Europe/Athens"
    "Europe/Belgrade"
    "Europe/Berlin"
    "Europe/Bratislava"
    "Europe/Brussels"
    "Europe/Bucharest"
    "Europe/Budapest"
    "Europe/Busingen"
    "Europe/Chisinau"
    "Europe/Copenhagen"
    "Europe/Dublin"
    "Europe/Gibraltar"
    "Europe/Guernsey"
    "Europe/Helsinki"
    "Europe/Isle_of_Man"
    "Europe/Istanbul"
    "Europe/Jersey"
    "Europe/Kaliningrad"
    "Europe/Kiev"
    "Europe/Kirov"
    "Europe/Lisbon"
    "Europe/Ljubljana"
    "Europe/London"
    "Europe/Luxembourg"
    "Europe/Madrid"
    "Europe/Malta"
    "Europe/Mariehamn"
    "Europe/Minsk"
    "Europe/Monaco"
    "Europe/Moscow"
    "Europe/Oslo"
    "Europe/Paris"
    "Europe/Podgorica"
    "Europe/Prague"
    "Europe/Riga"
    "Europe/Rome"
    "Europe/Samara"
    "Europe/San_Marino"
    "Europe/Sarajevo"
    "Europe/Saratov"
    "Europe/Simferopol"
    "Europe/Skopje"
    "Europe/Sofia"
    "Europe/Stockholm"
    "Europe/Tallinn"
    "Europe/Tirane"
    "Europe/Ulyanovsk"
    "Europe/Uzhgorod"
    "Europe/Vaduz"
    "Europe/Vatican"
    "Europe/Vienna"
    "Europe/Vilnius"
    "Europe/Volgograd"
    "Europe/Warsaw"
    "Europe/Zagreb"
    "Europe/Zaporozhye"
    "Europe/Zurich"
    "Indian/Antananarivo"
    "Indian/Chagos"
    "Indian/Christmas"
    "Indian/Cocos"
    "Indian/Comoro"
    "Indian/Kerguelen"
    "Indian/Mahe"
    "Indian/Maldives"
    "Indian/Mauritius"
    "Indian/Mayotte"
    "Indian/Reunion"
    "Pacific/Apia"
    "Pacific/Auckland"
    "Pacific/Bougainville"
    "Pacific/Chatham"
    "Pacific/Chuuk"
    "Pacific/Easter"
    "Pacific/Efate"
    "Pacific/Enderbury"
    "Pacific/Fakaofo"
    "Pacific/Fiji"
    "Pacific/Funafuti"
    "Pacific/Galapagos"
    "Pacific/Gambier"
    "Pacific/Guadalcanal"
    "Pacific/Guam"
    "Pacific/Honolulu"
    "Pacific/Kiritimati"
    "Pacific/Kosrae"
    "Pacific/Kwajalein"
    "Pacific/Majuro"
    "Pacific/Marquesas"
    "Pacific/Midway"
    "Pacific/Nauru"
    "Pacific/Niue"
    "Pacific/Norfolk"
    "Pacific/Noumea"
    "Pacific/Pago_Pago"
    "Pacific/Palau"
    "Pacific/Pitcairn"
    "Pacific/Pohnpei"
    "Pacific/Port_Moresby"
    "Pacific/Rarotonga"
    "Pacific/Saipan"
    "Pacific/Tahiti"
    "Pacific/Tarawa"
    "Pacific/Tongatapu"
    "Pacific/Wake"
    "Pacific/Wallis")
  "All supported time zones."
  )

(defun counsel-world-clock--offset (time-zone)
  "Get the UTC offset in hour for given TIME-ZONE.
If TIME-ZONE is nil, system time zone is returned."
  (/
   (car (current-time-zone
	 nil
	 time-zone))
   3600))

(defconst counsel-world-clock--system-offset
  (counsel-world-clock--offset nil)
  "UTC offset of system's time zone.")

(defun counsel-world-clock--diff-from-system (time-zone)
  "Get the difference in hour between TIME-ZONE and system time zone."
  (-
   (counsel-world-clock--offset time-zone)
   counsel-world-clock--system-offset))

(defun counsel-world-clock--format-time-string (format-string time-zone)
  "Use FORMAT-STRING to format current time in a given TIME-ZONE.

FORMAT-STRING is similar to the argument passed to `format-time-string'.
In addition to the standard format placeholders, \"%/\" is
added which is replaced by the return value of
`counsel-world-clock--diff-from-system'."
  (let* ((diff (format
		"%+3d"
		(counsel-world-clock--diff-from-system
		 time-zone)))
	 (fmt (s-replace
	       "%/"
	       diff
	       format-string)))
    (format-time-string
     fmt
     (current-time)
     time-zone)))

(defun counsel-world-clock--local-time (time-zone)
  "Get current local time in TIME-ZONE."
  (counsel-world-clock--format-time-string
   counsel-world-clock-time-format
   time-zone))

(defun counsel-world-clock--decorate-candidate (time-zone)
  "Decorate a TIME-ZONE candidate, by appending local time."
  (format
   "%-40s%s"
   time-zone
   (counsel-world-clock--local-time
    time-zone)))

(defun counsel-world-clock--format-function (candidates)
  "Customized Ivy format function, which displays decorated time-zone CANDIDATES."
  (ivy--format-function-generic
   (lambda (time-zone)
     (ivy--add-face
      (counsel-world-clock--decorate-candidate
       time-zone)
      'ivy-current-match))
   'counsel-world-clock--decorate-candidate
   candidates
   "\n"))

;;;###autoload
(defun counsel-world-clock ()
  "Display time in different time zone in echo area."
  (interactive)
  (let ((ivy-format-function #'counsel-world-clock--format-function))
    (ivy-read
     "Time zone: "
     counsel-world-clock--time-zones
     :caller 'counsel-world-clock
     :action (lambda (time-zone)
	       (message
		"Local time in %s is %s"
		time-zone
		(counsel-world-clock--local-time time-zone))))))

(provide 'counsel-world-clock)
;;; counsel-world-clock.el ends here
