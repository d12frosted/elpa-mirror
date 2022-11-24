;;; jenkinsfile-mode.el --- Major mode for editing Jenkins declarative pipeline syntax -*- lexical-binding: t -*-

;; Copyright (c) 2019 John Louis Del Rosario
;; Package-Requires: ((emacs "24") (groovy-mode "2.0"))
;; Package-Commit: 1d90c1ff8edc7ea88844af92a206e7c5f083b568
;; Package-Version: 20221124.30
;; Package-X-Original-Version: 0.0.1
;; Homepage: https://github.com/john2x/jenkinsfile-mode
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Provides a major mode `jenkinsfile-mode' (derived from groovy-mode)
;; for editing Jenkins declarative pipeline files.

;;; Code:

(require 'groovy-mode)

(defcustom jenkinsfile-mode-vim-source-url
  "https://raw.githubusercontent.com/martinda/Jenkinsfile-vim-syntax/master/syntax/Jenkinsfile.vim"
  "URL to Jenkinsfile.vim source file."
  :group 'jenkinsfile-mode
  :type 'string)

(defcustom jenkinsfile-mode-indent-offset 4
  "Indentation width to use."
  :group 'jenkinsfile-mode
  :type 'integer)

(defvar jenkinsfile-mode--file-section-keywords
  '("pipeline" "agent" "stages" "steps" "post"))

(defvar jenkinsfile-mode--directive-keywords
  '("environment" "options" "parameters" "triggers" "stage" "tools" "input" "when" "libraries"))

(defvar jenkinsfile-mode--option-keywords
  '("contained" "buildDiscarder"
    "disableConcurrentBuilds" "overrideIndexTriggers"
    "skipDefaultCheckout" "nextgroup=jenkinsfileOptionParams" "contained"
    "skipStagesAfterUnstable" "checkoutToSubdirectory" "timeout" "retry"
    "timestamps" "nextgroup=jenkinsfileOptionParams"))

(defvar jenkinsfile-mode--core-step-keywords
  '("checkout" "docker"
    "dockerfile" "skipwhite" "nextgroup=jenkinsFileDockerConfigBlock"
    "node" "scm" "sh" "stage" "parallel" "steps" "step" "tool" "always"
    "changed" "failure" "success" "unstable" "aborted" "unsuccessful"
    "regression" "fixed" "cleanup"))

(defvar jenkinsfile-mode--pipeline-step-keywords
  '("Applitools"
    "ArtifactoryGradleBuild" "Consul" "MavenDescriptorStep" "OneSky"
    "VersionNumber" "ViolationsToBitbucketServer" "ViolationsToGitHub"
    "ViolationsToGitLab" "_OcAction" "_OcContextInit" "_OcWatch"
    "acceptGitLabMR" "acsDeploy" "activateDTConfiguration" "addBadge"
    "addErrorBadge" "addGitLabMRComment" "addInfoBadge"
    "addInteractivePromotion" "addShortText" "addWarningBadge" "allure"
    "anchore" "androidApkMove" "androidApkUpload" "androidLint"
    "ansiColor" "ansiblePlaybook" "ansibleTower" "ansibleVault"
    "appMonBuildEnvironment" "appMonPublishTestResults"
    "appMonRegisterTestRun" "applatix" "approveReceivedEvent"
    "approveRequestedEvent" "aqua" "archive" "archiveArtifacts"
    "arestocats" "artifactResolver" "artifactoryDistributeBuild"
    "artifactoryDownload" "artifactoryMavenBuild"
    "artifactoryPromoteBuild" "artifactoryUpload" "awaitDeployment"
    "awaitDeploymentCompletion" "awsCodeBuild" "awsIdentity" "azureCLI"
    "azureDownload" "azureFunctionAppPublish" "azureUpload"
    "azureVMSSUpdate" "azureVMSSUpdateInstances" "azureWebAppPublish"
    "backlogPullRequest" "bat" "bearychatSend" "benchmark"
    "bitbucketStatusNotify" "blazeMeterTest" "build" "buildBamboo"
    "buildImage" "bzt" "cache" "catchError" "cbt" "cbtScreenshotsTest"
    "cbtSeleniumTest" "cfInvalidate" "cfnCreateChangeSet" "cfnDelete"
    "cfnDeleteStackSet" "cfnDescribe" "cfnExecuteChangeSet" "cfnExports"
    "cfnUpdate" "cfnUpdateStackSet" "cfnValidate" "changeAsmVer"
    "checkstyle" "chefSinatraStep" "cifsPublisher" "cleanWs" "cleanup"
    "cloudshareDockerMachine" "cm" "cmake" "cmakeBuild" "cobertura"
    "codefreshLaunch" "codefreshRun" "codescene" "codesonar" "collectEnv"
    "conanAddRemote" "conanAddUser" "configFileProvider" "container"
    "containerLog" "contrastAgent" "contrastVerification" "copy"
    "copyArtifacts" "coverityResults" "cpack" "createDeploymentEvent"
    "createEnvironment" "createEvent" "createMemoryDump" "createSummary"
    "createThreadDump" "crxBuild" "crxDeploy" "crxDownload" "crxReplicate"
    "crxValidate" "ctest" "ctmInitiatePipeline" "ctmPostPiData"
    "ctmSetPiData" "cucumber" "cucumberSlackSend" "currentNamespace"
    "debianPbuilder" "deleteDir" "dependencyCheckAnalyzer"
    "dependencyCheckPublisher" "dependencyCheckUpdateOnly"
    "dependencyTrackPublisher" "deployAPI" "deployArtifacts"
    "deployLambda" "dingding" "dir" "disk" "dockerFingerprintFrom"
    "dockerFingerprintRun" "dockerNode" "dockerPullStep" "dockerPushStep"
    "dockerPushWithProxyStep" "doktor" "downloadProgetPackage"
    "downstreamPublisher" "dropbox" "dry" "ec2" "ec2ShareAmi" "echo"
    "ecrLogin" "emailext" "emailextrecipients" "envVarsForTool" "error"
    "evaluateGate" "eventSourceLambda" "executeCerberusCampaign"
    "exportPackages" "exportProjects" "exws" "exwsAllocate" "figlet"
    "fileExists" "fileOperations" "findFiles" "findbugs" "fingerprint"
    "flywayrunner" "ftp" "ftpPublisher" "gatlingArchive"
    "getArtifactoryServer" "getContext" "getLastChangesPublisher" "git"
    "gitbisect" "githubNotify" "gitlabBuilds" "gitlabCommitStatus"
    "googleCloudBuild" "googleStorageDownload" "googleStorageUpload"
    "gprbuild" "greet" "hipchatSend" "http" "httpRequest" "hub_detect"
    "hub_scan" "hub_scan_failure" "hubotApprove" "hubotSend"
    "importPackages" "importProjects" "inNamespace" "inSession"
    "initConanClient" "input" "invokeLambda" "isUnix" "ispwOperation"
    "ispwRegisterWebhook" "ispwWaitForWebhook" "jacoco" "jdbc"
    "jiraAddComment" "jiraAddWatcher" "jiraAssignIssue"
    "jiraAssignableUserSearch" "jiraComment" "jiraDeleteAttachment"
    "jiraDeleteIssueLink" "jiraDeleteIssueRemoteLink"
    "jiraDeleteIssueRemoteLinks" "jiraDownloadAttachment"
    "jiraEditComment" "jiraEditComponent" "jiraEditIssue"
    "jiraEditVersion" "jiraGetAttachmentInfo" "jiraGetComment"
    "jiraGetComments" "jiraGetComponent" "jiraGetComponentIssueCount"
    "jiraGetFields" "jiraGetIssue" "jiraGetIssueLink"
    "jiraGetIssueLinkTypes" "jiraGetIssueRemoteLink"
    "jiraGetIssueRemoteLinks" "jiraGetIssueTransitions"
    "jiraGetIssueWatches" "jiraGetProject" "jiraGetProjectComponents"
    "jiraGetProjectStatuses" "jiraGetProjectVersions" "jiraGetProjects"
    "jiraGetVersion" "jiraIssueSelector" "jiraJqlSearch" "jiraLinkIssues"
    "jiraNewComponent" "jiraNewIssue" "jiraNewIssueRemoteLink"
    "jiraNewIssues" "jiraNewVersion" "jiraNotifyIssue" "jiraSearch"
    "jiraTransitionIssue" "jiraUploadAttachment" "jiraUserSearch"
    "jmhReport" "jobDsl" "junit" "klocworkBuildSpecGeneration"
    "klocworkIncremental" "klocworkIntegrationStep1"
    "klocworkIntegrationStep2" "klocworkIssueSync"
    "klocworkQualityGateway" "klocworkWrapper" "kubernetesApply"
    "kubernetesDeploy" "lastChanges" "library" "libraryResource"
    "liquibaseDbDoc" "liquibaseRollback" "liquibaseUpdate"
    "listAWSAccounts" "livingDocs" "loadRunnerTest" "lock" "logstashSend"
    "mail" "marathon" "mattermostSend" "memoryMap" "milestone" "mockLoad"
    "newArtifactoryServer" "newBuildInfo" "newGradleBuild" "newMavenBuild"
    "nexusArtifactUploader" "nexusPolicyEvaluation" "nexusPublisher"
    "node" "nodejs" "nodesByLabel" "notifyBitbucket" "notifyDeploymon"
    "notifyOTC" "nunit" "nvm" "octoPerfTest" "office365ConnectorSend"
    "openTasks" "openshiftBuild" "openshiftCreateResource"
    "openshiftDeleteResourceByJsonYaml" "openshiftDeleteResourceByKey"
    "openshiftDeleteResourceByLabels" "openshiftDeploy" "openshiftExec"
    "openshiftImageStream" "openshiftScale" "openshiftTag"
    "openshiftVerifyBuild" "openshiftVerifyDeployment"
    "openshiftVerifyService" "openstackMachine"
    "osfBuilderSuiteForSFCCDeploy" "p4" "p4approve" "p4publish" "p4sync"
    "p4tag" "p4unshelve" "pagerduty" "parasoftFindings" "pcBuild" "pdrone"
    "perfReport" "perfSigReports" "perfpublisher" "plot" "pmd"
    "podTemplate" "powershell" "pragprog" "pretestedIntegrationPublisher"
    "properties" "protecodesc" "publishATX" "publishBrakeman"
    "publishBuildInfo" "publishBuildRecord" "publishConfluence"
    "publishDeployRecord" "publishETLogs" "publishEventQ"
    "publishGenerators" "publishHTML" "publishLambda" "publishLastChanges"
    "publishSQResults" "publishStoplight" "publishTMS" "publishTRF"
    "publishTestResult" "publishTraceAnalysis" "publishUNIT"
    "publishValgrind" "pullPerfSigReports" "puppetCode" "puppetHiera"
    "puppetJob" "puppetQuery" "pushImage" "pushToCloudFoundry" "pwd"
    "pybat" "pysh" "qc" "queryModuleBuildRequest" "questavrm" "r"
    "radargunreporting" "rancher" "readFile" "readJSON" "readManifest"
    "readMavenPom" "readProperties" "readTrusted" "readXml" "readYaml"
    "realtimeJUnit" "registerWebhook" "release" "resolveScm" "retry"
    "rocketSend" "rtp" "runConanCommand" "runFromAlmBuilder"
    "runLoadRunnerScript" "runValgrind" "s3CopyArtifact" "s3Delete"
    "s3Download" "s3FindFiles" "s3Upload" "salt" "sauce" "saucePublisher"
    "sauceconnect" "script" "selectRun" "sendCIMessage"
    "sendDeployableMessage" "serviceNow_attachFile" "serviceNow_attachZip"
    "serviceNow_createChange" "serviceNow_getCTask"
    "serviceNow_getChangeState" "serviceNow_updateChangeItem"
    "setAccountAlias" "setGerritReview" "setGitHubPullRequestStatus" "sh"
    "sha1" "signAndroidApks" "silkcentral" "silkcentralCollectResults"
    "slackSend" "sleep" "sloccountPublish" "snsPublish" "snykSecurity"
    "sonarToGerrit" "sparkSend" "splitTests" "springBoot" "sscm"
    "sseBuild" "sseBuildAndPublish" "sshPublisher" "sshagent" "stage"
    "startET" "startSandbox" "startSession" "startTS" "stash" "step"
    "stepcounter" "stopET" "stopSandbox" "stopSession" "stopTS"
    "submitJUnitTestResultsToqTest" "submitModuleBuildRequest"
    "svChangeModeStep" "svDeployStep" "svExportStep" "svUndeployStep"
    "svn" "tagImage" "task" "teamconcert" "tee" "testFolder" "testPackage"
    "testProject" "testiniumExecution" "themisRefresh" "themisReport"
    "throttle" "time" "timeout" "timestamps" "tm" "tool" "touch"
    "triggerInputStep" "triggerJob" "typetalkSend" "uftScenarioLoad"
    "unarchive" "unstash" "unzip" "updateBotPush"
    "updateGitlabCommitStatus" "updateIdP" "updateTrustPolicy"
    "upload-pgyer" "uploadProgetPackage" "uploadToIncappticConnect"
    "vSphere" "validateDeclarativePipeline" "vmanagerLaunch"
    "waitForCIMessage" "waitForJob" "waitForQualityGate" "waitForWebhook"
    "waitUntil" "walk" "waptProReport" "warnings" "whitesource"
    "winRMClient" "withAWS" "withAnt" "withContext" "withCoverityEnv"
    "withCredentials" "withDockerContainer" "withDockerRegistry"
    "withDockerServer" "withEnv" "withKafkaLog" "withKubeConfig"
    "withMaven" "withNPM" "withPod" "withPythonEnv" "withSCM"
    "withSandbox" "withSonarQubeEnv" "withTypetalk" "wrap" "writeFile"
    "writeJSON" "writeMavenPom" "writeProperties" "writeXml" "writeYaml"
    "ws" "xUnitImporter" "xUnitUploader" "xunit" "xldCreatePackage"
    "xldDeploy" "xldPublishPackage" "xlrCreateRelease" "xrayScanBuild"
    "zip"))


(defun jenkinsfile-mode--fetch-keywords-from-jenkinsfile-vim ()
  "Fetch and extract keywords from `jenkinsfile-mode-vim-source-url'.
