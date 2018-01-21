#!/bin/sh
# lightsun
TOOL_VERSION=2
TOOL_BUILD=alpha
SEEDUTIL_COMMAND="sudo /System/Library/PrivateFrameworks/Seeding.framework/Versions/A/Resources/seedutil"
SYSTEM_BUILD="$(sw_vers -buildVersion)"
SYSTEM_VERSION="$(sw_vers -productVersion)"

function setDefaultSettings(){
	PLATFORM=macOS
	detectCatalog
}

function setProjectPath(){
	COUNT=1
	while(true); do
		if [[ -d "/tmp/lightsun/${COUNT}" ]]; then
			COUNT=$((COUNT+1))
		else
			mkdir -p "/tmp/lightsun/${COUNT}"
			PROJECT_DIR="/tmp/lightsun/${COUNT}"
			break
		fi
	done
	mkdir -p "${PROJECT_DIR}/TitleBar"
}

function showInferface(){
	addTitleBar "Home"
	while(true); do
		clear
		showLines "*"
		echo "lightsun_${TOOL_BUILD}-${TOOL_VERSION} by pookjw"
		showLines "-"
		if [[ -z "${PLATFORM}" ]]; then
			echo "(1) Platform (required): (undefined)"
		else
			echo "(1) Platform (required): ${PLATFORM}"
		fi
		if [[ -z "${DEVICE}" ]]; then
			echo "(2) Device: (undefined)"
		else
			echo "(2) Device: ${DEVICE}"
		fi
		if [[ -z "${VERSION}" ]]; then
			echo "(3) Version: (undefined)"
		else
			echo "(3) Version: ${VERSION}"
		fi
		if [[ -z "${BUILD}" ]]; then
			echo "(4) Build: (undefined)"
		else
			echo "(4) Build: ${BUILD}"
		fi
		if [[ -z "${CATALOG}" ]]; then
			echo "(5) Catalog (required): (undefined)"
		else
			echo "(5) Catalog (required): ${CATALOG}"
		fi
		if [[ -z "${PREREQUISITE_VERISON}" ]]; then
			echo "(6) Version (Prerequisite): (undefined)"
		else
			echo "(6) Version (Prerequisite): ${PREREQUISITE_VERISON}"
		fi
		if [[ -z "${PREREQUISITE_BUILD}" ]]; then
			echo "(7) Build (Prerequisite): (undefined)"
		else
			echo "(7) Build (Prerequisite): ${PREREQUISITE_BUILD}"
		fi
		showLines "-"
		echo "commands: 1~7, adv, back, exit, reset, start"
		showLines "*"
		readAnswer

		if [[ "${ANSWER}" == 1 ]]; then
			addTitleBar "Set Platform"
			while(true); do
				clear
				showLines "*"
				showTitleBar
				showLines "-"
				echo "(1) macOS"
				echo "(2) iOS"
				showLines "*"
				readAnswer

				if [[ "${ANSWER}" == 1 ]]; then
					resetValues
					PLATFORM=macOS
					CATALOG=
					echo "Fill Version and Build with current macOS? (y/n)"
					readAnswer
					if [[ "${ANSWER}" == y || "${ANSWER}" == yes ]]; then
						VERSION="${SYSTEM_VERSION}"
						BUILD="${SYSTEM_BUILD}"
					fi
					backTitleBar
					break
				elif [[ "${ANSWER}" == 2 ]]; then
					resetValues
					PLATFORM=iOS
					CATALOG=
					backTitleBar
					break
				else
					replyAnswer
				fi
			done
		elif [[ "${ANSWER}" == 2 ]]; then
			readAnswer "DEVICE=" DEVICE
		elif [[ "${ANSWER}" == 3 ]]; then
			readAnswer "VERSION=" VERSION
		elif [[ "${ANSWER}" == 4 ]]; then
			readAnswer "BUILD=" BUILD
		elif [[ "${ANSWER}" == 5 ]]; then
			addTitleBar "Set catalog"
			if [[ -z "${PLATFORM}" ]]; then
				showError "Define Platform first."
				backTitleBar
				showPA2C
			else
				while(true); do
					clear
					showLines "*"
					showTitleBar
					showLines "-"

					if [[ "${PLATFORM}" == macOS ]]; then
						echo "(1) Detect from this macOS"
					else
						echo "(1) Detect from OTA Profile (.mobileconfig)"
					fi
					echo "(2) Enter URL manually"
					showLines "*"
					readAnswer

					if [[ "${ANSWER}" == 1 ]]; then
						detectCatalog
						if [[ -z "${CATALOG}" ]]; then
							showError "Failed to detect catalog."
							showPA2C
						else
							backTitleBar
							break
						fi
					elif [[ "${ANSWER}" == 2 ]]; then
						readAnswer "CATALOG=" CATALOG
						backTitleBar
						break
					else
						replyAnswer
					fi
				done
			fi
		elif [[ "${ANSWER}" == 6 ]]; then
			readAnswer "PREREQUISITE_VERISON=" PREREQUISITE_VERISON
		elif [[ "${ANSWER}" == 7 ]]; then
			readAnswer "PREREQUISITE_BUILD=" PREREQUISITE_BUILD
		elif [[ "${ANSWER}" == reset ]]; then
			resetValues
		elif [[ "${ANSWER}" == start ]]; then
			if [[ -z "${PLATFORM}" || -z "${CATALOG}" ]]; then
				showError "Fill Platform and Catalog."
				showPA2C
			else
				startService
			fi
		else
			replyAnswer
		fi
	done
}

