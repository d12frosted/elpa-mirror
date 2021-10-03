;;; terraform-doc.el --- Look up terraform documentation on the fly -*- lexical-binding: t -*-

;; Copyright (C) 2019 Giap Tran <txgvnn@gmail.com>

;; Author: Giap Tran <txgvnn@gmail.com>
;; URL: https://github.com/TxGVNN/terraform-doc
;; Package-Version: 20211003.1333
;; Package-Commit: 16179e57ce290190c222b27961900657a1981330
;; Version: 1.2.0
;; Package-Requires: ((emacs "24.4"))
;; Keywords: comm

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; M-x terraform-doc

;;; Code:

(require 'shr)

(defgroup terraform nil
  "Major mode of `terraform-doc' file."
  :group 'languages
  :prefix "terraform-doc-")

(defcustom terraform-doc-hook nil
  "*Hook run by `terraform-doc'."
  :type 'hook
  :group 'terraform)

(defcustom terraform-doc-name "Terraform-Doc"
  "*Modeline of `terraform-doc'."
  :type 'string
  :group 'terraform)

(defvar terraform-doc-mode-map
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap (kbd "o") 'terraform-doc-at-point)
    (define-key keymap (kbd "RET") 'terraform-doc-at-point)
    (define-key keymap (kbd "<tab>") 'shr-next-link)
    (define-key keymap (kbd "TAB") 'shr-next-link)
    (define-key keymap (kbd "n") 'next-line)
    (define-key keymap (kbd "p") 'previous-line)
    keymap)
  "Keymap for Terraform-Doc major mode.")


(defvar terraform-doc-providers
  '(("ACME" . "acme") ("Akamai" . "akamai") ("Alibaba Cloud" . "alicloud") ("Archive" . "archive") ("Arukas" . "arukas") ("Auth0" . "auth0") ("Avi Vantage" . "avi") ("Aviatrix" . "aviatrix") ("AWS" . "aws") ("Azure" . "azurerm") ("Azure Active Directory" . "azuread") ("Azure DevOps" . "azuredevops") ("Azure Stack" . "azurestack") ("A10 Networks" . "vthunder") ("BaiduCloud" . "baiducloud") ("Bitbucket" . "bitbucket") ("Brightbox" . "brightbox") ("CenturyLinkCloud" . "clc") ("Check Point" . "checkpoint") ("Chef" . "chef") ("CherryServers" . "cherryservers") ("Circonus" . "circonus") ("Cisco ASA" . "ciscoasa") ("Cisco ACI" . "aci") ("Cisco MSO" . "mso") ("CloudAMQP" . "cloudamqp") ("Cloudflare" . "cloudflare") ("Cloud-init" . "cloudinit") ("CloudScalech" . "cloudscale") ("CloudStack" . "cloudstack") ("Cobbler" . "cobbler") ("Cohesity" . "cohesity") ("Constellix" . "constellix") ("Consul" . "consul")
    ("Datadog" . "datadog") ("DigitalOcean" . "do") ("DNS" . "dns") ("DNSimple" . "dnsimple") ("DNSMadeEasy" . "dme") ("Docker" . "docker") ("Dome9" . "dome9") ("Dyn" . "dyn") ("EnterpriseCloud" . "ecl") ("Exoscale" . "exoscale") ("External" . "external") ("F5 BIG-IP" . "bigip") ("Fastly" . "fastly") ("FlexibleEngine" . "flexibleengine") ("FortiOS" . "fortios") ("Genymotion" . "genymotion") ("GitHub" . "github") ("GitLab" . "gitlab") ("Google Cloud Platform" . "google") ("Grafana" . "grafana") ("Gridscale" . "gridscale") ("Hedvig" . "hedvig") ("Helm" . "helm") ("Heroku" . "heroku") ("Hetzner Cloud" . "hcloud") ("HTTP" . "http") ("HuaweiCloud" . "huaweicloud") ("HuaweiCloudStack" . "huaweicloudstack") ("Icinga2" . "icinga2")
    ("Ignition" . "ignition") ("Incapsula" . "incapsula") ("InfluxDB" . "influxdb") ("Infoblox" . "infoblox") ("JDCloud" . "jdcloud") ("KingsoftCloud" . "ksyun") ("Kubernetes" . "kubernetes") ("Lacework" . "lacework") ("LaunchDarkly" . "launchdarkly") ("Librato" . "librato") ("Linode" . "linode") ("Local" . "local") ("Logentries" . "logentries") ("LogicMonitor" . "logicmonitor") ("Mailgun" . "mailgun") ("MetalCloud" . "metalcloud") ("MongoDB Atlas" . "mongodbatlas") ("MySQL" . "mysql") ("Naver Cloud" . "ncloud") ("Netlify" . "netlify") ("Nomad" . "nomad") ("NS1" . "ns1") ("Nutanix" . "nutanix") ("1 & 1" . "oneandone") ("Okta" . "okta") ("Okta Advanced Server Access" . "oktaasa") ("OpenNebula" . "opennebula") ("OpenStack" . "openstack") ("OpenTelekomCloud" . "opentelekomcloud") ("OpsGenie" . "opsgenie")
    ("Oracle Cloud Infrastructure" . "oci") ("Oracle Cloud Platform" . "oraclepaas") ("Oracle Public Cloud" . "opc") ("OVH" . "ovh") ("Packet" . "packet") ("PagerDuty" . "pagerduty") ("Palo Alto Networks PANOS" . "panos") ("Palo Alto Networks PrismaCloud" . "prismacloud") ("PostgreSQL" . "postgresql") ("PowerDNS" . "powerdns") ("ProfitBricks" . "profitbricks") ("Pureport" . "pureport") ("RabbitMQ" . "rabbitmq") ("Rancher" . "rancher") ("Rancher2" . "rancher2") ("RightScale" . "rightscale") ("Rubrik" . "rubrik") ("Rundeck" . "rundeck") ("RunScope" . "runscope") ("Scaleway" . "scaleway") ("Selectel" . "selectel") ("SignalFx" . "signalfx") ("Skytap" . "skytap")
    ("SoftLayer" . "softlayer") ("Spotinst" . "spotinst") ("StackPath" . "stackpath") ("StatusCake" . "statuscake") ("Sumo Logic" . "sumologic") ("TelefonicaOpenCloud" . "telefonicaopencloud") ("Template" . "template") ("TencentCloud" . "tencentcloud") ("Terraform" . "terraform") ("Terraform Cloud" . "tfe") ("Time" . "time") ("TLS" . "tls") ("Triton" . "triton") ("Turbot" . "turbot") ("UCloud" . "ucloud") ("UltraDNS" . "ultradns") ("Vault" . "vault") ("Venafi" . "venafi") ("VMware Cloud" . "vmc") ("VMware NSX-T" . "nsxt") ("VMware vCloud Director" . "vcd") ("VMware vRA7" . "vra7") ("VMware vSphere" . "vsphere") ("Vultr" . "vultr") ("Wavefront" . "wavefront") ("Yandex" . "yandex")))

;;;###autoload
(defun terraform-doc (&optional provider)
  "Look up PROVIDER."
  (interactive (list
                (assoc (completing-read
                        "Provider: "
                        (mapcar (lambda (x) (car x)) terraform-doc-providers))
                       terraform-doc-providers)))
  (if (member provider terraform-doc-providers)
      (terraform-doc--render-tree (cdr provider) (format "*Terraform:%s*" (cdr provider)))
    (message "%s" (propertize "Provider is not valid"))))

(defun terraform-doc-at-point()
  "Render url by 'terraform-doc--render-object."
  (interactive)
  (if (get-text-property (point) 'shr-url)
      (let* ((url (get-text-property (point) 'shr-url))
             (buffer-name (string-join (last (split-string url "/") 2) "/"))
             (provider (replace-regexp-in-string ".*terraform-provider-\\(.+?\\)/.*" "\\1" url)))
        (terraform-doc--render-object url (format "*Terraform:%s:%s*" provider buffer-name)))))

(defun terraform-doc--render-tree (provider buffer-name)
  "Render the PROVIDER and rename to BUFFER-NAME."
  (if (get-buffer buffer-name)
      (switch-to-buffer buffer-name)
    (with-current-buffer (get-buffer-create buffer-name)
      (insert (format "<a href=\"/terraform-providers/terraform-provider-%s/HEAD/website/docs/index.html.markdown\">Provider</a><br/>" provider))
      (let ((content))
        (dolist (url '("d" "r"))
          (with-current-buffer
              (url-retrieve-synchronously
               (format "https://github.com/terraform-providers/terraform-provider-%s/file-list/HEAD/website/docs/%s" provider url))
            (goto-char (point-min))
            (search-forward-regexp "\n\n" )
            (delete-region (point) (point-min))
            (let* ((html-dom-tree (libxml-parse-html-region (point-min) (point-max)))
                   (dives (dom-elements html-dom-tree 'role "rowheader"))
                   (j 0) (div nil) (file nil) (url_type nil) (formatted_str nil))
              (erase-buffer)
              (while (< j (length dives))
                (setq div (elt dives j))
                (setq file (dom-by-class div "Link--primary"))
                (unless (not file)
                  (setq url_type (if (string= "d" url) "data" "resource"))
                  (setq formatted_str (car (split-string (dom-text file) "\\.")))
                  (setcdr (cdr (car file)) (list (format "%s/%s" url_type formatted_str)))
                  (xml-print file)
                  (insert "<br/>"))
                (setq j (+ j 1))))
            (setq content (buffer-string)))
          (insert content))
        (goto-char (point-min))
        (while (re-search-forward "href=\"" nil t)
          (replace-match "href=\"https://raw.githubusercontent.com" nil nil))
        (goto-char (point-min))
        (while (re-search-forward "/blob" nil t)
          (replace-match "" nil nil))
        (shr-render-region (point-min) (point-max))
        (terraform-doc-mode-on)
        (switch-to-buffer (current-buffer))))))

(defun terraform-doc--render-object (url buffer-name)
  "Render the URL and rename to BUFFER-NAME."
  (if (get-buffer buffer-name)
      (switch-to-buffer buffer-name)
    (url-retrieve
     url
     (lambda (arg)
       (cond
        ((equal :error (car arg))
         (message arg))
        (t
         (goto-char (point-min))
         (search-forward-regexp "\n\n" )
         (delete-region (point) (point-min))
         (rename-buffer buffer-name)
         (if (fboundp 'markdown-mode)
             (markdown-mode))
         (setq buffer-read-only t)
         (switch-to-buffer (current-buffer))))))))

(defun terraform-doc-mode-on ()
  "Render and switch to ‘terraform-doc’ mode."
  (goto-char (point-min))
  (terraform-doc-mode))

(define-derived-mode terraform-doc-mode special-mode terraform-doc-name
  "Major mode for looking up terraform documentation on the fly."
  (local-set-key [remap shr-browse-url] 'terraform-doc-at-point)
  (setq buffer-auto-save-file-name nil
        buffer-read-only t))

(provide 'terraform-doc)
;;; terraform-doc.el ends here