Run this manually when editing this file to get an updated the list of keywords."
  (let* (file-sections directives options core-steps pipeline-steps
                       (syn-keyword-p (lambda (name line) (string-prefix-p (concat "syn keyword " name " ") line)))
                       (split-keywords (lambda (line) (split-string (replace-regexp-in-string "syn keyword [^ .]* " "" line)))))
    (with-current-buffer (url-retrieve-synchronously jenkinsfile-mode-vim-source-url t)
      (goto-char (point-min))
      (while (not (eobp))
        (move-beginning-of-line 1)
        (let ((line (buffer-substring (point) (line-end-position))))
          (cond
           ((funcall syn-keyword-p "jenkinsfileSection" line)      (setq file-sections (append file-sections (funcall split-keywords line))))
           ((funcall syn-keyword-p "jenkinsfileDirective" line)    (setq directives (append directives (funcall split-keywords line))))
           ((funcall syn-keyword-p "jenkinsfileOption" line)       (setq options (append options (funcall split-keywords line))))
           ((funcall syn-keyword-p "jenkinsfileCoreStep" line)     (setq core-steps (append core-steps (funcall split-keywords line))))
           ((funcall syn-keyword-p "jenkinsfilePipelineStep" line) (setq pipeline-steps (append pipeline-steps (funcall split-keywords line))))))
        (forward-line 1)))
    (let ((buf (get-buffer-create "*jenkinsfile-mode--fetch-keywords-from-jenkinsfile-vim*")))
      (with-current-buffer buf
        (erase-buffer)
        (emacs-lisp-mode)
        (insert ";; copy the contents of this buffer into jenkinsfile-mode.el\n\n")
        (insert (format "(setq jenkinsfile-mode--file-section-keywords '%S)\n\n" file-sections))
        (insert (format "(setq jenkinsfile-mode--directive-keywords '%S)\n\n" directives))
        (insert (format "(setq jenkinsfile-mode--option-keywords '%S)\n\n" options))
        (insert (format "(setq jenkinsfile-mode--core-step-keywords '%S)\n\n" core-steps))
        (insert (format "(setq jenkinsfile-mode--pipeline-step-keywords '%S)\n\n" pipeline-steps))
        (fill-region 0 (point)))
      (switch-to-buffer buf))))