function detectCatalog(){
	CATALOG=
	if [[ "${PLATFORM}" == macOS ]]; then
		CURRENT_ENROLLED_SEED=$(${SEEDUTIL_COMMAND} current | grep "Currently enrolled in" | cut -d" " -f4)
		echo "Currently enrolled in: ${CURRENT_ENROLLED_SEED}"
		if [[ "${CURRENT_ENROLLED_SEED}" == "(null)" ]]; then
			${SEEDUTIL_COMMAND} enroll DeveloperSeed > /dev/null 2>&1
		fi
		CATALOG=$(sudo /System/Library/PrivateFrameworks/Seeding.framework/Versions/A/Resources/seedutil current | grep CatalogURL | cut -d" " -f2)
		echo "CatalogURL: ${CATALOG}"
		if [[ "${CURRENT_ENROLLED_SEED}" == "(null)" ]]; then
			${SEEDUTIL_COMMAND} unenroll > /dev/null 2>&1
		fi
		showPA2C
	else
		readAnswer "Path of .mobileconfig: " PATH_MOBILECONFIG
		if [[ -z "${PATH_MOBILECONFIG}" ]]; then
			:
		elif [[ ! -f "${PATH_MOBILECONFIG}" ]]; then
			showError "No such file: ${PATH_MOBILECONFIG}"
		elif [[ -d "${PATH_MOBILECONFIG}" ]]; then
			showError "${PATH_MOBILECONFIG} is directory."
		else
			VALUE=
			PASS_ONCE_1=No
			for VALUE in $(strings "${PATH_MOBILECONFIG}"); do
				if [[ "${VALUE}" == "<key>MobileAssetServerURL-com.apple.MobileAsset.SoftwareUpdate</key>" ]]; then
					PASS_ONCE_1=YES
				elif [[ "${PASS_ONCE_1}" == YES ]]; then
					CATALOG="$(echo "${VALUE}" | cut -d">" -f2 | cut -d"<" -f1)"
					PASS_ONCE_1=NO
					break
				fi
			done
		fi
	fi
}

function resetValues(){
	PLATFORM=
	DEVICE=
	VERSION=
	BUILD=
	CATALOG=
	PREREQUISITE_VERISON=
	PREREQUISITE_BUILD=
}

