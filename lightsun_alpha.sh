#!/bin/sh
# lightsun
TOOL_VERSION=4
TOOL_BUILD=alpha
SEEDUTIL_COMMAND="sudo /System/Library/PrivateFrameworks/Seeding.framework/Versions/A/Resources/seedutil"
SYSTEM_BUILD="$(sw_vers -buildVersion)"
SYSTEM_VERSION="$(sw_vers -productVersion)"

function setDefaultSettings(){
	PLATFORM=iOS
	CATALOG=https://mesu.apple.com/assets
	VERSION=11.2.5
	DEVICE=iPhone10,4
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
			echo "(1) Platform : (undefined)"
		else
			echo "(1) Platform : ${PLATFORM}"
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
			echo "(5) Catalog : (undefined)"
		else
			echo "(5) Catalog : ${CATALOG}"
		fi
		if [[ ! "${PLATFORM}" == macOS ]]; then
			if [[ -z "${PREREQUISITE_VERISON}" ]]; then
				echo "(6) Prerequisite Version: (undefined)"
			else
				echo "(6) Prerequisite Version: ${PREREQUISITE_VERISON}"
			fi
			if [[ -z "${PREREQUISITE_BUILD}" ]]; then
				echo "(7) Prerequisite Build: (undefined)"
			else
				echo "(7) Prerequisite Build: ${PREREQUISITE_BUILD}"
			fi
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
				echo "(2) iOS, watchOS, tvOS, etc..."
				showLines "*"
				readAnswer

				if [[ "${ANSWER}" == 1 ]]; then
					resetValues
					PLATFORM=macOS
					backTitleBar
					break
				elif [[ "${ANSWER}" == 2 ]]; then
					resetValues
					PLATFORM=etc
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
					if [[ ! "${PLATFORM}" == macOS ]]; then
						echo "(3) See list of URL (only for non-macOS)"
					fi
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
					elif [[ "${ANSWER}" == 3 ]]; then
						if [[ "${PLATFORM}" == macOS ]]; then
							showNotSupportedCommand
						else
							addTitleBar "List of URL"
							clear
							showLines "*"
							showTitleBar
							showLines "-"
							echo "https://mesu.apple.com/assets"
							echo "https://mesu.apple.com/assets/watch"
							echo "http://mesu.apple.com/assets/tv"
							echo "http://mesu.apple.com/assets/audio"
							echo "https://mesu.apple.com/assets/iOS11DeveloperSeed"
							showLines "*"
							showPA2C
							backTitleBar
						fi
					else
						replyAnswer
					fi
				done
			fi
		elif [[ "${ANSWER}" == 6 ]]; then
			if [[ "${PLATFORM}" == macOS ]]; then
				showNotSupportedCommand
			else
				readAnswer "PREREQUISITE_VERISON=" PREREQUISITE_VERISON
			fi
		elif [[ "${ANSWER}" == 7 ]]; then
			if [[ "${PLATFORM}" == macOS ]]; then
				showNotSupportedCommand
			else
				readAnswer "PREREQUISITE_BUILD=" PREREQUISITE_BUILD
			fi
		elif [[ "${ANSWER}" == reset || "${ANSWER}" == r ]]; then
			resetValues
		elif [[ "${ANSWER}" == start || "${ANSWER}" == s ]]; then
			if [[ -z "${PLATFORM}" || -z "${CATALOG}" ]]; then
				showError "Fill Platform and Catalog."
				showPA2C
			else
				break
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
			"${SEEDUTIL_COMMAND}" enroll DeveloperSeed > /dev/null 2>&1
		fi
		CATALOG=$(${SEEDUTIL_COMMAND} current | grep CatalogURL | cut -d" " -f2)
		echo "CatalogURL: ${CATALOG}"
		if [[ "${CURRENT_ENROLLED_SEED}" == "(null)" ]]; then
			"${SEEDUTIL_COMMAND}" unenroll > /dev/null 2>&1
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
			"${SEEDUTIL_COMMAND}" enroll DeveloperSeed
			showPA2C
		elif [[ "${ANSWER}" == 4 ]]; then
			"${SEEDUTIL_COMMAND}" enroll PublicSeed
			showPA2C
		elif [[ "${ANSWER}" == 5 ]]; then
			"${SEEDUTIL_COMMAND}" unenroll
			showPA2C
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
	mkdir -p "${PROJECT_DIR}/data"
	startOverParseStage
	VALUE=
	if [[ "${PLATFORM}" == macOS ]]; then
		PASS_ONCE_1=YES
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
			if [[ ! -z "$(echo "${VALUE}" | grep ".dist</string>")" ]]; then
				PASS_ONCE_4=YES
				PASS_ONCE_5=NO
			elif [[ "${PASS_ONCE_4}" == YES ]]; then
				PASS_ONCE_4=NO
				PASS_ONCE_5=YES
			elif [[ "${PASS_ONCE_5}" == YES ]]; then
				START_RECORDING=NO
				PASS_ONCE_5=NO
			fi
			if [[ "${START_RECORDING}" == YES ]]; then
				echo "${VALUE}" >> "${PROJECT_DIR}/data/${UPDATE_KEY}.txt"
			fi
		done
	else
		for VALUE in $(cat "${PROJECT_DIR}/assets.xml"); do
			if [[ "${VALUE}" == "<key>ActualMinimumSystemPartition</key>" ]]; then
				START_RECORDING=YES
			fi
			if [[ "${START_RECORDING}" == YES ]]; then
				echo "${VALUE}" >> "${PROJECT_DIR}/data/untitled.txt"
				if [[ "${VALUE}" == "<key>Build</key>" ]]; then
					PASS_ONCE_1=YES
				elif [[ "${PASS_ONCE_1}" == YES ]]; then
					PASS_ONCE_1=NO
					NAME_BUILD="${VALUE}"
					if [[ ! -z "${BUILD}" && ! "<string>${BUILD}</string>" == "${NAME_BUILD}" ]]; then
						startOverParseStage
					fi
				fi
				if [[ "${VALUE}" == "<key>OSVersion</key>" ]]; then
					PASS_ONCE_2=YES
				elif [[ "${PASS_ONCE_2}" == YES ]]; then
					PASS_ONCE_2=NO
					NAME_OSVERSION="${VALUE}"
					if [[ ! -z "${VERSION}" && ! "<string>${VERSION}</string>" == "${NAME_OSVERSION}" && ! "<string>9.9.${VERSION}</string>" == "${NAME_OSVERSION}" ]]; then
						startOverParseStage
					fi
				fi
				if [[ "${VALUE}" == "<key>PrerequisiteBuild</key>" ]]; then
					PASS_ONCE_3=YES
				elif [[ "${PASS_ONCE_3}" == YES ]]; then
					PASS_ONCE_3=NO
					SEARCHED_PREREQUISITE=YES
					if [[ -z "${PREREQUISITE_BUILD}" || "<string>${PREREQUISITE_BUILD}</string>" == "${VALUE}" ]]; then
						NAME_PREREQUISITE_BUILD="${VALUE}"
					else
						startOverParseStage
					fi
				fi
				if [[ "${VALUE}" == "<key>PrerequisiteOSVersion</key>" ]]; then
					PASS_ONCE_4=YES
				elif [[ "${PASS_ONCE_4}" == YES ]]; then
					PASS_ONCE_4=NO
					SEARCHED_PREREQUISITE=YES
					if [[ -z "${PREREQUISITE_VERISON}" || "<string>${PREREQUISITE_VERISON}</string>" == "${VALUE}" ]]; then
						NAME_PREREQUISITE_VERSION="${VALUE}"
					else
						startOverParseStage
					fi
				fi
				if [[ "${VALUE}" == "<key>SUDocumentationID</key>" ]]; then
					PASS_ONCE_5=YES
				elif [[ "${PASS_ONCE_5}" == YES ]]; then
					PASS_ONCE_5=NO
					NAME_INTERNAL_BUILD_NAME="${VALUE}"
				fi
				if [[ "${VALUE}" == "<key>SupportedDeviceModels</key>" ]]; then
					PASS_ONCE_6=YES
				elif [[ "${PASS_ONCE_6}" == YES ]]; then
					PASS_ONCE_6=NO
					PASS_ONCE_7=YES
				elif [[ "${PASS_ONCE_7}" == YES ]]; then
					PASS_ONCE_7=NO
					NAME_CODE_DEVICE="${VALUE}"
					if [[ ! -z "${DEVICE}" && ! "<string>${DEVICE}</string>" == "${NAME_CODE_DEVICE}" ]]; then
						PASS_ONCE_8=YES
					fi
				fi
				if [[ "${VALUE}" == "<key>SupportedDevices</key>" ]]; then
					PASS_ONCE_9=YES
				elif [[ "${PASS_ONCE_9}" == YES ]]; then
					PASS_ONCE_9=NO
					PASS_ONCE_10=YES
				elif [[ "${PASS_ONCE_10}" == YES ]]; then
					PASS_ONCE_10=NO
					NAME_DEVICE="${VALUE}"
					if [[ "${PASS_ONCE_8}" == YES && ! -z "<string>${DEVICE}" && ! "<string>${DEVICE}</string>" == "${NAME_DEVICE}" ]]; then
						startOverParseStage
					fi
				fi
				if [[ "${VALUE}" == "<key>__RelativePath</key>" ]]; then
					PASS_ONCE_11=YES
				elif [[ "${PASS_ONCE_11}" == YES ]]; then
					PASS_ONCE_11=NO
					NAME_BUILD="$(echo "${NAME_BUILD}" | cut -d">" -f2 | cut -d"<" -f1)"
					NAME_OSVERSION="$(echo "${NAME_OSVERSION}" | cut -d">" -f2 | cut -d"<" -f1)"
					NAME_PREREQUISITE_BUILD="$(echo "${NAME_PREREQUISITE_BUILD}" | cut -d">" -f2 | cut -d"<" -f1)"
					NAME_PREREQUISITE_VERSION="$(echo "${NAME_PREREQUISITE_VERSION}" | cut -d">" -f2 | cut -d"<" -f1)"
					NAME_INTERNAL_BUILD_NAME="$(echo "${NAME_INTERNAL_BUILD_NAME}" | cut -d">" -f2 | cut -d"<" -f1)"
					NAME_CODE_DEVICE="$(echo "${NAME_CODE_DEVICE}" | cut -d">" -f2 | cut -d"<" -f1)"
					NAME_DEVICE="$(echo "${NAME_DEVICE}" | cut -d">" -f2 | cut -d"<" -f1)"
					if [[ "${SEARCHED_PREREQUISITE}" == YES ]]; then
						mv "${PROJECT_DIR}/data/untitled.txt" "${PROJECT_DIR}/data/${NAME_CODE_DEVICE}_${NAME_DEVICE}_${NAME_OSVERSION}_${NAME_BUILD}_${NAME_INTERNAL_BUILD_NAME}_Prerequisite_${NAME_PREREQUISITE_VERSION}_${NAME_PREREQUISITE_BUILD}.txt"
					else
						if [[ -z "${PREREQUISITE_BUILD}" && -z "${PREREQUISITE_VERISON}" ]]; then	
							mv "${PROJECT_DIR}/data/untitled.txt" "${PROJECT_DIR}/data/${NAME_CODE_DEVICE}_${NAME_DEVICE}_${NAME_OSVERSION}_${NAME_BUILD}_${NAME_INTERNAL_BUILD_NAME}.txt"
						fi
					fi
					startOverParseStage
				fi
			fi
		done
	fi		
}

function startOverParseStage(){
	START_RECORDING=NO
	PASS_ONCE_1=NO
	PASS_ONCE_2=NO
	PASS_ONCE_3=NO
	PASS_ONCE_4=NO
	PASS_ONCE_5=NO
	PASS_ONCE_6=NO
	PASS_ONCE_7=NO
	PASS_ONCE_8=NO
	PASS_ONCE_9=NO
	PASS_ONCE_10=NO
	PASS_ONCE_11=NO
	NAME_BUILD=
	NAME_OSVERSION=
	NAME_PREREQUISITE_BUILD=
	NAME_PREREQUISITE_VERSION=
	NAME_INTERNAL_BUILD_NAME=
	NAME_CODE_DEVICE=
	NAME_DEVICE=
	SEARCHED_PREREQUISITE=NO
	deleteFile "${PROJECT_DIR}/data/untitled.txt"
}

function showFinder(){
	if [[ -z "$(ls "${PROJECT_DIR}/data")" ]]; then
		showError "No data found."
	else
		open "${PROJECT_DIR}/data"
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
downloadCatalog
parseAssets
showFinder
quitTool 0