(defvar jenkinsfile-mode-font-lock-keywords
  `((,(regexp-opt jenkinsfile-mode--file-section-keywords 'symbols)  . font-lock-constant-face)
    (,(regexp-opt jenkinsfile-mode--directive-keywords 'symbols)     . font-lock-constant-face)
    (,(regexp-opt jenkinsfile-mode--option-keywords 'symbols)        . font-lock-function-name-face)
    (,(regexp-opt jenkinsfile-mode--core-step-keywords 'symbols)     . font-lock-function-name-face)
    (,(regexp-opt jenkinsfile-mode--pipeline-step-keywords 'symbols) . font-lock-keyword-face)))

(defvar jenkinsfile-mode-font-lock-defaults
  (append groovy-font-lock-keywords jenkinsfile-mode-font-lock-keywords))

(defun jenkinsfile-mode--pipeline-step-compeletion-at-point ()
  "completion for pipeline step"
  (interactive)
  (let* (
         (bds (bounds-of-thing-at-point 'symbol))
         (start (car bds))
         (end (cdr bds)))
    (list start end jenkinsfile-mode--pipeline-step-keywords . nil ))
  )

(defun jenkinsfile-mode--core-step-compeletion-at-point ()
  "completion for core step"
  (interactive)
  (let* (
         (bds (bounds-of-thing-at-point 'symbol))
         (start (car bds))
         (end (cdr bds)))
    (list start end jenkinsfile-mode--core-step-keywords . nil ))
  )

(defun jenkinsfile-mode--option-compeletion-at-point ()
  "completion for option step"
  (interactive)
  (let* (
         (bds (bounds-of-thing-at-point 'symbol))
         (start (car bds))
         (end (cdr bds)))
    (list start end jenkinsfile-mode--option-keywords . nil ))
  )

(defun jenkinsfile-mode--directive-compeletion-at-point ()
  "completion for directive step"
  (interactive)
  (let* (
         (bds (bounds-of-thing-at-point 'symbol))
         (start (car bds))
         (end (cdr bds)))
    (list start end jenkinsfile-mode--directive-keywords . nil ))
  )

(defun jenkinsfile-mode--file-compeletion-at-point ()
  "completion for file step"
  (interactive)
  (let* (
         (bds (bounds-of-thing-at-point 'symbol))
         (start (car bds))
         (end (cdr bds)))
    (list start end jenkinsfile-mode--file-section-keywords . nil ))
  )

;;;###autoload
(define-derived-mode jenkinsfile-mode groovy-mode "Jenkinsfile"
  "Major mode for editing Jenkins declarative pipeline files."
  (setq font-lock-defaults '(jenkinsfile-mode-font-lock-defaults))
  (add-hook 'completion-at-point-functions 'jenkinsfile-mode--file-compeletion-at-point nil 'local)
  (add-hook 'completion-at-point-functions 'jenkinsfile-mode--directive-compeletion-at-point nil 'local)
  (add-hook 'completion-at-point-functions 'jenkinsfile-mode--option-compeletion-at-point nil 'local)
  (add-hook 'completion-at-point-functions 'jenkinsfile-mode--pipeline-step-compeletion-at-point nil 'local)
  (add-hook 'completion-at-point-functions 'jenkinsfile-mode--core-step-compeletion-at-point nil 'local)
  (setq-local groovy-indent-offset jenkinsfile-mode-indent-offset)
  (with-eval-after-load 'company-keywords
    (add-to-list 'company-keywords-alist
                 `(jenkinsfile-mode . ,(append jenkinsfile-mode--file-section-keywords
                                               jenkinsfile-mode--directive-keywords
                                               jenkinsfile-mode--option-keywords
                                               jenkinsfile-mode--pipeline-step-keywords
                                               jenkinsfile-mode--core-step-keywords
                                               ))))
  )

;;;###autoload
(add-to-list 'auto-mode-alist '("Jenkinsfile\\'" . jenkinsfile-mode))

(provide 'jenkinsfile-mode)
;;; jenkinsfile-mode.el ends here