function readAnswer(){
	if [[ -z "${1}" ]]; then
		read -p "- " ANSWER
	else
		if [[ -z "${2}" ]]; then
			read -p "${1}" ANSWER
		else
			read -p "${1}" "${2}"
		fi
	fi
}

function replyAnswer(){
	if [[ "${ANSWER}" == back || "${ANSWER}" == q ]]; then
		if [[ "$(showTitleBar)" == Home ]]; then
			showNotSupportedCommand
		else
			backTitleBar
			break
		fi
	elif [[ "${ANSWER}" == exit ]]; then
		quitTool 0
	elif [[ "${ANSWER}" == adv ]]; then
		showAdvancedSettings
	elif [[ -z "${ANSWER}" ]]; then
		:
	else
		showNotSupportedCommand
	fi
}

function showAdvancedSettings(){
	addTitleBar "Advanced Settings"
	while(true); do
		clear
		showLines "*"
		showTitleBar
		showLines "-"
		echo "(1) Run addTitleBar"
		echo "(2) Run backTitleBar"
		echo "(3) Enroll to DeveloperSeed"
		echo "(4) Enroll to PublicSeed"
		echo "(5) Unenroll Seed"
		showLines "-"
		echo "PROJECT_DIR=${PROJECT_DIR}"
		echo "TITLE_NUM=${TITLE_NUM}"
		showLines "*"
		readAnswer

		if [[ "${ANSWER}" == 1 ]]; then
			addTitleBar "$(readAnswer "$ addTitleBar "; echo "${ANSWER}")"
		elif [[ "${ANSWER}" == 2 ]]; then
			backTitleBar
		elif [[ "${ANSWER}" == 3 ]]; then
			${SEEDUTIL_COMMAND} enroll DeveloperSeed
		elif [[ "${ANSWER}" == 4 ]]; then
			${SEEDUTIL_COMMAND} enroll PublicSeed
		elif [[ "${ANSWER}" == 5 ]]; then
			${SEEDUTIL_COMMAND} unenroll
		else
			replyAnswer
		fi
	done
}

function showError(){
	if [[ -z "${1}" ]]; then
		echo "ERROR!"
	else
		echo "ERROR: ${1}"
	fi
}

function showNotSupportedCommand(){
	echo "Not supported command: ${ANSWER}"
	showPA2C
}

function showLines(){
	PRINTED_COUNTS=0
	COLS=`tput cols`
	if [[ "${COLS}" -ge 1 ]]; then
		while [[ ! $PRINTED_COUNTS == $COLS ]]; do
			printf "${1}"
			PRINTED_COUNTS=$((${PRINTED_COUNTS}+1))
		done
		echo
	fi
}

function showPA2C(){
	read -s -n 1 -p "Press any key to continue..."
	echo
}

function showTitleBar(){
	if [[ -f "${PROJECT_DIR}/TitleBar/${TITLE_NUM}" ]]; then
		cat "${PROJECT_DIR}/TitleBar/${TITLE_NUM}"
	else
		echo "Title"
	fi
}

function addTitleBar(){
	if [[ -z "${TITLE_NUM}" ]]; then
		TITLE_NUM=1
	fi
	if [[ ! -z "${1}" ]]; then
		if [[ -z "$(ls "${PROJECT_DIR}/TitleBar")" ]]; then
			echo "${1}" >> "${PROJECT_DIR}/TitleBar/${TITLE_NUM}"
		else
			echo "$(showTitleBar) > ${1}" >> "${PROJECT_DIR}/TitleBar/$((${TITLE_NUM}+1))"
			TITLE_NUM=$((${TITLE_NUM}+1))
		fi
	fi
}

function backTitleBar(){
	if [[ -f "${PROJECT_DIR}/TitleBar/${TITLE_NUM}" ]]; then
		rm "${PROJECT_DIR}/TitleBar/${TITLE_NUM}"
	fi
	TITLE_NUM=$((${TITLE_NUM}-1))
}

function startService(){
	downloadCatalog
	parseAssets
	quitTool 0
}

function downloadCatalog(){
	deleteFile "${PROJECT_DIR}/assets.gz"
	deleteFile "${PROJECT_DIR}/assets"
	deleteFile "${PROJECT_DIR}/assets.xml"
	deleteFile "${PROJECT_DIR}/documentation.xml"
	if [[ "${PLATFORM}" == macOS ]]; then
		curl -# -o "${PROJECT_DIR}/assets.gz" "${CATALOG}"
		gunzip "${PROJECT_DIR}/assets.gz"
		if [[ ! -f  "${PROJECT_DIR}/assets" ]]; then
			showError "Failed to get assets."
			quitTool 1
		fi
		mv "${PROJECT_DIR}/assets" "${PROJECT_DIR}/assets.xml"
	else
		curl -# -o "${PROJECT_DIR}/assets.xml" "${CATALOG}/com_apple_MobileAsset_SoftwareUpdate/com_apple_MobileAsset_SoftwareUpdate.xml"
		curl -# -o "${PROJECT_DIR}/documentation.xml" "${CATALOG}/com_apple_MobileAsset_SoftwareUpdateDocumentation/com_apple_MobileAsset_SoftwareUpdateDocumentation.xml"
		if [[ ! -f "${PROJECT_DIR}/assets.xml" || ! -f "${PROJECT_DIR}/documentation.xml" ]]; then
			showError "Failed to get assets."
			quitTool 1
		fi
	fi
}

function parseAssets(){
	if [[ "${PLATFORM}" == macOS ]]; then
		mkdir -p "${PROJECT_DIR}/data"
		VALUE=
		PASS_ONCE_1=YES
		PASS_ONCE_2=NO
		PASS_ONCE_3=YES
		for VALUE in $(cat "${PROJECT_DIR}/assets.xml"); do
			if [[ "${PASS_ONCE_1}" == YES ]]; then
				SUB_VALUE_1="${VALUE}"
				PASS_ONCE_1=NO
				PASS_ONCE_2=YES
				if [[ "${SUB_VALUE_1}" == "<key>ServerMetadataURL</key>" ]]; then
					UPDATE_KEY="$(echo "${SUB_VALUE_2}" | cut -d">" -f2 | cut -d"<" -f1)"
					START_RECORDING=YES
				fi
			elif [[ "${PASS_ONCE_2}" == YES ]]; then
				SUB_VALUE_2="${VALUE}"
				PASS_ONCE_2=NO
				PASS_ONCE_3=YES
				if [[ "${SUB_VALUE_2}" == "<key>ServerMetadataURL</key>" ]]; then
					UPDATE_KEY="$(echo "${SUB_VALUE_3}" | cut -d">" -f2 | cut -d"<" -f1)"
					START_RECORDING=YES
				fi
			elif [[ "${PASS_ONCE_3}" == YES ]]; then
				SUB_VALUE_3="${VALUE}"
				PASS_ONCE_3=NO
				PASS_ONCE_1=YES
				if [[ "${SUB_VALUE_3}" == "<key>ServerMetadataURL</key>" ]]; then
					UPDATE_KEY="$(echo "${SUB_VALUE_1}" | cut -d">" -f2 | cut -d"<" -f1)"
					START_RECORDING=YES
				fi
			fi
			if [[ "${START_RECORDING}" == YES ]]; then
				echo "${VALUE}" >> "${PROJECT_DIR}/data/${UPDATE_KEY}"
			fi
		done
	else
		:
	fi		
}

function deleteFile(){
	if [[ ! -z "${1}" ]]; then
		if [[ -f "${1}" ]]; then
			rm "${1}"
		elif [[ -d "${1}" ]]; then
			rm -rf "${1}"
		fi
	fi
}

function quitTool(){
	#deleteFile "${PROJECT_DIR}"
	exit "${1}"
}

setDefaultSettings
setProjectPath
showInferface
